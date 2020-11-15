module myI2S_wrapper(s_axi_ctrl_aclk, s_axi_ctrl_aresetn, 
	aud_mclk, aud_mrst, s_axis_aud_aclk, s_axis_aud_aresetn, s_axi_ctrl_awvalid, 
	s_axi_ctrl_awready, s_axi_ctrl_awaddr, s_axi_ctrl_wvalid, s_axi_ctrl_wready, 
	s_axi_ctrl_wdata, s_axi_ctrl_bvalid, s_axi_ctrl_bready, s_axi_ctrl_bresp, 
	s_axi_ctrl_arvalid, s_axi_ctrl_arready, s_axi_ctrl_araddr, s_axi_ctrl_rvalid, 
	s_axi_ctrl_rready, s_axi_ctrl_rdata, s_axi_ctrl_rresp, irq, lrclk_out, sclk_out, sdata_0_out, 
	s_axis_aud_tdata, s_axis_aud_tid, s_axis_aud_tvalid, s_axis_aud_tready, s_axi_ctrl_wstrb);

	input s_axi_ctrl_aclk;
	input s_axi_ctrl_aresetn;
	input aud_mclk;
	input aud_mrst;
	input s_axis_aud_aclk;
	input s_axis_aud_aresetn;
	input s_axi_ctrl_awvalid;
	output s_axi_ctrl_awready;
	input [7:0]s_axi_ctrl_awaddr;
	input s_axi_ctrl_wvalid;
	output s_axi_ctrl_wready;
	input [31:0]s_axi_ctrl_wdata;
	output s_axi_ctrl_bvalid;
	input s_axi_ctrl_bready;
	output [1:0]s_axi_ctrl_bresp;
	input s_axi_ctrl_arvalid;
	output s_axi_ctrl_arready;
	input [7:0]s_axi_ctrl_araddr;
	output s_axi_ctrl_rvalid;
	input s_axi_ctrl_rready;
	output [31:0]s_axi_ctrl_rdata;
	output [1:0]s_axi_ctrl_rresp;
	output irq;
	output lrclk_out;
	output sclk_out;
	output sdata_0_out;
	input [31:0]s_axis_aud_tdata;
	input [2:0]s_axis_aud_tid;
	input s_axis_aud_tvalid;
	output s_axis_aud_tready;
	input [3:0] s_axi_ctrl_wstrb;

	/* this is the xilinx IP core, which does not have WSTRB */
	myI2S i2s_i2s(
		.aud_mclk(aud_mclk),
		.aud_mrst(aud_mrst),
		.s_axi_ctrl_aclk(s_axi_ctrl_aclk),
		.s_axi_ctrl_araddr(s_axi_ctrl_araddr),
		.s_axi_ctrl_aresetn(s_axi_ctrl_aresetn),
		.s_axi_ctrl_arvalid(s_axi_ctrl_arvalid),
		.s_axi_ctrl_awaddr(s_axi_ctrl_awaddr),
		.s_axi_ctrl_awvalid(s_axi_ctrl_awvalid),
		.s_axi_ctrl_bready(s_axi_ctrl_bready),
		.s_axi_ctrl_rready(s_axi_ctrl_rready),
		.s_axi_ctrl_wdata(s_axi_ctrl_wdata),
		.s_axi_ctrl_wvalid(s_axi_ctrl_wvalid),
		.s_axis_aud_aclk(s_axis_aud_aclk),
		.s_axis_aud_aresetn(s_axis_aud_aresetn),
		.s_axis_aud_tdata(s_axis_aud_tdata),
		.s_axis_aud_tid(s_axis_aud_tid),
		.s_axis_aud_tvalid(s_axis_aud_tvalid),
		.s_axi_ctrl_awready(s_axi_ctrl_awready),
		.s_axi_ctrl_wready(s_axi_ctrl_wready),
		.s_axi_ctrl_bvalid(s_axi_ctrl_bvalid),
		.s_axi_ctrl_bresp(s_axi_ctrl_bresp),
		.s_axi_ctrl_arready(s_axi_ctrl_arready),
		.s_axi_ctrl_rvalid(s_axi_ctrl_rvalid),
		.s_axi_ctrl_rdata(s_axi_ctrl_rdata),
		.s_axi_ctrl_rresp(s_axi_ctrl_rresp),
		.s_axis_aud_tready(s_axis_aud_tready),
		.irq(),
		.lrclk_out(lrclk_out),
		.sclk_out(sclk_out),
		.sdata_0_out(sdata_0_out)
	);

endmodule
