module stimulus ();

    logic clk;
    logic we3;
    logic [4:0] ra1, ra2, wa3;
    logic [31:0] wd3;
    logic [31:0] rd1, rd2;

    // DUT Instantiation
    regfile dut (
        .clk(clk),
        .we3(we3),
        .ra1(ra1),
        .ra2(ra2),
        .wa3(wa3),
        .wd3(wd3),
        .rd1(rd1),
        .rd2(rd2)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // helper: set read addresses for regfile
  task automatic set_reads(input logic [4:0] a1, input logic [4:0] a2);
    begin
      ra1 = a1;
      ra2 = a2;
      #1; // allow combinational settle
    end
  endtask

  // helper: synchronous write to register file
  task automatic write_reg(input logic [4:0] addr, input logic [31:0] data);
    begin
      wa3 = addr;
      wd3 = data;
      we3 = 1'b1;
      @(posedge clk); #1; // write occurs at posedge
      we3 = 1'b0;
    end
  endtask

  integer i;

  initial begin
    // init
    we3 = 1'b0;
    ra1 = 5'd0; ra2 = 5'd0;
    wa3 = 5'd0;
    wd3 = 32'd0;
    end

endmodule // stimulus