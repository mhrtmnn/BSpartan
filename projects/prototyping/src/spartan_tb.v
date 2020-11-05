`timescale 1ns / 1ns

module spartan_tb;
	reg i_clk;
	reg i_rst_n;
	reg [7:0] i_gport_e = 8'd0;
	wire [7:0] w_gport_e;
	assign w_gport_e = i_gport_e;

	spartan_top dut(
		.clk(i_clk),
		.rst_n(i_rst_n),
		.gport_e(w_gport_e)
	);

	initial // initial block executes only once
	begin
		$dumpfile("dump.vcd");
		$dumpvars(0, dut);
		i_rst_n = 1;
		i_clk = 1'b0;

		// BTNs are active low
		i_gport_e[4] = 1;
		i_gport_e[5] = 1;
		i_gport_e[6] = 1;

		#1000;

		// simulate button press
		$display("---> Btn low");
		i_gport_e[5] = 0;

		#10;

		$display("---> Btn high");
		i_gport_e[5] = 1;

		#10000;

		// finish simulation
		$display("---> DONE!");
		$finish();
	end

	// 100 MHz clock (T = 10ns)
	always 
	begin
		i_clk = !i_clk; 
		#5;
	end

endmodule
