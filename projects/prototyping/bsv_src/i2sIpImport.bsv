package i2sIpImport;

import AxiStreamBridge::*;
import AxiBridge::*;


/******************************************************
* VERILOG BRIDGE: I2S IP CORE
******************************************************/
interface I2SIp;

	// I2S Tfer
	method bit getIRQ();
	method bit getLRCLK();
	method bit getSCLK();
	method bit getSDATA();

	// system
	method Action putRSTn(bit rst_axi, bit rst_axis, bit rst_dev);
	method Action putCLK(bit clk);

	// AXI CHANNELS
	interface AxiLiteIface#(32, 8) 	ctrl_axi;
	interface AxiStreamIface#(32) 	axis;

endinterface


// this binds the Verilog ports to methods
// eg: Verilog in=A,b; out=X
//		method start (A, B) enable((*inhigh*) unused1); // is always enabled
//		method X result ;

import "BVI" myI2S_wrapper =
module mkI2SIp (I2SIp);
	default_clock clk();         // no clock connections
	default_reset rst();         // no reset connections

	/* I2S data signals */
	method irq 						getIRQ();
	method lrclk_out 				getLRCLK();
	method sclk_out 				getSCLK();
	method sdata_0_out 				getSDATA();

	/* system signals */
	method putCLK(aud_mclk) 						enable((*inhigh*) EN0);
	method putRSTn(s_axi_ctrl_aresetn,
				   s_axis_aud_aresetn,
				   aud_mrst) 						enable((*inhigh*) EN1);

	/* AXI Lite signals */
	interface AxiLiteIface ctrl_axi;

		method putCLK(s_axi_ctrl_aclk) 				enable((*inhigh*) EN2);

		// Write Address channel (AW) Channel
		method putAW(s_axi_ctrl_awaddr,
					 s_axi_ctrl_awvalid)			enable((*inhigh*) EN3);
		method s_axi_ctrl_awready 	getAWready();


		// Write Data channel (W) Channel
		method putW(s_axi_ctrl_wdata,
					s_axi_ctrl_wvalid,
					s_axi_ctrl_wstrb) 				enable((*inhigh*) EN4);
		method s_axi_ctrl_wready 	getWready();

		// Write Response channel (B) Channel
		method putB(s_axi_ctrl_bready) 				enable((*inhigh*) EN5);
		method s_axi_ctrl_bvalid 	getBvalid();
		method s_axi_ctrl_bresp 	getBresp();

		// Read Address channel (AR) Channel
		method putAR(s_axi_ctrl_araddr,
					 s_axi_ctrl_arvalid) 			enable((*inhigh*) EN6);
		method s_axi_ctrl_arready 	getARready();

		// Read Data channel (R) Channel
		method putR(s_axi_ctrl_rready) 				enable((*inhigh*) EN7);
		method s_axi_ctrl_rvalid 	getRvalid();
		method s_axi_ctrl_rdata 	getRdata();
		method s_axi_ctrl_rresp 	getRresp();

	endinterface


	/* AXI Stream signals */
	interface AxiStreamIface axis;

		method putCLK(s_axis_aud_aclk) 				enable((*inhigh*) EN8);

		// Stream data channel
		method putData(s_axis_aud_tid,
					   s_axis_aud_tdata,
					   s_axis_aud_tvalid)			enable((*inhigh*) EN9);
		method s_axis_aud_tready 	getReady();

	endinterface


	/* scheduling info */
	schedule
	(putCLK,putRSTn,
	axis_putCLK,axis_putData,
	ctrl_axi_putCLK,ctrl_axi_putAW,ctrl_axi_putW,ctrl_axi_putB,ctrl_axi_putAR,ctrl_axi_putR)
	CF
	(putCLK,putRSTn,
	axis_putCLK,axis_putData,
	ctrl_axi_putCLK,ctrl_axi_putAW,ctrl_axi_putW,ctrl_axi_putB,ctrl_axi_putAR,ctrl_axi_putR);

	schedule
	(putCLK,putRSTn,
	axis_putCLK,axis_putData,
	ctrl_axi_putCLK,ctrl_axi_putAW,ctrl_axi_putW,ctrl_axi_putB,ctrl_axi_putAR,ctrl_axi_putR)
	CF
	(axis_getReady,
	getIRQ,getLRCLK,getSCLK,getSDATA,
	ctrl_axi_getRvalid,ctrl_axi_getRdata,ctrl_axi_getRresp,
	ctrl_axi_getAWready,ctrl_axi_getWready,ctrl_axi_getBvalid,ctrl_axi_getBresp,ctrl_axi_getARready);

	schedule
	(axis_getReady,
	getIRQ,getLRCLK,getSCLK,getSDATA,
	ctrl_axi_getRvalid,ctrl_axi_getRdata,ctrl_axi_getRresp,
	ctrl_axi_getAWready,ctrl_axi_getWready,ctrl_axi_getBvalid,ctrl_axi_getBresp,ctrl_axi_getARready)
	CF
	(axis_getReady,
	getIRQ,getLRCLK,getSCLK,getSDATA,
	ctrl_axi_getRvalid,ctrl_axi_getRdata,ctrl_axi_getRresp,
	ctrl_axi_getAWready,ctrl_axi_getWready,ctrl_axi_getBvalid,ctrl_axi_getBresp,ctrl_axi_getARready);

endmodule

endpackage
