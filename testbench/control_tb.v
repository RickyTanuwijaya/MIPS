`include "../control.v"
`timescale 1ns/1ps

module tb_control;
  // -------------------------------
  // 1) Deklarasi Input (reg) dan Output (wire)
  // -------------------------------
  reg  [5:0] Opcode;   // 6-bit Opcode instruksi MIPS
  reg  [5:0] funct;       // 6-bit FUNCT (hanya relevan jika Opcode = 000000)

  wire       RegDst;    // 1 = tulis ke rd (R‐type), 0 = tulis ke rt (I‐type)
  wire       Jump;       // 1 = instruksi Jump
  wire       Branch;    // 1 = instruksi Branch (BEQ/BNE)
  wire       MemRead;   // 1 = baca dari Data Memory (LW)
  wire       MemtoReg;  // 1 = data memory → register (LW)
  wire [1:0] ALUOp;     // Kode “utama” untuk ALU (2-bit)
  wire       MemWrite;  // 1 = tulis ke Data Memory (SW)
  wire       ALUSrc;    // 1 = operand kedua dari immediate
  wire       RegWrite;  // 1 = tulis hasil ke register file
  wire [3:0] ALUControl;   // Kode kontrol final untuk ALU (4-bit)

  control uut (
    .Opcode   (Opcode),
    .RegDst   (RegDst),
    .Jump      (Jump),
    .Branch   (Branch),
    .MemRead  (MemRead),
    .MemtoReg (MemtoReg),
    .ALUOp    (ALUOp),
    .MemWrite (MemWrite),
    .ALUSrc   (ALUSrc),
    .RegWrite (RegWrite),
    .ALUControl  (ALUControl),
    .funct       (funct)
  );

  task printSignals;
    begin
      $display(
        "time=%0t | Opcode=%b funct=%b || RegWrite=%b RegDst=%b ALUSrc=%b Branch=%b MemWrite=%b MemtoReg=%b ALUOp=%b Jump=%b MemRead=%b ALUControl=%b",
         $time, Opcode, funct, RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, ALUOp, Jump, MemRead, ALUControl
      );
    end
  endtask

  // -------------------------------
  //    Blok initial: menerapkan vektor‐vektor uji secara berurutan
  //    dan mencetak hasilnya. Setiap `#10` memberi waktu 10 ns
  //    bagi `control.v` untuk menentukan sinyal kontrol.
  // -------------------------------
  initial begin
    $display("=== Mulai ===");

    // --------------------------------------------------
    // 4.1) R‐type instructions (Opcode = 000000), loop melalui beberapa funct
    // --------------------------------------------------
    Opcode = 6'b000000;

    // ADD   (funct = 100000)
    funct = 6'b100000;  #10; printSignals();
    // ADDU  (funct = 100001)
    funct = 6'b100001;  #10; printSignals();
    // SUB   (funct = 100010)
    funct = 6'b100010;  #10; printSignals();
    // SUBU  (funct = 100011)
    funct = 6'b100011;  #10; printSignals();
    // AND   (funct = 100100)
    funct = 6'b100100;  #10; printSignals();
    // OR    (funct = 100101)
    funct = 6'b100101;  #10; printSignals();
    // SLL   (funct = 000000)
    funct = 6'b000000;  #10; printSignals();
    // SRL   (funct = 000010)
    funct = 6'b000010;  #10; printSignals();
    // SLT   (funct = 101010)
    funct = 6'b101010;  #10; printSignals();

    // --------------------------------------------------
    
    // --------------------------------------------------
    // I‐type: LW (Opcode = 100011)
    // --------------------------------------------------
    Opcode = 6'b100011; 
    funct     = 6'bxxxxxx;
    #10; printSignals();

    // --------------------------------------------------
    // I‐type: SW (Opcode = 101011)
    // --------------------------------------------------
    Opcode = 6'b101011; 
    funct     = 6'bxxxxxx;
    #10; printSignals();

    // --------------------------------------------------
    // Branch: BEQ (Opcode = 000100)
    // --------------------------------------------------
    Opcode = 6'b000100; 
    funct     = 6'bxxxxxx;
    #10; printSignals();

    // I‐type: ADDI (Opcode = 001000)
    // --------------------------------------------------
    Opcode = 6'b001000; 
    funct     = 6'bxxxxxx;   // ‘funct’ tidak dipakai karena Opcode != 000000
    #10; printSignals();

    // --------------------------------------------------
    // Jump: J (Opcode = 000010)
    // --------------------------------------------------
    Opcode = 6'b000010; 
    funct     = 6'bxxxxxx;
    #10; printSignals();

    // --------------------------------------------------
    // Branch: BNE (Opcode = 000101)
    // --------------------------------------------------
    Opcode = 6'b000101; 
    funct     = 6'bxxxxxx;
    #10; printSignals();

    // --------------------------------------------------
    // Kasus Default: kode Opcode yang tidak valid (111111)
    // --------------------------------------------------
    Opcode = 6'b111111; 
    funct     = 6'bxxxxxx;
    #10; printSignals();

    $display("=== Selesai ===");
    $finish;
  end

endmodule

