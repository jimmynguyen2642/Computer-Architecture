module regfile 
   (input logic         clk, 
		input logic 	    we3, 
		input logic [4:0]   ra1, ra2, wa3, 
		input logic [31:0]  wd3, 
		output logic [31:0] rd1, rd2);
   
   logic [31:0] 		    rf[31:0];
   
   // three ported register file
   // read two ports combinationally
   // write third port on rising edge of clock
   // register 0 hardwired to 0

   //write port 
   always_ff @(posedge clk) begin
      if (we3 && (wa3 != 5'd0)) begin
         rf[wa3] <= wd3;
      end
   end

   //read ports (combinational)
   always_comb begin
      rd1 = (ra1 == 5'd0) ? 32'd0 : rf[ra1];
      rd2 = (ra2 == 5'd0) ? 32'd0 : rf[ra2];
   end
   
   
endmodule // regfile
