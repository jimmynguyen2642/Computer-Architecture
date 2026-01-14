module stimulus ();

   logic   clock;
   logic   In;
   logic   reset;
   
   logic   Out;
   
   integer handle3;
   integer desc3;
   
   // Instantiate DUT
   fsm dut (clock, reset, In, Out);

   // Setup the clock to toggle every 1 time units 
   initial 
     begin	
	clock = 1'b1;
	forever #5 clock = ~clock;
     end

   initial
     begin
	// Gives output file name
	handle3 = $fopen("test.out");
	// Tells when to finish simulation
	#500 $finish;		
     end

   always 
     begin
	desc3 = handle3;
	#5 $fdisplay(desc3, "%b %b || %b", 
		     reset, In, Out);
     end   
   
   initial 
     begin      
	#0  reset = 1'b0;
	#12 reset = 1'b1;	
     #15 reset = 1'b0; // Start on S0
	// #0  In = 1'b0; //S0 to S1
	// #20 In = 1'b1; //S1 to S2
	// #20 In = 1'b0; //S2 to S1
     // #20 In = 1'b0; //S1 to S1
     // #20 In = 1'b1; //S1 to S2
     // #20 In = 1'b1; //S2 to S0
     // #20 In = 1'b0; //S0 to S1 
     // #20 In = 1'b1; //S1 to S2
     // #20 In = 1'b1; //S2 to S0
     // #20 In = 1'b1; //End
     @(negedge clock); In = 1'b0;
     @(negedge clock); In = 1'b1;
     @(negedge clock); In = 1'b0;
     @(negedge clock); In = 1'b0;
     @(negedge clock); In = 1'b1;
     @(negedge clock); In = 1'b1;
     @(negedge clock); In = 1'b0;
     @(negedge clock); In = 1'b1;
     @(negedge clock); In = 1'b1;
     @(negedge clock); In = 1'b1;
     end

endmodule // stimulus


