// riscvsingle.sv

// RISC-V single-cycle processor
// From Section 7.6 of Digital Design & Computer Architecture
// 27 April 2020
// David_Harris@hmc.edu 
// Sarah.Harris@unlv.edu

// run 210
// Expect simulator to print "Simulation succeeded"
// when the value 25 (0x19) is written to address 100 (0x64)

//   Instruction  opcode    funct3    funct7
//   add          0110011   000       0000000
//   sub          0110011   000       0100000
//   and          0110011   111       0000000
//   or           0110011   110       0000000
//   slt          0110011   010       0000000
//   addi         0010011   000       immediate
//   andi         0010011   111       immediate
//   ori          0010011   110       immediate
//   slti         0010011   010       immediate
//   beq          1100011   000       immediate
//   lw	          0000011   010       immediate
//   sw           0100011   010       immediate
//   jal          1101111   immediate immediate

module riscvsingle(
    input  logic        clk,
    input  logic        reset,
    input  logic        PReady,
    output logic [31:0] PC,
    input  logic [31:0] Instr,
    output logic        MemWrite,
    output logic        MemStrobe,
    output logic [31:0] ALUResult,
    output logic [31:0] WriteData,
    input  logic [31:0] ReadData
);

   logic        ALUSrc, RegWrite, Jump, Zero, lt, ltu, ASrc, PCEnable;
   logic [1:0]  ResultSrc;
   logic [2:0]  ImmSrc;
   logic [3:0]  ALUControl;
   logic [1:0]  PCSel;

   controller c(
      Instr[6:0], Instr[14:12], Instr[30], Zero, lt, ltu,
      ResultSrc, MemWrite, MemStrobe, ALUSrc, ASrc, RegWrite, Jump,
      ImmSrc, ALUControl, PCSel
   );

   assign PCEnable = ~MemStrobe | PReady;

   datapath dp(
      clk, reset, PCEnable, ResultSrc, PCSel,
      ALUSrc, ASrc, RegWrite,
      ImmSrc, Instr[14:12], ALUControl,
      Zero, PC, Instr,
      ALUResult, WriteData, ReadData, lt, ltu
   );

endmodule

module controller(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic       Zero,
    input  logic       lt,
    input  logic       ltu,
    output logic [1:0] ResultSrc,
    output logic       MemWrite,
    output logic       MemStrobe,
    output logic       ALUSrc,
    output logic       ASrc,
    output logic       RegWrite,
    output logic       Jump,
    output logic [2:0] ImmSrc,
    output logic [3:0] ALUControl,
    output logic [1:0] PCSel
);

   logic [1:0] ALUOp;
   logic       Branch;

   maindec md(
      op, ResultSrc, MemWrite, MemStrobe, Branch,
      ALUSrc, ASrc, RegWrite, Jump, ImmSrc, ALUOp
   );

   aludec ad(
      op[5], funct3, funct7b5, ALUOp, ALUControl
   );

   bu branch_unit(
      Branch, Jump, op, funct3, Zero, lt, ltu, PCSel
   );

endmodule

