`timescale 1ns / 1ps
`include "../cpu.v"
module simple_cpu_tb;

  reg clk;
  reg reset;
  wire [31:0] fetchedInstruction;
  wire [31:0] rd1, rd2;
  wire [31:0] writeData;
  reg  [4:0]  rs, rt, rd;
  reg  [31:0] immediate;
  reg         WE3;
  reg  [4:0]  A3;

  wire [31:0] aluResult;
  wire        zero, overflow;
  reg  [3:0]  aluCtrl;
  reg         aluSrc;

  reg [31:0] pc;

  // Instantiate instruction memory
  InstructionMemory imem (
    .PC(pc),
    .RD(fetchedInstruction)
  );

  // Instantiate register file
  wire [31:0] WD3;
  reg[31:0] tempWD3;
  regsFile rf (
    .A1(rs),
    .A2(rt),
    .WE3(WE3),
    .A3(A3),
    .WD3(WD3),
    .RD1(rd1),
    .RD2(rd2)
  );

  // Instantiate ALU
  wire [31:0] srcB;
  assign srcB = (aluSrc) ? immediate : rd2;

  alu mainALU (
    .ALUSrc(aluSrc),
    .SrcA(rd1),
    .RD2(rd2),
    .SignImm(immediate),
    .aluCtrl(aluCtrl),
    .ALUResult(aluResult),
    .Zero(zero),
    .overflow(overflow)
  );

  assign WD3 = aluResult;

  // Simulate memory (for LW, SW)
  reg [31:0] dataMem [0:255];

  initial begin
    $display("=== CPU TB SIMULATION START ===");

    clk = 0;
    reset = 1;
    pc = 0;
    WE3 = 0;
    aluSrc = 1;

    #5 reset = 0;
    #5 reset = 1;

    repeat (8) begin
      #1;
      instructionFetchDecodeExecute(fetchedInstruction);
      pc = pc + 4;
      #5;
    end

    $display("\n=== Final Register File Snapshot ===");
    $display("$t0 = %0d", rf.regMem[8]);
    $display("$t1 = %0d", rf.regMem[9]);
    $display("$t2 = %0d", rf.regMem[10]);
    $display("$t3 = %0d", rf.regMem[11]);
    $display("$t4 = %0d", rf.regMem[12]);
    $display("$t5 = %0d", rf.regMem[13]);
    $display("$t6 = %0d", rf.regMem[14]);
    $display("dataMem[0] = %0d", dataMem[0]);

    $display("=== SIMULATION END ===");
    $finish;
  end

  task instructionFetchDecodeExecute;
    input [31:0] instr;
    reg [5:0] opcode;
    reg [4:0] shamt;
    reg [5:0] funct;
    reg [31:0] memAddr;
    begin
      opcode = instr[31:26];
      rs = instr[25:21];
      rt = instr[20:16];
      rd = instr[15:11];
      immediate = {{16{instr[15]}}, instr[15:0]};
      shamt = instr[10:6];
      funct = instr[5:0];

      case (opcode)
        6'b001000: begin // ADDI
          aluCtrl = 4'b0010;
          aluSrc = 1;
          A3 = rt;
          WE3 = 1;
          #1;
          $display("Executed ADDI: $%0d = $%0d + %0d => %0d", rt, rs, immediate, aluResult);
          WE3 = 0;
        end
        6'b000000: begin // R-type
          case (funct)
            6'b100000: begin // ADD
              aluCtrl = 4'b0010;
              aluSrc = 0;
              A3 = rd;
              WE3 = 1;
              #1;
              $display("Executed ADD: $%0d = $%0d + $%0d => %0d", rd, rs, rt, aluResult);
              WE3 = 0;
            end
            6'b100010: begin // SUB
              aluCtrl = 4'b0110;
              aluSrc = 0;
              A3 = rd;
              WE3 = 1;
              #1;
              $display("Executed SUB: $%0d = $%0d - $%0d => %0d", rd, rs, rt, aluResult);
              WE3 = 0;
            end
            default: $display("Unsupported R-type funct = 0x%02X", funct);
          endcase
        end
        6'b101011: begin // SW
          aluCtrl = 4'b0010;
          aluSrc = 1;
          memAddr = rd1 + immediate;
          dataMem[memAddr[9:2]] = rd2;
          $display("Executed SW: mem[%0d] = %0d", memAddr, rd2);
        end
		6'b100011: begin // LW
		  aluCtrl = 4'b0010;
		  aluSrc = 1;
		  memAddr = rd1 + immediate;
		  tempWD3 = dataMem[memAddr[9:2]]; // Simulasi hasil baca memory
		  //isMemData = 1;
		  A3 = rt;
		  WE3 = 1;
		  #1;
		  $display("Executed LW: $%0d = mem[%0d] => %0d", rt, memAddr, WD3);
		  WE3 = 0;
		end
        default: $display("Unsupported opcode = 0x%02X", opcode);
      endcase
    end
  endtask

endmodule
