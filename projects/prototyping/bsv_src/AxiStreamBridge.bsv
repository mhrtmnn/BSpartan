package AxiStreamBridge;

import ClientServer::*;
import GlobalTypes::*;
import GetPut::*;
import FIFO::*;


/******************************************************
* GLOBAL TYPES/FUNCTIONS/DATA
******************************************************/
typedef enum { NVALID, VALID } AxiValid deriving (Bits);

typedef struct {
	Bit#(d_len) data;
	Bit#(3)     tid;
} AXIS_tfer#(numeric type d_len) deriving (Bits);

// helper function
function Action axis_send(AxiStreamBridge#(n) axi, Bit#(n) d, Bit#(3) t);
action
	let tfer = AXIS_tfer {
		data    : d,
		tid     : t
	};
	axi.tx.put(tfer);
endaction
endfunction


/******************************************************
* GENERIC AXI STREAM IFACE
******************************************************/
interface AxiStreamIface#(numeric type d_len);
	method Action putCLK(bit clk);

	// Stream Data Channel
	method Action putData(Bit#(3) tid, Bit#(d_len) data, bit valid);
	method bit getReady();
endinterface


/******************************************************
* BSV AXI STREAM INTERFACE
******************************************************/
interface AxiStreamBridge#(numeric type d_len);
	interface Put#(AXIS_tfer#(d_len)) tx;
endinterface

module mkAxiStreamBridge#(AxiStreamIface#(d_len) coreAXI) (AxiStreamBridge#(d_len));

	/* module state */
	FIFO#(AXIS_tfer#(d_len)) tx_fifo_in     <- mkFIFO();
	Reg#(Bit#(2)) axis_state                <- mkReg(0);
	Reg#(bit) clk                           <- mkReg(0);

	/* output buffers */
	Reg#(Bit#(    1)) buf_valid     <- mkReg(0);
	Reg#(Bit#(d_len)) buf_data      <- mkReg(0);
	Reg#(Bit#(    3)) buf_tid       <- mkReg(0);


	/******************************************************
	* RULES
	******************************************************/

	rule axis(clk == 1 && axis_state == 0);

		// change signal levels once clock goes low
		buf_data    <= tx_fifo_in.first.data;
		buf_tid     <= tx_fifo_in.first.tid;
		buf_valid   <= pack(VALID);

		axis_state <= 1;
	endrule

	rule axis_ctrl(clk == 1 && axis_state == 1);

		// read signal levels while clock is high
		if (coreAXI.getReady() == 1) begin
			$display("[axis] s1. Payload=%x, tid=%x", tx_fifo_in.first.data, tx_fifo_in.first.tid);
			axis_state <= 2;
		end
	endrule

	rule axis_ctrl1(clk == 1 && axis_state == 2);

		// change signal levels once clock goes low
		buf_data    <= 0;
		buf_tid     <= 0;
		buf_valid   <= pack(NVALID);

		tx_fifo_in.deq();
		axis_state  <= 0;
	endrule


	/*********************** SYSTEM **********************/

	rule axi_clk;
		clk <= ~clk;
		coreAXI.putCLK(clk);
	endrule

	/* drive signals in every cycle */
	(*fire_when_enabled*)
	rule signal_driver;
		coreAXI.putData(buf_tid, buf_data, buf_valid);
	endrule


	/******************************************************
	* INTERFACE
	******************************************************/
	interface tx = toPut(tx_fifo_in);


endmodule

endpackage