module bu(
    input  logic       Branch,
    input  logic       Jump,
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       Zero,
    input  logic       lt,
    input  logic       ltu,
    output logic [1:0] PCSel
);

   always_comb begin
      if (Jump && op == 7'b1100111)
         PCSel = 2'b10;
      else if ((Branch & ~funct3[2] & (Zero ^ funct3[0])) |
               (Branch &  funct3[2] & ~funct3[1] & (lt  ^ funct3[0])) |
               (Branch &  funct3[2] &  funct3[1] & (ltu ^ funct3[0])) |
               Jump)
         PCSel = 2'b01;
      else
         PCSel = 2'b00;
   end

endmodule

module maindec(
    input  logic [6:0] op,
    output logic [1:0] ResultSrc,
    output logic       MemWrite,
    output logic       MemStrobe,
    output logic       Branch,
    output logic       ALUSrc,
    output logic       ASrc,
    output logic       RegWrite,
    output logic       Jump,
    output logic [2:0] ImmSrc,
    output logic [1:0] ALUOp
);

   logic [12:0] controls;

   assign {RegWrite, ImmSrc, ASrc, ALUSrc, MemWrite,
           ResultSrc, Branch, ALUOp, Jump} = controls;

   always_comb begin
      MemStrobe = 1'b0;
      case(op)
         7'b0000011: begin controls = 13'b1_000_0_1_0_01_0_00_0; MemStrobe = 1'b1; end
         7'b0010011:       controls = 13'b1_000_0_1_0_00_0_10_0;
         7'b0010111:       controls = 13'b1_100_1_1_0_00_0_00_0;
         7'b0100011: begin controls = 13'b0_001_0_1_1_00_0_00_0; MemStrobe = 1'b1; end
         7'b0110011:       controls = 13'b1_xxx_0_0_0_00_0_10_0;
         7'b0110111:       controls = 13'b1_100_0_1_0_00_0_11_0;
         7'b1100011:       controls = 13'b0_010_0_0_0_00_1_01_0;
         7'b1101111:       controls = 13'b1_011_0_0_0_10_0_00_1;
         7'b1100111:       controls = 13'b1_000_0_1_0_10_0_00_1;
         7'b1110011:       controls = 13'b0_000_0_0_0_00_0_00_0;
         default:          controls = 13'b0_000_0_0_0_00_0_00_0;
      endcase
   end

endmodule

module aludec(
    input  logic       opb5,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic [1:0] ALUOp,
    output logic [3:0] ALUControl
);

   logic RtypeSub;

   assign RtypeSub = funct7b5 & opb5;

   always_comb begin
      case(ALUOp)
         2'b00: ALUControl = 4'b0000;
         2'b01: ALUControl = 4'b0001;
         2'b11: ALUControl = 4'b1010;
         default: begin
            case(funct3)
               3'b000: ALUControl = RtypeSub ? 4'b0001 : 4'b0000;
               3'b001: ALUControl = 4'b0110;
               3'b010: ALUControl = 4'b0101;
               3'b011: ALUControl = 4'b1001;
               3'b100: ALUControl = 4'b0100;
               3'b101: ALUControl = funct7b5 ? 4'b1000 : 4'b0111;
               3'b110: ALUControl = 4'b0011;
               3'b111: ALUControl = 4'b0010;
               default: ALUControl = 4'b0000;
            endcase
         end
      endcase
   end

endmodule

module datapath(
    input  logic        clk,
    input  logic        reset,
    input  logic        PCEnable,
    input  logic [1:0]  ResultSrc,
    input  logic [1:0]  PCSel,
    input  logic        ALUSrc,
    input  logic        ASrc,
    input  logic        RegWrite,
    input  logic [2:0]  ImmSrc,
    input  logic [2:0]  funct3,
    input  logic [3:0]  ALUControl,
    output logic        Zero,
    output logic [31:0] PC,
    input  logic [31:0] Instr,
    output logic [31:0] ALUResult,
    output logic [31:0] WriteData,
    input  logic [31:0] ReadData,
    output logic        lt,
    output logic        ltu
);

   logic [31:0] PCNext, PCPlus4, PCTarget;
   logic [31:0] ImmExt;
   logic [31:0] SrcA, SrcB;
   logic [31:0] Result;
   logic [31:0] SrcAReg;
   logic [31:0] WriteDataRaw;
   logic [31:0] JalrTargetRaw, JalrTarget;
   logic [31:0] LoadData, StoreDataWord;

   flopenr #(32) pcreg(clk, reset, PCEnable, PCNext, PC);
   adder pcadd4(PC, 32'd4, PCPlus4);
   adder pcaddbranch(PC, ImmExt, PCTarget);
   adder jalradd(SrcAReg, ImmExt, JalrTargetRaw);

   assign JalrTarget = {JalrTargetRaw[31:1], 1'b0};

   mux3 #(32) pcmux(PCPlus4, PCTarget, JalrTarget, PCSel, PCNext);

   regfile rf(
      clk, RegWrite,
      Instr[19:15], Instr[24:20], Instr[11:7],
      Result, SrcAReg, WriteDataRaw
   );

   extend ext(Instr[31:7], ImmSrc, ImmExt);

   mux2 #(32) srcamux(SrcAReg, PC, ASrc, SrcA);
   mux2 #(32) srcbmux(WriteDataRaw, ImmExt, ALUSrc, SrcB);

   alu alu0(SrcA, SrcB, ALUControl, ALUResult, Zero, lt, ltu);

   lsu lsu0(
      funct3, ALUResult, ReadData, WriteDataRaw,
      LoadData, StoreDataWord
   );

   wdunit wd0(
      ResultSrc, ALUResult, LoadData, PCPlus4, Result
   );

   assign WriteData = StoreDataWord;

endmodule

module lsu(
    input  logic [2:0]  funct3,
    input  logic [31:0] Addr,
    input  logic [31:0] ReadData,
    input  logic [31:0] WriteDataRaw,
    output logic [31:0] LoadData,
    output logic [31:0] StoreDataWord
);

   logic [7:0]  LoadByte;
   logic [15:0] LoadHalf;
   logic [31:0] LB_ext, LH_ext, LBU_ext, LHU_ext;

   assign LoadByte = ReadData[8*Addr[1:0] +: 8];
   assign LoadHalf = ReadData[16*Addr[1] +: 16];

   signext #(8)  sx_b(LoadByte, LB_ext);
   signext #(16) sx_h(LoadHalf, LH_ext);
   zeroext #(8)  zx_b(LoadByte, LBU_ext);
   zeroext #(16) zx_h(LoadHalf, LHU_ext);

   always_comb begin
      case (funct3)
         3'b000: LoadData = LB_ext;
         3'b001: LoadData = LH_ext;
         3'b010: LoadData = ReadData;
         3'b100: LoadData = LBU_ext;
         3'b101: LoadData = LHU_ext;
         default: LoadData = ReadData;
      endcase
   end

   always_comb begin
      case (funct3)
         3'b000: begin
            StoreDataWord = 32'b0;
            StoreDataWord[8*Addr[1:0] +: 8] = WriteDataRaw[7:0];
         end
         3'b001: begin
            StoreDataWord = 32'b0;
            StoreDataWord[16*Addr[1] +: 16] = WriteDataRaw[15:0];
         end
         3'b010: StoreDataWord = WriteDataRaw;
         default: StoreDataWord = WriteDataRaw;
      endcase
   end

endmodule

module wdunit(
    input  logic [1:0]  ResultSrc,
    input  logic [31:0] ALUResult,
    input  logic [31:0] LoadData,
    input  logic [31:0] PCPlus4,
    output logic [31:0] Result
);

   mux3 #(32) resultmux(ALUResult, LoadData, PCPlus4, ResultSrc, Result);

endmodule

module extend(
    input  logic [31:7] instr,
    input  logic [2:0]  immsrc,
    output logic [31:0] immext
);

   always_comb begin
      case(immsrc)
         3'b000: immext = {{20{instr[31]}}, instr[31:20]};
         3'b001: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
         3'b010: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
         3'b011: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
         3'b100: immext = {instr[31:12], 12'b0};
         default: immext = 32'b0;
      endcase
   end

endmodule

module signext #(parameter WIDTH = 8)(
    input  logic [WIDTH-1:0] in,
    output logic [31:0] out
);
   assign out = {{(32-WIDTH){in[WIDTH-1]}}, in};
endmodule

module zeroext #(parameter WIDTH = 8)(
    input  logic [WIDTH-1:0] in,
    output logic [31:0] out
);
   assign out = {{(32-WIDTH){1'b0}}, in};
endmodule

module alu(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alucontrol,
    output logic [31:0] result,
    output logic        zero,
    output logic        lt,
    output logic        ltu
);

   logic [31:0] sum;
   logic [32:0] fullsum;
   logic        cout;
   logic        v;
   logic        isAddSub;
   logic [31:0] condinvb;

   assign condinvb = alucontrol[0] ? ~b : b;
   assign fullsum  = {1'b0, a} + {1'b0, condinvb} + alucontrol[0];
   assign sum      = fullsum[31:0];
   assign cout     = fullsum[32];
   assign ltu      = ~cout;
   assign isAddSub = (~alucontrol[2] & ~alucontrol[1]) |
                     (~alucontrol[1] &  alucontrol[0]);

   always_comb begin
      case (alucontrol)
         4'b0000: result = sum;
         4'b0001: result = sum;
         4'b0010: result = a & b;
         4'b0011: result = a | b;
         4'b0100: result = a ^ b;
         4'b0101: result = {31'b0, (sum[31] ^ v)};
         4'b0110: result = a << b[4:0];
         4'b0111: result = a >> b[4:0];
         4'b1000: result = $signed(a) >>> b[4:0];
         4'b1001: result = {31'b0, ltu};
         4'b1010: result = b;
         default: result = 32'b0;
      endcase
   end

   assign zero = (result == 32'b0);
   assign v    = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
   assign lt   = sum[31] ^ v;

endmodule

module regfile(
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1,
    input  logic [4:0]  a2,
    input  logic [4:0]  a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);

   logic [31:0] rf[31:0];

   always_ff @(posedge clk)
      if (we3) rf[a3] <= wd3;

   assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
   assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;

endmodule

module adder(
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
   assign y = a + b;
endmodule

module flopr #(parameter WIDTH = 8)(
    input  logic             clk,
    input  logic             reset,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

   always_ff @(posedge clk, posedge reset)
      if (reset) q <= '0;
      else       q <= d;

endmodule

module flopenr #(parameter WIDTH = 8)(
    input  logic             clk,
    input  logic             reset,
    input  logic             en,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

   always_ff @(posedge clk, posedge reset)
      if (reset)      q <= '0;
      else if (en)    q <= d;

endmodule

module mux2 #(parameter WIDTH = 8)(
    input  logic [WIDTH-1:0] d0,
    input  logic [WIDTH-1:0] d1,
    input  logic             s,
    output logic [WIDTH-1:0] y
);
   assign y = s ? d1 : d0;
endmodule

module mux3 #(parameter WIDTH = 8)(
    input  logic [WIDTH-1:0] d0,
    input  logic [WIDTH-1:0] d1,
    input  logic [WIDTH-1:0] d2,
    input  logic [1:0]       s,
    output logic [WIDTH-1:0] y
);
   assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule