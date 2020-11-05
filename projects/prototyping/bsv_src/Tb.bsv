package Tb;
import Bs_top::*;

module mkTb(Empty);
	let dut <- mkBs_top();

	rule killer;
		let t <- $time;
		if (t > 1000000)
			$finish();
	endrule

	rule gport_a;
		dut.set_buttons(False, False);
		let v1 = dut.update_gport_a();
		let v2 = dut.update_gport_b();
		let v3 = dut.update_rgb();
		// $display("[%d] Gport_a: %d, Gport_b: %d, RGB: %d", $time, v1, v2, v3);
	endrule

endmodule

endpackage
