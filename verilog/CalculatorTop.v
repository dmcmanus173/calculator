//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Brian Mulkeen
// Target Device: XC7A100T-csg324 on Digilent Nexys 4 board
// Description:   Top-level module for calculator design.
//                Defines top-level input and output signals.
//                Instantiates clock and reset generator block, for 5 MHz clock
//                Instantiates other modules to implement calculator...
//                Includes temporary keypad test hardware
//  Created: 30 October 2015
//  Keypad test hardware added 6 November 2017
//////////////////////////////////////////////////////////////////////////////////
module calculator_top(
        input clk100,		 // 100 MHz clock from oscillator on board
        input rstPBn,		 // reset signal, active low, from CPU RESET pushbutton
        input [5:0] kpcol,   // keypad column signals
        output [3:0] kprow,  // keypad row signals
        output [7:0] digit,  // digit controls - active low (7 on left, 0 on right)
        output [7:0] segment, // segment controls - active low (a b c d e f g dp)
        output NEG_LED,
        output OVW_LED
        );

// ===========================================================================
// Interconnecting Signals
    wire clk5;              // 5 MHz clock signal, buffered
    wire reset;             // internal reset signal, active high
    wire newkey;            // pulse to indicate new key pressed, keycode valid
    wire [4:0] keycode;     // 5-bit code to identify key pressed
    wire [15:0] calcOut;    // 16-bit output from calculator, to be displayed
	
// ===========================================================================
// Instantiate clock and reset generator, connect to signals
    clockReset  clkGen  (
            .clk100 (clk100),
            .rstPBn (rstPBn),
            .clk5   (clk5),
            .reset  (reset) );

//==================================================================================
// Calculator logic - instantiate your calculator here
	calc_logic calculator (
        .clk (clk5),
        .rst (reset),
        .keycode (keycode),
        .newkey (newkey),
        .Xdisplay (calcOut),
        .LED_NEG_digit(NEG_LED),
        .LED_OVW(OVW_LED)
        );

//==================================================================================
// Keypad interface to scan keypad and return valid keycodes
    keypad keyp1 (
        .clk(clk5),            // clock for keypad module is 5 MHz
        .rst(reset),            // reset is internal reset signal
        .kpcol(kpcol),            // 6 keypad column inputs
        .kprow(kprow),            // 4 keypad row outputs
        .newkey(newkey),        // new key signal
        .keycode(keycode)        // 5-bit code representing key
        );

//==================================================================================
// Display interface, for 4 digits - replace with your display interface
	DisplayInterface display (
	       .clock(clk5), 
	       .reset(reset), 
	       .value(calcOut),
	       .points(4'b0000),    // use a dot to separate key codes for test
		   .digit(digit), // only using rightmost 4 digits
		   .segment(segment)
		   );
	
	
endmodule
