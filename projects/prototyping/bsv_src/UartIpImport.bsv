package UartIpImport;

import AxiBridge::*;


/******************************************************
* VERILOG BRIDGE: UART IP CORE
******************************************************/
interface UartLiteIp;

	// UART Tfer
	method Action putRX(bit tx);
	method bit getTX();

	// system
	method Action putRSTn(bit rst);
	method bit getInterrupt();

	// AXI CHANNELS
	interface AxiLiteIface#(32, 4) axi;

endinterface


// this binds the Verilog ports to methods
// eg: Verilog in=A,b; out=X
//      method start (A, B) enable((*inhigh*) unused1); // is always enabled
//      method X result ;

import "BVI" myUartLite =
module mkUartLiteIp (UartLiteIp);
	default_clock clk();         // no clock connections
	default_reset rst();         // no reset connections

	/* UART data signals */
	method tx                   getTX();
	method putRX(rx)                                enable((*inhigh*) EN0);

	/* system signals */
	method putRSTn(s_axi_aresetn)                   enable((*inhigh*) EN1);
	method interrupt            getInterrupt();

	/* AXI signals */
	interface AxiLiteIface axi;

		method putCLK(s_axi_aclk)                   enable((*inhigh*) EN2);

		// Write Address channel (AW) Channel
		method putAW(s_axi_awaddr,
		             s_axi_awvalid)                 enable((*inhigh*) EN3);
		method s_axi_awready    getAWready();


		// Write Data channel (W) Channel
		method putW(s_axi_wdata,
		            s_axi_wvalid,
		            s_axi_wstrb)                    enable((*inhigh*) EN4);
		method s_axi_wready     getWready();

		// Write Response channel (B) Channel
		method putB(s_axi_bready)                   enable((*inhigh*) EN5);
		method s_axi_bvalid     getBvalid();
		method s_axi_bresp      getBresp();

		// Read Address channel (AR) Channel
		method putAR(s_axi_araddr,
		             s_axi_arvalid)                 enable((*inhigh*) EN6);
		method s_axi_arready    getARready();

		// Read Data channel (R) Channel
		method putR(s_axi_rready)                   enable((*inhigh*) EN7);
		method s_axi_rvalid     getRvalid();
		method s_axi_rdata      getRdata();
		method s_axi_rresp      getRresp();

	endinterface


	/* scheduling info */
	schedule
	(putRX, axi_putCLK, putRSTn, axi_putAW, axi_putW, axi_putB, axi_putAR, axi_putR)
	CF
	(putRX, axi_putCLK, putRSTn, axi_putAW, axi_putW, axi_putB, axi_putAR, axi_putR);

	schedule
	(getTX, getInterrupt, axi_getAWready, axi_getWready, axi_getBvalid,
	axi_getBresp, axi_getARready, axi_getRvalid, axi_getRdata, axi_getRresp)
	CF
	(putRX, axi_putCLK, putRSTn, axi_putAW, axi_putW, axi_putB, axi_putAR, axi_putR);

	schedule
	(getTX, getInterrupt, axi_getAWready, axi_getWready, axi_getBvalid,
	axi_getBresp, axi_getARready, axi_getRvalid, axi_getRdata, axi_getRresp)
	CF
	(getTX, getInterrupt, axi_getAWready, axi_getWready, axi_getBvalid,
	axi_getBresp, axi_getARready, axi_getRvalid, axi_getRdata, axi_getRresp);

endmodule

endpackage
