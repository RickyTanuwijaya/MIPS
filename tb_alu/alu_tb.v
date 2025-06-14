`timescale 1ns/1ps
module tb_alu;

  reg         ALUSrc;        // 1 → operand kedua diambil dari SignImm; 0 → dari RD2
  reg  [31:0] SrcA;          // Operand A (register pertama)
  reg  [31:0] RD2;           // Operand B (register kedua), kecuali untuk shift
  reg  [31:0] SignImm;       // Immediate yang sudah sign‐extend (untuk ADDI)
  reg  [4:0]  sa;            // Shift‐amount (5 bit) untuk SLL/SRL
  reg  [3:0]  ALUControl;    // Kode kontrol ALU dari Control Unit

  wire [31:0] ALUResult;     // Hasil keluaran ALU
  wire        Zero;          // Flag Zero = 1 jika result == 0
  wire        overflow;      // Flag Overflow untuk signed ADD/SUB


  alu uut (
    .ALUSrc     (ALUSrc),
    .SrcA       (SrcA),
    .RD2        (RD2),
    .SignImm    (SignImm),
    .sa      (sa),
    .ALUControl (ALUControl),
    .ALUResult  (ALUResult),
    .Zero       (Zero),
    .overflow   (overflow)
  );

  // --------------------------------------------------------------------------
  // 2) Test‐vector storage (total 14 vektor: 0..13)
  // --------------------------------------------------------------------------
  integer i;
  reg [31:0] tv_a        [0:13];
  reg [31:0] tv_b        [0:13];
  reg  [4:0] tv_sa    [0:13];
  reg  [3:0] tv_ctrl     [0:13];
  reg        tv_src      [0:13];
  reg [31:0] tv_exp_res  [0:13];
  reg        tv_exp_zero [0:13];
  reg        tv_exp_ovf  [0:13]; // Ekspektasi overflow

  initial begin
    $dumpfile("alu_overflow.vcd");
    $dumpvars(0, tb_alu);
  end

  // --------------------------------------------------------------------------
  // 3) Inisialisasi test‐vector (0..13)
  // --------------------------------------------------------------------------
  initial begin
    //  0: ADD  (ALUControl=0000)
    tv_a[0]        = 32'd10;
    tv_b[0]        = 32'd20;
    tv_sa[0]        = 5'd0;
    tv_src[0]      = 1'b0;      // operand kedua dari RD2
    tv_ctrl[0]     = 4'b0000;   // ADD
    tv_exp_res[0]  = 32'd30;
    tv_exp_zero[0] = 1'b0;
    tv_exp_ovf[0]  = 1'b0;      // tidak overflow

    //  1: ADDU (ALUControl=0001) – unsigned wrap
    tv_a[1]        = 32'hFFFF_FFFF;
    tv_b[1]        = 32'd1;
    tv_sa[1]    = 5'd0;
    tv_src[1]      = 1'b0;
    tv_ctrl[1]     = 4'b0001;   // ADDU
    tv_exp_res[1]  = 32'd0;     // wrap‐around
    tv_exp_zero[1] = 1'b1;      // sum=0
    tv_exp_ovf[1]  = 1'b0;      // ADDU tidak trap overflow

    //  2: SUB (ALUControl=0010)
    tv_a[2]        = 32'd20;
    tv_b[2]        = 32'd5;
    tv_sa[2]    = 5'd0;
    tv_src[2]      = 1'b0;
    tv_ctrl[2]     = 4'b0010;   // SUB
    tv_exp_res[2]  = 32'd15;
    tv_exp_zero[2] = 1'b0;
    tv_exp_ovf[2]  = 1'b0;      // 20-5 tidak overflow

    //  3: SUBU (ALUControl=0011) – unsigned wrap
    tv_a[3]        = 32'd5;
    tv_b[3]        = 32'd20;
    tv_sa[3]    = 5'd0;
    tv_src[3]      = 1'b0;
    tv_ctrl[3]     = 4'b0011;   // SUBU
    tv_exp_res[3]  = 32'hFFFF_FFF1;
    tv_exp_zero[3] = 1'b0;
    tv_exp_ovf[3]  = 1'b0;      // SUBU tidak trap overflow

    //  4: AND (ALUControl=0100)
    tv_a[4]        = 32'hF0F0_F0F0;
    tv_b[4]        = 32'h0FF0_0FF0;
    tv_sa[4]    = 5'd0;
    tv_src[4]      = 1'b0;
    tv_ctrl[4]     = 4'b0100;   // AND
    tv_exp_res[4]  = 32'h00F0_00F0;
    tv_exp_zero[4] = 1'b0;
    tv_exp_ovf[4]  = 1'b0;      // AND tidak menghasilkan overflow

    //  5: OR (ALUControl=0101)
    tv_a[5]        = 32'hF0F0_F0F0;
    tv_b[5]        = 32'h0FF0_0FF0;
    tv_sa[5]    = 5'd0;
    tv_src[5]      = 1'b0;
    tv_ctrl[5]     = 4'b0101;   // OR
    tv_exp_res[5]  = 32'hFFF0_FFF0;
    tv_exp_zero[5] = 1'b0;
    tv_exp_ovf[5]  = 1'b0;      // OR tidak menghasilkan overflow

    //  6: SLL (ALUControl=0110), shift register RT=tv_b[6] by sa=4
    tv_a[6]        = 32'd0;      // SrcA tidak dipakai untuk shift
    tv_b[6]        = 32'd1;      // data yang di‐shift
    tv_sa[6]    = 5'd4;       // geser 4 bit
    tv_src[6]      = 1'b0;       // operand kedua tetap RD2
    tv_ctrl[6]     = 4'b0110;    // SLL
    tv_exp_res[6]  = 32'd16;     // 1 << 4 = 16
    tv_exp_zero[6] = 1'b0;
    tv_exp_ovf[6]  = 1'b0;      // shift tidak menghasilkan overflow

    //  7: SRL (ALUControl=0111), shift register RT=tv_b[7] by sa=31
    tv_a[7]        = 32'd0;      
    tv_b[7]        = 32'h8000_0000; 
    tv_sa[7]    = 5'd31;       
    tv_src[7]      = 1'b0;
    tv_ctrl[7]     = 4'b0111;     // SRL
    tv_exp_res[7]  = 32'h0000_0001; 
    tv_exp_zero[7] = 1'b0;
    tv_exp_ovf[7]  = 1'b0;      // shift tidak menghasilkan overflow

    //  8: SLT (ALUControl=1000), signed compare (3 < 5 → 1)
    tv_a[8]        = 32'd3;
    tv_b[8]        = 32'd5;
    tv_sa[8]    = 5'd0;
    tv_src[8]      = 1'b0;
    tv_ctrl[8]     = 4'b1000;    // SLT
    tv_exp_res[8]  = 32'd1;
    tv_exp_zero[8] = 1'b0;
    tv_exp_ovf[8]  = 1'b0;      // compare tidak menghasilkan overflow

    //  9: BEQ (ALUControl=1001), cek Zero: 7 == 7 → Zero=1
    tv_a[9]        = 32'd7;
    tv_b[9]        = 32'd7;
    tv_sa[9]    = 5'd0;
    tv_src[9]      = 1'b0;
    tv_ctrl[9]     = 4'b1001;    // BEQ
    tv_exp_res[9]  = 32'd0;      // ALUResult = 7-7 = 0
    tv_exp_zero[9] = 1'b1;      // Zero=1
    tv_exp_ovf[9]  = 1'b0;      // SUB hasil 0 tidak overflow

    // 10: BNE (ALUControl=1010), cek Zero: 7 != 8 → Zero=0
    tv_a[10]       = 32'd7;
    tv_b[10]       = 32'd8;
    tv_sa[10]   = 5'd0;
    tv_src[10]     = 1'b0;
    tv_ctrl[10]    = 4'b1010;    // BNE
    tv_exp_res[10] = 32'hFFFF_FFFF; // ALUResult = 7-8 = -1
    tv_exp_zero[10]= 1'b0;      // Zero=0
    tv_exp_ovf[10] = 1'b0;      // SUB -1 tidak overflow

    // 11: ADDI (ALUControl=0000 dengan ALUSrc=1)
    tv_a[11]       = 32'd10;
    tv_b[11]       = 32'd5;      // SignImm = 5
    tv_sa[11]   = 5'd0;
    tv_src[11]     = 1'b1;       // operand kedua = SignImm
    tv_ctrl[11]    = 4'b0000;    // ADDI (di‐decode sebagai ADD)
    tv_exp_res[11] = 32'd15;     // 10 + 5 = 15
    tv_exp_zero[11]= 1'b0;
    tv_exp_ovf[11] = 1'b0;      // 15 tidak overflow

    // ----------------------
    // 12: Signed ADD Overflow
    //     0x7FFF_FFFF + 1 → 0x8000_0000, overflow=1
    // ----------------------
    tv_a[12]       = 32'h7FFF_FFFF; // MAX_POS = +2147483647
    tv_b[12]       = 32'd1;         // tambahkan 1
    tv_sa[12]   = 5'd0;
    tv_src[12]     = 1'b0;          
    tv_ctrl[12]    = 4'b0000;       // ADD
    tv_exp_res[12] = 32'h8000_0000;  // hasil wrap (signed = -2147483648)
    tv_exp_zero[12]= 1'b0;          // hasil ≠ 0
    tv_exp_ovf[12] = 1'b1;          // pasti overflow

    // ----------------------
    // 13: Signed SUB Overflow
    //     0x8000_0000 - 1 → 0x7FFF_FFFF, overflow=1
    // ----------------------
    tv_a[13]       = 32'h8000_0000; // MIN_NEG = -2147483648 (signed)
    tv_b[13]       = 32'd1;         // kurangi 1
    tv_sa[13]   = 5'd0;
    tv_src[13]     = 1'b0;
    tv_ctrl[13]    = 4'b0010;       // SUB
    tv_exp_res[13] = 32'h7FFF_FFFF;  // hasil = +2147483647
    tv_exp_zero[13]= 1'b0;          // hasil ≠ 0
    tv_exp_ovf[13] = 1'b1;          // pasti overflow
  end

  // --------------------------------------------------------------------------
  // 4) Eksekusi test‐bench: loop melalui semua vektor (0..13)
  //    Memeriksa ALUResult, Zero, dan overflow
  // --------------------------------------------------------------------------
  initial begin
    $display("=== Mulai ===");
    for (i = 0; i < 14; i = i + 1) begin
      // ----- drive input -----
      ALUSrc     = tv_src[i];
      SrcA       = tv_a[i];
      sa      = tv_sa[i];
      if (tv_src[i] == 1'b0) begin
        RD2       = tv_b[i];
        SignImm   = 32'bx;   // x karena tidak dipakai
      end else begin
        RD2       = 32'bx;   // x karena tidak dipakai
        SignImm   = tv_b[i];
      end
      ALUControl = tv_ctrl[i];

      #1; // tunggu 1 ns agar sinyal kombinasi stabil

      // ----- cek hasil -----
      // Untuk BEQ (1001) & BNE (1010), fokus pada Zero
      if (tv_ctrl[i] == 4'b1001 || tv_ctrl[i] == 4'b1010) begin
        if (Zero !== tv_exp_zero[i]) begin
          $display("GAGAL #%0d: Instr BEQ/BNE, A=%0d B=%0d → Zero=%b, diharapkan=%b",
                   i, tv_a[i], tv_b[i], Zero, tv_exp_zero[i]);
        end else begin
          $display("SUKSES #%0d: Instr BEQ/BNE, Zero=%b", i, Zero);
        end
      end
      else begin
        // Instr lain: cek ALUResult
        if (ALUResult !== tv_exp_res[i]) begin
          $display("GAGAL #%0d: ALUControl=%b, SrcA=%h, SrcB/Imm=%h → ALUResult=%h, diharapkan=%h",
                   i, ALUControl, tv_a[i], tv_b[i], ALUResult, tv_exp_res[i]);
        end
        else if (Zero !== tv_exp_zero[i]) begin
          $display("GAGAL #%0d: ALUControl=%b, Zero=%b, diharapkan=%b",
                   i, ALUControl, Zero, tv_exp_zero[i]);
        end
        else if (overflow !== tv_exp_ovf[i]) begin
          $display("GAGAL #%0d: ALUControl=%b, Overflow=%b, diharapkan=%b",
                   i, ALUControl, overflow, tv_exp_ovf[i]);
        end
        else begin
          $display("SUKSES #%0d: ALUControl=%b, ALUResult=%h, Zero=%b, Overflow=%b",
                   i, ALUControl, ALUResult, Zero, overflow);
        end
      end
    end

    $display("=== Selesai ===");
    $finish;
  end
endmodule

