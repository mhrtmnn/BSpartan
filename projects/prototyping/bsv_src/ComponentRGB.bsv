package ComponentRGB;

import GlobalTypes::*;
import Timing::*;
import Vector::*;


/******************************************************
* GLOBAL TYPES/FUNCTIONS/DATA
******************************************************/
typedef Vector#(3, Byte) RGB_color;


/******************************************************
* CONSTANTS
******************************************************/
Byte onn = 8'h10;
Byte off = 8'h00;
// RGB Color                 [ RR   GG   BB  ]
RGB_color rgb_off    = unpack({off, off, off});
RGB_color rgb_white  = unpack({onn, onn, onn});
RGB_color rgb_red    = unpack({onn, off, off});
RGB_color rgb_green  = unpack({off, onn, off});
RGB_color rgb_blue   = unpack({off, off, onn});
RGB_color rgb_yellow = unpack({onn, onn, off});
RGB_color rgb_pink   = unpack({onn, off, onn});
RGB_color rgb_turk   = unpack({off, onn, onn});

/* SK6805 timing values */
Integer c_T0H             =  30 * c_10NS;
Integer c_T1H             =  95 * c_10NS;
Integer c_T0L             =  90 * c_10NS;
Integer c_T1L             =  25 * c_10NS;
Integer c_TRST            =  80 * c_US;


/******************************************************
* Component Driver: RGB LED
******************************************************/
interface RGBDriver;
	(*always_enabled*)
	method bit update_rgb();
	method Action set_rgb(bit num, RGB_color c);
endinterface


module mkRGBDriver(RGBDriver);
	/* internal state */
	Reg#(Bool) init_done <- mkReg(False);
	Reg#(UInt#(20)) comp <- mkReg(0);
	Reg#(UInt#(2)) state <- mkReg(3);
	Reg#(UInt#(5)) pos <- mkReg(0);
	Reg#(bit) led_num <- mkReg(0);

	/* value used to drive the DIN pin */
	Reg#(bit) rgb_data <- mkReg(0);

	/* code word to send */
	Vector#(2, Reg#(RGB_color)) rgb_word <- replicateM(mkRegU());


	/******************************************************
	* RULES
	******************************************************/
	(* fire_when_enabled *)
	rule init(!init_done);
		for (Integer i=0; i<2; i=i+1)
			rgb_word[i] <= rgb_white;

		init_done <= True;
		comp <= 0;
	endrule

	(* fire_when_enabled *)
	rule tick(init_done && comp > 0);
		comp <= comp - 1;
	endrule

	(* fire_when_enabled *)
	rule clk(init_done && comp == 0);

		/* [GGGGGGGG RRRRRRRR BBBBBBBB] */
		Bit#(24) arr = pack({rgb_word[led_num][0], rgb_word[led_num][1], rgb_word[led_num][2]});
		bit val = arr[pos]; // Fixme

		/**
		 * Clk is 100MHz, ie one cycle is 10ns.
		 */
		case(state) matches
			/* write high part */
			0: begin
				$display("[RGB] [%d] Write HIGH (value: %d, pos: %d)", $time, val, pos);
				rgb_data <= 1;
				if (val == 0) begin
					comp <= fromInteger(c_T0H);
				end else begin
					comp <= fromInteger(c_T1H);
				end
				state <= 1;
			end

			/* write low part */
			1: begin
				$display("[RGB] [%d] Write LOW  (value: %d, pos: %d)", $time, val, pos);
				rgb_data <= 0;
				if (val == 0) begin
					comp <= fromInteger(c_T0L);
				end else begin
					comp <= fromInteger(c_T1L);
				end

				if (led_num == 0 && pos == 23) begin
					/* LED1 word done */
					pos <= 0;
					led_num <= 1;
					state <= 0; // maybe pause?
				end else if (led_num == 1 && pos == 23) begin
					/* LED2 word done */
					pos <= 0;
					led_num <= 0;
					state <= 3;
				end else begin
					/* within a word */
					pos <= pos + 1;
					state <= 0;
				end
			end

			/* write reset part */
			2: begin
				$display("[RGB] [%d] Write RST  (value: %d, pos: %d)", $time, val, pos);
				rgb_data <= 0;

				comp <= fromInteger(c_TRST);
				state <= 0;
			end

			/* idle */
			3: begin
				$display("[RGB] [%d] idling", $time);
				rgb_data <= 0;

				comp <= 100 * fromInteger(c_US);
				state <= 0;
			end
		endcase
	endrule


	/******************************************************
	* INTERFACE
	******************************************************/
	method bit update_rgb();
		return rgb_data;
	endmethod

	method Action set_rgb(bit num, RGB_color c) if (init_done);
		/* Translate [RGB] to [GRB] that is needed by SK6805 */
		Vector#(3, Byte) vec = unpack(pack(c));
		RGB_color newCol = unpack({vec[1], vec[2], vec[0]});

		rgb_word[num] <= newCol;
	endmethod

endmodule

endpackage
