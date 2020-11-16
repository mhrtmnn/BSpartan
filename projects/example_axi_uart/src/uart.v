module test(
	// common
	input clk,
	input rst_n,

	// gpio group A
	inout [7:0] gport_a
	);

	// signals to modules
	reg i_rst_n = 0;

	// reset
	reg [31:0] counter = 0;
	reg rst_done = 0;
	always @(posedge clk) begin
		counter = counter + 1;
		if (!rst_done && counter == 20) begin
			i_rst_n = 1;
			rst_done = 1;
		end
	end

	wire reset_rtl_0;
	wire uart_rtl_0_rxd;
	wire uart_rtl_0_txd;

	assign reset_rtl_0 = ~i_rst_n;
	assign clk_100MHz = clk;

	// data lines
	assign uart_rtl_0_rxd = 0;
	assign uart_rtl_0_txd = gport_a[5];

	// instantiate block design
	jtag_to_uart myUart
	   (.clk_100MHz(clk_100MHz),
	    .reset_rtl_0(reset_rtl_0),
	    .uart_rtl_0_rxd(uart_rtl_0_rxd),
	    .uart_rtl_0_txd(uart_rtl_0_txd));

endmodule
