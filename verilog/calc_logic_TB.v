`timescale 1ns / 1ns
// Example testbench for calculator module
module calculatorTB;

	// Inputs of the module under test are created as type reg
	reg clk, rst, newkey;
	reg [4:0] keycode;

	// Outputs from the module under test are created as type wire
	wire [15:0] Xdisplay;
	wire LED_neg, LED_ovf;
	// Define names for the non-digit keys
	// Note the leftmost bit of the keycode is inverted - see later
	localparam [4:0] PLUS = 5'h1B, 
	                 MINUS = 5'h1A,
	                 MULTI = 5'h19, 
	                 SQR = 5'h11,
	                 CH_SIGN = 5'h12,
	                 EQUALS = 5'h13,
	                 CA = 5'h14,
	                 CE = 5'h1C;
	
	localparam CONSOLE = 1;  // file handle for console output
	
	// Testbench internal variables
	integer errorCount = 0;
	integer outFile;
	
	// Instantiate the Unit Under Test (UUT)
	calc_logic UUT (
        .clk (clk),
        .rst (rst),
        .keycode (keycode),
		.newkey (newkey),
		.LED_NEG_digit(LED_neg),
        .LED_OVW(LED_ovf),
        .Xdisplay (Xdisplay)
		);


// Generate the 5 MHz clock signal
	initial begin
		clk = 0;		// initialise clock
		#100;		// delay at start
		forever
		  #100 clk = ~clk;		// delay 100 ns and invert the clock
	end
	
// Define the test sequence
	initial begin
		outFile = $fopen("calcTB_log.txt");		// open the log file

		rst = 1'b0;			// initialize all the inputs
		keycode = 5'b0;
		newkey = 1'b0;

		#100;   			// delay before reset, so ouptut can be seen     
		rst = 1'b1;  		// reset pulse of at least one clock cycle
		@(negedge clk);	    // wait for falling clock edge
		@(negedge clk) rst = 1'b0;		// end pulse at second falling edge
		
		#200;		    // more delay, so effect of reset can be seen
		//Input 1234
        PRESS(1);
        PRESS(2);
        PRESS(3);
        PRESS(4);
        CHECK(16'h1234);
        //Testing Clear Entry
        PRESS(CE);
        CHECK(16'h0);
        
        //Test 12 change sign
        PRESS(1);
        PRESS(2);
        CHECK(16'h12);
        PRESS(CH_SIGN);
        CHECK(16'hffee);
        PRESS(CH_SIGN);
        CHECK(16'h12);
        //Testing addition, continuous addition then change sign +clear all
        PRESS(PLUS);
        PRESS(5);
        CHECK(16'h5);
        PRESS(EQUALS);
        CHECK(16'h17);
        PRESS(PLUS);
        PRESS(1);
        PRESS(1);
        PRESS(1);
        PRESS(1);
        CHECK(16'h1111);
        PRESS(EQUALS);
        CHECK(16'h1128);
        PRESS(CH_SIGN);
        CHECK(16'heed8);
        //test clearall
        PRESS(CA);
        CHECK(16'h0);
       
       //testing subtraction
        PRESS(5);
        PRESS(5'hd);
        PRESS(5'he);
        CHECK(16'h5de);
        PRESS(MINUS);
        PRESS(5'hf);
        PRESS(5'he);
        CHECK(16'hfe);
        PRESS(EQUALS);
        CHECK(16'h4e0);
        PRESS(CA);
        CHECK(16'h0);
        
        //testing multiplication
        PRESS(5);
        PRESS(1);
        PRESS(2);
        CHECK(16'h512);
        PRESS(MULTI);
        PRESS(2);
        PRESS(3);
        CHECK(16'h23);
        PRESS(EQUALS);
        CHECK(16'hb176);
        PRESS(CA);
        CHECK(16'h0);
        
        //testing squaring number
        PRESS(1);
        PRESS(2);
        CHECK(16'h12);
        PRESS(SQR);
        CHECK(16'h144);
        PRESS(CE);
        CHECK(16'h0);
        PRESS(1);
        PRESS(2);
        CHECK(16'h12);
        PRESS(CH_SIGN);
        CHECK(16'hffee);
        PRESS(SQR);
        CHECK(16'h144);
        PRESS(CA);
        CHECK(16'h0);
        
        
        //TESTING OVERFLOWS in addition, multiplication and plus
        PRESS(5'hf);
        PRESS(5'hf);
        PRESS(5'hf);
        PRESS(5'hf);
        CHECK(16'hffff);
        PRESS(PLUS);
        PRESS(5'hf);
        PRESS(5'hf);
        PRESS(5'hf);
        PRESS(5'hf);  
        CHECK(16'hffff);
        PRESS(EQUALS);
        CHECK(16'hfffe);
        PRESS(CA);
        CHECK(16'h0);
        
        PRESS(5);
        CHECK(16'h5);
        PRESS(MINUS);
        PRESS(5'h6);
        CHECK(16'h6);
        PRESS(EQUALS);
        CHECK(16'hffff);
        PRESS(CA);
        CHECK(16'h0);
        
        PRESS(5'hf);
        PRESS(5'hf);
        PRESS(5'hf);
        PRESS(5'hf);
        CHECK(16'hffff);
        PRESS(MULTI);
        PRESS(5'hf);
        PRESS(5'hf);
        PRESS(5'hf);
        PRESS(5'hf);  
        CHECK(16'hffff);
        PRESS(EQUALS);
        CHECK(16'h0001);
        PRESS(CA);  
        CHECK(16'h0);           
        
		// continue to implement the verification plan...
		#600;     // wait to see the effect of the last action
		$fclose(outFile);  // close the log file
		$display("Simulation finished with %d errors",errorCount);
		$stop;			// stop the simulation
	end


/*  Task to simulate input from the keypad.  Input to the task is a 5-bit value, 
    similar to the keycode, but with the MSB inverted.  This allows easier use 
    with digit keys.  The keypad hardware has outputs that change just after the
    rising edge of the clock, so this task will change the inputs to the calculator
    just after the rising edge of the clock.  */
	task PRESS (input [4:0] pseudoKeyCode);  
        begin
            @ (posedge clk);	// wait for clock edge
			#1 keycode = pseudoKeyCode ^ 5'h10;	// set keycode just after clock edge
			@ (negedge clk);	// wait for next clock edge
			#1 newkey = 1'b1;	// generate pulse on newkey, for one clock cycle
			@ (posedge clk);	
			#1 newkey = 1'b0;
			// log what has been pressed
			$fdisplay(outFile, "    time %t ps, key %h", $time, keycode);
			repeat(2)    //2 to shorten timing diagram
				@ (posedge clk);    // hold the keycode for 2 more clock cycles
			#1 keycode = 5'h0;	    // then remove it
		end
	endtask

/*  Task to check the output from the calculator.  Input to this task is a 16-bit
    value that is the expected output of the calculator.  The output is checked
    just at the falling edge of the clock, when it should be stable.  All outputs 
    are logged.  Any errors are reported on the console and in the log file.  */ 
	task CHECK (input [15:0] expectedX);
        begin
            @ (negedge clk);	// wait for falling edge of clock
            if (Xdisplay != expectedX)	
                begin   // error message to log file and to console
                    $fdisplay(outFile|CONSOLE, "*** time %t ps, X = %h, expected %h", 
                                $time, Xdisplay, expectedX);
                    errorCount = errorCount + 1;	// increment error counter
                end
            else  // output as expected, just record it in the log file
                $fdisplay(outFile, "    time %t ps, X = %h", $time, Xdisplay);
        end
    endtask
		
endmodule
