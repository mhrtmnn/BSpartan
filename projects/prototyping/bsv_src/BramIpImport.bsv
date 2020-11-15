package BramIpImport;

import AxiBridge::*;


/******************************************************
* VERILOG BRIDGE: BRAM BD
******************************************************/
interface BramIp;

	// system
	method Action putRSTn(bit rst);

	// AXI iface
	interface AxiLiteIface#(32, 12) axi;

endinterface


// this binds the Verilog ports to methods
// eg: Verilog in=A,b; out=X
//		method start (A, B) enable((*inhigh*) unused1); // is always enabled
//		method X result ;

import "BVI" myDesign =
module mkBramIp (BramIp);
	default_clock clk();         // no clock connections
	default_reset rst();         // no reset connections

	/* system signals */
	method putRSTn(s_axi_aresetn_0) 					enable((*inhigh*) EN1);

	/* AXI signals */
	interface AxiLiteIface axi;

		method putCLK(s_axi_aclk_0) 					enable((*inhigh*) EN2);

		// Write Address channel (AW) Channel
		method putAW(S_AXI_0_awaddr,
					 S_AXI_0_awvalid)					enable((*inhigh*) EN3);
		method S_AXI_0_awready 	getAWready();


		// Write Data channel (W) Channel
		method putW(S_AXI_0_wdata,
					S_AXI_0_wvalid,
					S_AXI_0_wstrb) 						enable((*inhigh*) EN4);
		method S_AXI_0_wready 	getWready();

		// Write Response channel (B) Channel
		method putB(S_AXI_0_bready) 					enable((*inhigh*) EN5);
		method S_AXI_0_bvalid 	getBvalid();
		method S_AXI_0_bresp 		getBresp();

		// Read Address channel (AR) Channel
		method putAR(S_AXI_0_araddr,
					 S_AXI_0_arvalid) 					enable((*inhigh*) EN6);
		method S_AXI_0_arready 	getARready();

		// Read Data channel (R) Channel
		method putR(S_AXI_0_rready) 					enable((*inhigh*) EN7);
		method S_AXI_0_rvalid 	getRvalid();
		method S_AXI_0_rdata 		getRdata();
		method S_AXI_0_rresp 		getRresp();

	endinterface


	/* scheduling info */
	schedule
	(axi_putCLK, putRSTn, axi_putAW, axi_putW, axi_putB, axi_putAR, axi_putR)
	CF
	(axi_putCLK, putRSTn, axi_putAW, axi_putW, axi_putB, axi_putAR, axi_putR);

	schedule
	(axi_getAWready, axi_getWready, axi_getBvalid,
	axi_getBresp, axi_getARready, axi_getRvalid, axi_getRdata, axi_getRresp)
	CF
	(axi_putCLK, putRSTn, axi_putAW, axi_putW, axi_putB, axi_putAR, axi_putR);

	schedule
	(axi_getAWready, axi_getWready, axi_getBvalid,
	axi_getBresp, axi_getARready, axi_getRvalid, axi_getRdata, axi_getRresp)
	CF
	(axi_getAWready, axi_getWready, axi_getBvalid,
	axi_getBresp, axi_getARready, axi_getRvalid, axi_getRdata, axi_getRresp);

endmodule

endpackage
