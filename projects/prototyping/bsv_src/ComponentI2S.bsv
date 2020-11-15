package ComponentI2S;

import AxiStreamBridge::*;
import BramIpImport::*;
import SpecialFIFOs::*;
import ClientServer::*;
import i2sIpImport::*;
import AxiBridge::*;
import BRAMCore::*;
import Vector::*;
import Timing::*;
import GetPut::*;
import FIFO::*;


/******************************************************
* Data Types
******************************************************/
typedef Bit#(16) Smpl_t;


/******************************************************
* Component Driver: I2S IP
******************************************************/
interface I2Sip;
	method bit getLRCLK();
	method bit getSCLK();
	method bit getSDATA();

	method Action toggle_running();
endinterface

module mkI2Sip(I2Sip);

	/* constants */
	Integer aud_len   = 13335; 		// no of samples in audio
	Integer f_sample  = 11025; 		// sampling frequency of aufio
	Integer f_i2c     = f_sys/2; 	// aud_mclk of I2S IP

	/* reference BRAM */
	BRAM_PORT#(Bit#(16), Smpl_t) bsv_bram <- mkBRAMCore1Load(aud_len, True, "./bram_init.mem", False);

	/* imported IP Cores */
	I2SIp i2s 		<- mkI2SIp;
	BramIp bram 	<- mkBramIp;

	/* high level interface adapter for IPCore's AXI and AXI Stream interface */
	AxiBridge#(32, 12) 		axi_bram	<- mkAxiBridge(bram.axi);
	AxiBridge#(32, 8) 		axi_ctrl	<- mkAxiBridge(i2s.ctrl_axi);
	AxiStreamBridge#(32) 	axi_str 	<- mkAxiStreamBridge(i2s.axis);

	/* internal state */
	FIFO#(Smpl_t) sample_fifo 	<- mkBypassFIFO();

	Reg#(Bit#(4)) rst_cnter 	<- mkReg(0);
	Reg#(Bit#(4)) setup_cnt 	<- mkReg(0);
	Reg#(bit) player_select		<- mkReg(0);
	Reg#(bit) filler_state 		<- mkReg(0);
	Reg#(Bool) setup_done 		<- mkReg(False);
	Reg#(Bool) is_running 		<- mkReg(False);
	Reg#(Smpl_t) chan_2 		<- mkReg(0);
	Reg#(Bit#(4)) state 		<- mkReg(0);
	Reg#(Bit#(16)) pos 			<- mkReg(0);
	Reg#(Bool) written 			<- mkReg(False);
	Reg#(bit) bstate 			<- mkReg(0);
	Reg#(bit) clk 				<- mkReg(0);

	/* Register Addresses */
	Integer i2s_base 			= 0;
	Integer i2s_reg_Ctrl 		= i2s_base + 'h08;
	Integer i2s_reg_TimingCtrl 	= i2s_base + 'h20;

	/* Control Register */
	Integer reg_Ctrl_CoreEN 	= 0;


	/******************************************************
	* FUNCTIONS
	******************************************************/
	function Bit#(32) encode(Smpl_t sample, bit channel);
		Bit#(1) parity   = reduceXor(sample); 	// [31] even parity
		Bit#(1) status   = 'b0; 				// [30] one status bit per frame, 192 frames per block
		Bit#(1) user     = 'b0; 				// [29] arbitrary user data
		Bit#(1) validity = 'b0; 				// [28] 0: subframe is valid, 1: invalid
		Bit#(16) data    = sample; 				// [12:27] audio data
		Bit#(8) padding  = 'b0; 				// [4:11] zero padding for 16bit/sample (none for 24bit)
		Bit#(4) preamble; 						// [0:3]
		if (channel == 0)
			preamble = 'b0001;
		else
			preamble = 'b0011;

		return {parity, status, user, validity, data, padding, preamble};
	endfunction


	/******************************************************
	* RULES
	******************************************************/
	rule axi_rst;
		if (rst_cnter <= 10) begin
			i2s.putRSTn(0, 0, 1);
			bram.putRSTn(0);
			rst_cnter <= rst_cnter + 1;
		end else begin
			i2s.putRSTn(1, 1, 0);
			bram.putRSTn(1);
		end
	endrule

	rule axi_clk;
		clk <= ~clk;
		i2s.putCLK(clk);
	endrule

	rule i2s_setup(!setup_done && setup_cnt == 0);
		$display("[I2S] enable core");

		Bit#(8) regVal = 0;
		regVal[reg_Ctrl_CoreEN] = 1;
		axilite_send(axi_ctrl, fromInteger(i2s_reg_Ctrl), regVal);

		setup_cnt <= 1;
	endrule

	rule i2s_setup2(!setup_done && setup_cnt == 1);
		/**
		 * Calculate the clock divider:
		 * [mclk] / ([#Channels]*[bit/sample]*[Fs]) = 2*DIV
		 */
		Integer div = f_i2c / (2*16*f_sample*2) + 1;
		$display("[I2S] set clk divider to %d", div);

		Bit#(8) regVal = fromInteger(div);
		axilite_send(axi_ctrl, fromInteger(i2s_reg_TimingCtrl), regVal);

		setup_done <= True;
	endrule

	/********************* FILL BRAM *********************/

	/**
	 * TODO: I couldn't get the Xilinx Block Memory Generator to load a
	 * memory initialization file (bram_initialization.coe).
	 * The init setting is always reset during synthesis
	 * ("WARNING: Resetting the memory initialization file ...").
	 */
	Vector#(10, Smpl_t) sine = newVector();
	sine[ 0] =      0;
	sine[ 1] =  21062;
	sine[ 2] =  32269;
	sine[ 3] =  28377;
	sine[ 4] =  11206;
	sine[ 5] = -11206;
	sine[ 6] = -28377;
	sine[ 7] = -32269;
	sine[ 8] = -21062;
	sine[ 9] =      0;

	rule pre_data(setup_done && !written);
		Smpl_t sample_val = sine[pos];
		$display("[I2S] Writing data=%x to addr=%x", sample_val, 4*pos);

		axilite_send(axi_bram, 4*truncate(pos), sample_val);

		if (pos == 9) begin
			$display("[I2S] Write process done!");
			pos <= 0;
			written <= True;
		end else begin
			pos <= pos + 1;
		end
	endrule

	/********************* BRAM FETCH ********************/

	rule bdata(setup_done && written && is_running && bstate == 0);

		/* alternatingly fetch data from Xilinx BRAM and BSV BRAM */
		if (player_select == 0) begin
			/* xilinx BRAM block desing */
			Bit#(12) addr = truncate(4 * (pos%10));
			axilite_recv_start(axi_bram, addr);
		end else begin
			/* BSV BRAM implementation */
			bsv_bram.put(False, pos, ?);
		end

		bstate <= 1;
		if (pos == fromInteger(aud_len) - 1) begin
			pos <= 0;
			is_running <= False;
			player_select <= ~player_select;
		end else begin
			pos <= pos + 1;
		end
	endrule

	rule bdata2(setup_done && written && bstate == 1);

		Smpl_t sample_val;
		if (player_select == 0) begin
			/* xilinx BRAM */
			Bit#(32) bram_data <- axilite_recv_get(axi_bram);
			sample_val = truncate(bram_data);
		end else begin
			/* BSV BRAM */
			sample_val = bsv_bram.read();
		end

		sample_fifo.enq(sample_val);
		$display("Got %x from BRAM", sample_val);

		bstate <= 0;
	endrule

	/********************* I2S STREAM ********************/

	rule data(setup_done && written && state == 0);

		let sample_val = sample_fifo.first(); sample_fifo.deq();
		$display("[I2S] Stream 1: got data %x", sample_val);

		axis_send(axi_str, encode(sample_val, 0), 0);

		state 	<= 1;
		chan_2 	<= sample_val;
	endrule

	rule data2(setup_done && written && state == 1);
		$display("[I2S] Stream 2: chan_2 %x", chan_2);

		axis_send(axi_str, encode(chan_2, 1), 1);

		state <= 0;
	endrule


	/******************************************************
	* INTERFACE
	******************************************************/
	method bit getLRCLK();
		return i2s.getLRCLK();
	endmethod

	method bit getSCLK();
		return i2s.getSCLK();
	endmethod

	method bit getSDATA();
		return i2s.getSDATA();
	endmethod

	method Action toggle_running() if (!is_running);
		is_running <= !is_running;
	endmethod

endmodule

endpackage
