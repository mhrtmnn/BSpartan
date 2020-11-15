package Bs_top;

import ComponentUart::*;
import ComponentRGB::*;
import ComponentI2S::*;
import GlobalTypes::*;
import TriState::*;
import Timing::*;
import Vector::*;


/******************************************************
* CONSTANTS
******************************************************/
Integer c_debounce_delay  	= 200 * c_MS;
Integer c_led_blink_delay 	=   1 * c_S;

List#(Char) uart_hello = stringToCharList("Hello Hello World!\n\x0d");
List#(Char) uart_echo  = stringToCharList("Echo >>> 'X'\n\x0d");


/******************************************************
* FUNCTIONS
******************************************************/
function Inout#(t) tri_to_io(TriState#(t) ts);
	return ts.io;
endfunction


/******************************************************
* TOP MODULE
******************************************************/
interface Bs_top;
	interface Vector#(8, Inout#(bit)) io_gport_a;
	interface Vector#(8, Inout#(bit)) io_gport_b;

	(*always_enabled*)
	method bit update_rgb();
	(*always_enabled*)
	method Action set_buttons(Bool btn0, Bool btn1);
endinterface

module mkBs_top(Bs_top);
	/* sub modules */
	let rgb_drv 	<- mkRGBDriver();
	let uart_drv 	<- mkUARTip();
	let i2s 		<- mkI2Sip();

	/* state of GPIO ports */
	Vector#(10, Reg#(bit)) board_in 	<- replicateM(mkReg(0));
	Vector#(10, Reg#(bit)) board_out 	<- replicateM(mkReg(0));
	Vector#( 8, Reg#(bit)) r_gport_a 	<- replicateM(mkReg(0));
	Vector#( 8, Reg#(bit)) r_gport_b 	<- replicateM(mkReg(0));
	Vector#( 8, Reg#(Bool)) gport_a_en	<- replicateM(mkReg(True));
	Vector#( 8, Reg#(Bool)) gport_b_en	<- replicateM(mkReg(True));

	Vector#(8, TriState#(bit)) t_gport_a = newVector();
	Vector#(8, TriState#(bit)) t_gport_b = newVector();
	for (Integer i=0; i<8; i=i+1) begin
		t_gport_a[i] <- mkTriState(gport_a_en[i], r_gport_a[i]);
		t_gport_b[i] <- mkTriState(gport_b_en[i], r_gport_b[i]);
	end

	/* state of buttons */
	Wire#(Bool) btn0 <- mkWire();
	Wire#(Bool) btn1 <- mkWire();
	Wire#(Bool) debouncing0 <- mkWire();
	Wire#(Bool) debouncing1 <- mkWire();
	Reg#(UInt#(25)) debounce_counter0[2] <- mkCReg(2, 0);
	Reg#(UInt#(25)) debounce_counter1[2] <- mkCReg(2, 0);

	/* internal registers/wires */
	Reg#(Maybe#(Byte)) pnd_echo <- mkReg(tagged Invalid);
	Reg#(UInt#(27)) led_counter <- mkReg(0);
	Reg#(UInt#(5))  clk_counter <- mkReg(0);
	Reg#(Bool) uart_tx_running	<- mkReg(False);
	Reg#(Bit#(2)) rgb_state 	<- mkReg(0);
	Reg#(UInt#(5)) uart_pos 	<- mkReg(0);
	Reg#(Bit#(3)) port_val 		<- mkReg(0);
	Reg#(Bool) led0_state 		<- mkReg(False);
	Reg#(Bool) led1_state 		<- mkReg(True);
	Wire#(Bool) do_led 			<- mkWire();
	Wire#(Bool) do_clk 			<- mkWire();


	/******************************************************
	* RULES
	******************************************************/
	(* fire_when_enabled, no_implicit_conditions *)
	rule clk;

		/* condition for led rule */
		Bool cond_led = (led_counter == fromInteger(c_led_blink_delay));
		do_led <= cond_led;
		if (cond_led)
			led_counter <= 0;
		else
			led_counter <= led_counter + 1;

		/* condition for clk rule */
		Bool cond_clk = (clk_counter == 24);
		do_clk <= cond_clk;
		if (cond_clk)
			clk_counter <= 0;
		else
			clk_counter <= clk_counter + 1;
	endrule


	/************************* CLK ***********************/

	/* Rule is run every 0.25 us */
	(* fire_when_enabled *)
	rule clk_gen(do_clk);

		/* update gpios */
		board_out[9] <= port_val[0];
		board_out[8] <= port_val[1];

		port_val <= port_val + 1;
	endrule


	/************************* BTN ***********************/

	/* Toggle LED if btn0 is pressed */
	(* fire_when_enabled *)
	rule r_btn0(btn0 && !debouncing0);
		$display("[%d] btn0 was pressed!", $time);
		led1_state <= !led1_state;
		i2s.toggle_running();

		// start debouncing
		debounce_counter0[1] <= fromInteger(c_debounce_delay);
	endrule

	/* Send char via uart if btn1 is pressed */
	(* fire_when_enabled *)
	rule r_btn1(btn1 && !debouncing1 && !uart_tx_running);
		$display("[%d] btn1 was pressed!", $time);

		uart_tx_running <= True;

		// start debouncing
		debounce_counter1[1] <= fromInteger(c_debounce_delay);
	endrule

	/* debounce both buttons */
	(* fire_when_enabled *)
	rule debounce_release;
		if (debounce_counter0[0] > 0) begin
			debounce_counter0[0] <= debounce_counter0[0] - 1;
			debouncing0 <= True;
		end else begin
			debouncing0 <= False;
		end

		if (debounce_counter1[0] > 0) begin
			debounce_counter1[0] <= debounce_counter1[0] - 1;
			debouncing1 <= True;
		end else begin
			debouncing1 <= False;
		end
	endrule


	/************************ UART ***********************/

	rule uart_tx(uart_tx_running);
		List#(Char) msg;
		if (isValid(pnd_echo))
			msg = uart_echo;
		else
			msg = uart_hello;

		Integer msg_len = List::length(msg);
		if (uart_pos < fromInteger(msg_len) - 1) begin
			uart_pos <= uart_pos + 1;
		end else begin
			uart_pos <= 0;
			uart_tx_running <= False;
			pnd_echo <= tagged Invalid;
		end

		Char c = msg[uart_pos];
		Byte b;
		if (uart_pos == 10 && isValid(pnd_echo))
			b = fromMaybe(?, pnd_echo);
		else
			b = fromInteger(charToInteger(c));
		$display("Sending character %c (%d of %d)", c, uart_pos, msg_len);

		// Debug: test status read capabilities
		// if(uart_pos == 0 || uart_pos == 8) begin
		// 	b = uart_drv.getStatus();
		// end

		uart_drv.send(b);
	endrule

	rule echo(!uart_tx_running && !btn1);
		let c <- uart_drv.receive();
		$display("Received character %c, echoing back", c);

		pnd_echo <= tagged Valid c;
		uart_tx_running <= True;
	endrule


	/************************* LED ***********************/

	(* fire_when_enabled *)
	rule led(do_led);
		/* toggle led */
		led0_state <= !led0_state;

		/* iterate rgb led */
		case (rgb_state) matches
			0: begin
				rgb_drv.set_rgb(0, rgb_yellow);
				rgb_drv.set_rgb(1, rgb_white);
				rgb_state <= 1;
			end
			1: begin
				rgb_drv.set_rgb(0, rgb_pink);
				rgb_drv.set_rgb(1, rgb_red);
				rgb_state <= 2;
			end
			2: begin
				rgb_drv.set_rgb(0, rgb_turk);
				rgb_drv.set_rgb(1, rgb_green);
				rgb_state <= 3;
			end
			3: begin
				rgb_drv.set_rgb(0, rgb_off);
				rgb_drv.set_rgb(1, rgb_blue);
				rgb_state <= 0;
			end
		endcase
	endrule


	/************************ PINS ***********************/

	/* DEBUG: drive GPIO same way as RGB LED */
	// (* fire_when_enabled *)
	// rule debug_pin;
	// 	board_out[6] <= rgb_drv.update_rgb();
	// endrule

	/* Drive the I2S pins */
	(* fire_when_enabled, no_implicit_conditions *)
	rule i2s_update;
		board_out[0] <= i2s.getLRCLK();
		board_out[1] <= i2s.getSCLK();
		board_out[2] <= i2s.getSDATA();

		// DEBUG: Scope
		board_out[5] <= i2s.getLRCLK();
		board_out[6] <= i2s.getSCLK();
		board_out[7] <= i2s.getSDATA();
	endrule

	/* Drive the UART TX Pin and read the RX pin and pass it to the drv */
	(* fire_when_enabled, no_implicit_conditions *)
	rule uart_update;
		// set gport_a[3] as input
		gport_a_en[3] <= False;

		board_out[4] <= uart_drv.getTX();
		uart_drv.putRX(board_in[3]);

		// DEBUG: send RX+TX to scope
		// board_out[5] <= uart_drv.getTX();
		// board_out[6] <= board_in[3];
	endrule

	/* Connect high level board periphery to FPGA pins */
	(* fire_when_enabled, no_implicit_conditions *)
	rule drive_board_out;

		/* update gpios */
		r_gport_a[0] <= board_out[0]; // Pin IO0
		r_gport_a[1] <= board_out[1]; // Pin IO1
		r_gport_a[2] <= board_out[2]; // Pin IO2
		r_gport_a[3] <= board_out[3]; // Pin IO3
		r_gport_a[4] <= board_out[4]; // Pin IO4
		r_gport_a[5] <= board_out[5]; // Pin IO5
		r_gport_a[6] <= board_out[6]; // Pin IO6
		r_gport_a[7] <= board_out[7]; // Pin IO7
		r_gport_b[0] <= board_out[8]; // Pin IO8
		r_gport_b[1] <= board_out[9]; // Pin IO9

		/* update LEDs */
		r_gport_b[6] <= pack(led0_state);
		r_gport_b[7] <= pack(led1_state);
	endrule

	(* fire_when_enabled, no_implicit_conditions *)
	rule drive_board_in;

		board_in[0] <= t_gport_a[0]; // Pin IO0
		board_in[1] <= t_gport_a[1]; // Pin IO1
		board_in[2] <= t_gport_a[2]; // Pin IO2
		board_in[3] <= t_gport_a[3]; // Pin IO3
		board_in[4] <= t_gport_a[4]; // Pin IO4
		board_in[5] <= t_gport_a[5]; // Pin IO5
		board_in[6] <= t_gport_a[6]; // Pin IO6
		board_in[7] <= t_gport_a[7]; // Pin IO7
		board_in[8] <= t_gport_b[0]; // Pin IO8
		board_in[9] <= t_gport_b[1]; // Pin IO9
	endrule


	/******************************************************
	* INTERFACE
	******************************************************/
	interface io_gport_a = map(tri_to_io, t_gport_a);
	interface io_gport_b = map(tri_to_io, t_gport_b);

	method Action set_buttons(Bool p_btn0, Bool p_btn1);
		/* active low */
		btn0 <= !p_btn0;
		btn1 <= !p_btn1;
	endmethod

	method bit update_rgb = rgb_drv.update_rgb;

endmodule

endpackage
