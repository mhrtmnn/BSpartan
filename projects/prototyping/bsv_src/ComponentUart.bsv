package ComponentUart;

import SpecialFIFOs::*;
import ClientServer::*;
import UartIpImport::*;
import GlobalTypes::*;
import AxiBridge::*;
import Timing::*;
import GetPut::*;
import FIFOF::*;


/******************************************************
* Component Driver: UART IP
******************************************************/
interface UARTip;
	(*always_enabled*)
	method bit getTX();
	(*always_enabled*)
	method Action putRX(bit rx);

	method Bit#(8) getStatus();

	method Action send(Byte c);
	method ActionValue#(Byte) receive();
endinterface

module mkUARTip(UARTip);

	/* imported "UARTLite" IP Core module */
	UartLiteIp uartIP 		<- mkUartLiteIp;

	/* high level interface adapter for IPCore's AXI interface */
	AxiBridge#(32, 4) axi	<- mkAxiBridge(uartIP.axi);

	/* internal state */
	Reg#(Bool) setup_done 		<- mkReg(False);
	Reg#(Bit#(8)) stat_reg	 	<- mkReg('hab);
	Reg#(Bit#(4)) rst_cnter 	<- mkReg(0);
	Reg#(Bool) pending_intr 	<- mkReg(False);
	Reg#(UInt#(4)) tx_state 	<- mkReg(0);
	Reg#(UInt#(4)) rx_state 	<- mkReg(0);
	Reg#(UInt#(18)) poll_cnter 	<- mkReg(0);

	FIFOF#(Byte) rx_char 		<- mkBypassFIFOF();
	FIFOF#(Byte) tx_char 		<- mkBypassFIFOF();

	/* Register Addresses */
	Integer uartLite_base 			= 0;
	Integer uartLite_reg_RX 		= uartLite_base + 'h0;
	Integer uartLite_reg_TX 		= uartLite_base + 'h4;
	Integer uartLite_reg_STAT 		= uartLite_base + 'h8;
	Integer uartLite_reg_CTRL 		= uartLite_base + 'hC;

	/* CTRL Register */
	Integer reg_CTRL_IntrEn 		= 4;

	/* STAT Register */
	Integer reg_STAT_ParityErr 		= 7;
	Integer reg_STAT_FrameErr 		= 6;
	Integer reg_STAT_OverrunErr 	= 5;
	Integer reg_STAT_IntrEnabled 	= 4;
	Integer reg_STAT_TxFifoFull 	= 3;
	Integer reg_STAT_TxFifoEmpty 	= 2;
	Integer reg_STAT_RxFifoFull 	= 1;
	Integer reg_STAT_RxFifoValid 	= 0;

	/* timing */
	Integer poll_delay = 1 * c_US;


	/******************************************************
	* RULES
	******************************************************/
	rule axi_rst;
		if (rst_cnter <= 10) begin
			uartIP.putRSTn(0);
			rst_cnter <= rst_cnter + 1;
		end else begin
			uartIP.putRSTn(1);
		end
	endrule

	/**
	 * Rising-edge interrupt is generated when the RX FIFO becomes non-empty
	 * or when the TX FIFO becomes empty.
	 */
	rule axi_intr(!pending_intr);
		let intr = uartIP.getInterrupt();
		if (intr == 1) begin
			$display("Interrupt!");
			pending_intr <= True;
		end
	endrule

	rule uart_setup(!setup_done);
		$display("[UART] Enabling Interrupts");

		Bit#(8) regVal = 0;
		regVal[reg_CTRL_IntrEn] = 1;

		axilite_send(axi, fromInteger(uartLite_reg_CTRL), regVal);

		setup_done <= True;
	endrule

	/********************** RECEIVE **********************/

	rule rx0(setup_done && pending_intr && rx_state == 0);
		axilite_recv_start(axi, fromInteger(uartLite_reg_STAT));
		rx_state <= 1;
	endrule

	rule rx1(setup_done && pending_intr && rx_state == 1);
		let statReg <- axilite_recv_get(axi);
		stat_reg <= truncate(statReg);

		// If there is valid RX data then get it
		if (statReg[reg_STAT_RxFifoValid] == 1) begin
			$display("[UART] send (Getting char from RX FIFO");

			axilite_recv_start(axi, fromInteger(uartLite_reg_RX));
			rx_state <= 2;
		end else begin
			rx_state <= 0;
			pending_intr <= False;
		end
	endrule

	rule rx2(setup_done && pending_intr && rx_state == 2);
		let rxReg <- axilite_recv_get(axi);

		/**
		 * Avoid blocking and deadlocking here by dropping
		 * incoming packet if fifo is full.
		 */
		if (rx_char.notFull)
			rx_char.enq(truncate(rxReg));
		rx_state <= 0;
		pending_intr <= False;
	endrule

	/********************** TRANSMIT *********************/

	rule tx0(setup_done && !pending_intr && tx_state == 0 && tx_char.notEmpty);
		axilite_recv_start(axi, fromInteger(uartLite_reg_STAT));
		tx_state <= 1;
	endrule

	rule tx1(setup_done && !pending_intr && tx_state == 1);
		let statReg <- axilite_recv_get(axi);
		stat_reg <= truncate(statReg);

		// if we have a pending TX char and FIFO is nonempty then send it
		if (statReg[reg_STAT_TxFifoFull] == 0) begin
			let c = tx_char.first(); tx_char.deq();
			$display("[UART] send (c=%d)", c);

			axilite_send(axi, fromInteger(uartLite_reg_TX), c);
		end

		tx_state <= 0;
	endrule


	/******************************************************
	* INTERFACE
	******************************************************/
	method bit getTX();
		return uartIP.getTX();
	endmethod

	method Action putRX(bit rx);
		uartIP.putRX(rx);
	endmethod

	method Action send(Byte c) if (setup_done);
		tx_char.enq(c);
	endmethod

	method ActionValue#(Byte) receive();
		let data = rx_char.first(); rx_char.deq();
		return data;
	endmethod

	method Bit#(8) getStatus();
		return stat_reg;
	endmethod

endmodule

endpackage
