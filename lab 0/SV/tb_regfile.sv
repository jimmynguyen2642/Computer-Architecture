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
      @(negedge clk);
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

    $display("TB START %0t", $time);

    // Test 1: x0 always reads 0
    set_reads(5'd0, 5'd0);
    assert(rd1 == 32'd0 && rd2 == 32'd0)
        else $fatal("FAIL: x0 did not read as 0");

    // "Reset": initialize regs 1..31 to 0
    for (i = 1; i < 32; i = i + 1) begin
        write_reg(i[4:0], 32'd0);
    end

    // Verify all regs read 0
    for (i = 0; i < 32; i = i + 1) begin
        set_reads(i[4:0], i[4:0]);
        assert(rd1 == 32'd0 && rd2 == 32'd0)
        else $fatal("FAIL: reg %0d not 0 after init", i);
    end

    // Test 2: basic write + readback
    write_reg(5'd5, 32'hAAAAAAAA);
    set_reads(5'd5, 5'd0);
    assert(rd1 == 32'hAAAAAAAA) else $fatal("FAIL: r5 readback wrong");
    assert(rd2 == 32'd0)        else $fatal("FAIL: x0 not 0");

    // Test 3: read same reg on both ports
    set_reads(5'd5, 5'd5);
    assert(rd1 == 32'hAAAAAAAA && rd2 == 32'hAAAAAAAA)
        else $fatal("FAIL: dual read wrong");

    // Test 4: write enable gating (we3=0 should not write)
    wa3 = 5'd6;
    wd3 = 32'h12345678;
    we3 = 1'b0;
    @(posedge clk); #1;
    set_reads(5'd6, 5'd6);
    assert(rd1 == 32'd0 && rd2 == 32'd0)
        else $fatal("FAIL: write happened with we3=0");

    // Test 5: writing x0 has no effect
    write_reg(5'd0, 32'hFFFFFFFF);
    set_reads(5'd0, 5'd0);
    assert(rd1 == 32'd0 && rd2 == 32'd0)
        else $fatal("FAIL: x0 changed");

    // Test 6: read while being updated (read-after-write)
    set_reads(5'd7, 5'd7);
    wa3 = 5'd7;
    wd3 = 32'hA5A5A5A5;
    we3 = 1'b1;
    @(posedge clk); #1;
    we3 = 1'b0;

    set_reads(5'd7, 5'd7);
    assert(rd1 == 32'hA5A5A5A5 && rd2 == 32'hA5A5A5A5)
        else $fatal("FAIL: read-after-write wrong");

    $display("All regfile tests passed. TB FINISH %0t", $time);
    $finish;
    end

endmodule // stimulus