`include "src/mkBs_top.v"

/**
 * Top Module that instantiates BSV module and connects it to the FPGA HW
 */
module spartan_top(
	// common
	input clk,
	input rst_n,

	// spi
	input spi_clk,
	input spi_fss,
	input spi_in,
	output spi_out,

	// RGB Led
	output sk6805_do,

	// gpio group A
	inout [7:0] gport_a,

	// gpio group B
	inout [7:0] gport_b,

	// gpio group E
	inout [7:0] gport_e
	);

	// signals to bs module
	reg i_rst_n = 0;
	wire btn_usr0;
	wire btn_usr1;
	wire btn_rst;

	assign btn_usr0 = gport_e[4];
	assign btn_usr1 = gport_e[5];
	assign btn_rst  = gport_e[6];

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

	// attach BS module
	mkBs_top bstop(
		.CLK(clk),
		.RST_N(i_rst_n & btn_rst),
		
		.io_gport_a_0(gport_a[0]),
		.io_gport_a_1(gport_a[1]),
		.io_gport_a_2(gport_a[2]),
		.io_gport_a_3(gport_a[3]),
		.io_gport_a_4(gport_a[4]),
		.io_gport_a_5(gport_a[5]),
		.io_gport_a_6(gport_a[6]),
		.io_gport_a_7(gport_a[7]),

		.io_gport_b_0(gport_b[0]),
		.io_gport_b_1(gport_b[1]),
		.io_gport_b_2(gport_b[2]),
		.io_gport_b_3(gport_b[3]),
		.io_gport_b_4(gport_b[4]),
		.io_gport_b_5(gport_b[5]),
		.io_gport_b_6(gport_b[6]),
		.io_gport_b_7(gport_b[7]),

		.update_rgb(sk6805_do),
		.set_buttons_btn0(btn_usr0),
		.set_buttons_btn1(btn_usr1)
	);

endmodule
