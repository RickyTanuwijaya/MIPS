module control(
    input  wire [5:0] Opcode,    // 6-bit Opcode dari instruksi MIPS
    input  wire [5:0] funct,        // 6-bit FUNCT (hanya relevan jika Opcode==000000)

    output reg        RegDst,    // 1 = tulis ke rd (R‐type), 0 = tulis ke rt (I‐type)
    output reg        Jump,       // 1 = instruksi J (jump), 0 = bukan jump
    output reg        Branch,    // 1 = instruksi Branch (BEQ/BNE), 0 = bukan Branch
    output reg        MemRead,   // 1 = baca data dari Data Memory (LW), 0 = tidak
    output reg        MemtoReg,  // 1 = data memory → register (LW), 0 = ALU → register
    output reg [1:0]  ALUOp,     // Kode “utama” untuk ALU (Main ALUOp)
    output reg        MemWrite,  // 1 = tulis data ke Data Memory (SW), 0 = tidak
    output reg        ALUSrc,    // 1 = operand ALU kedua dari immediate, 0 = dari register kedua
    output reg        RegWrite,  // 1 = tulis hasil ke register, 0 = tidak
    output reg [3:0]  ALUControl    // Kode kontrol final untuk ALU (hasil ALU Decode)
);

//=================================================
// 1) Parameter/Makro untuk Opcode MIPS dasar
//=================================================
parameter ADD   = 6'b000000;  // R‐type, funct=100000
parameter ADDU  = 6'b000000;  // R‐type, funct=100001
parameter SUB   = 6'b000000;  // R‐type, funct=100010
parameter SUBU  = 6'b000000;  // R‐type, funct=100011
parameter AND   = 6'b000000;  // R‐type, funct=100100
parameter OR    = 6'b000000;  // R‐type, funct=100101
parameter SLL   = 6'b000000;  // R‐type, funct=000000
parameter SRL   = 6'b000000;  // R‐type, funct=000010
parameter SLT   = 6'b000000;  // R‐type, funct=101010

parameter ADDI  = 6'b001000;  // I‐type add immediate
parameter LW    = 6'b100011;  // I‐type load word
parameter SW    = 6'b101011;  // I‐type store word
parameter BEQ   = 6'b000100;  // I‐type Branch if equal
parameter BNE   = 6'b000101;  // I‐type Branch if not equal
parameter J     = 6'b000010;  // J‐type jump

//=================================================
// 2) Parameter/Makro untuk “funct” field R‐type
//=================================================
parameter ADDFN  = 6'b100000;  // funct untuk ADD
parameter ADDUFN = 6'b100001;  // funct untuk ADDU
parameter SUBFN  = 6'b100010;  // funct untuk SUB
parameter SUBUFN = 6'b100011;  // funct untuk SUBU
parameter ANDFN  = 6'b100100;  // funct untuk AND
parameter ORFN   = 6'b100101;  // funct untuk OR
parameter SLLFN  = 6'b000000;  // funct untuk SLL
parameter SRLFN  = 6'b000010;  // funct untuk SRL
parameter SLTFN  = 6'b101010;  // funct untuk SLT

//=================================================
// 3) Internal: Kode menengah (fno) hasil decode funct
//    fno akan dipakai di blok ALU Decode
//    (4-bit “fungsi ALU”)
//=================================================
reg [3:0] fno;  

/* 
   Kategori ALUOp (2-bit) dalam modul ini:
   – 2’b10 = R‐type (gunakan fno dari “funct” untuk ALUControl)
   – 2’b01 = I‐type (ADDI, LW, SW → operasi ADD)
   – 2’b00 = BEQ   (operasi SUB + cek zero)
   – 2’b11 = BNE   (operasi SUB + cek bukan zero)

   Keluaran “ALUControl” (4-bit) maksimal:
     4'b0000 = ADD
     4'b0001 = ADDU
     4'b0010 = SUB
     4'b0011 = SUBU
     4'b0100 = AND
 4'b0101 = OR
     4'b0110 = SLL
     4'b0111 = SRL
     4'b1000 = SLT
     4'b1001 = BEQ  (hasil 1 jika A==B, else 0)
     4'b1010 = BNE  (hasil 1 jika A≠B, else 0)
*/

//=================================================
// 4) MAIN DECODE: selalu dijalankan saat “Opcode” berubah
//    Menghasilkan RegDst, ALUSrc, ALUOp, Branch, MemRead, MemWrite, Jump, MemtoReg, RegWrite
//=================================================
always @ (Opcode) begin
    // Default (jika Opcode tidak dikenali):
    // – Semua sinyal kontrol = 0, RegDst = 0 (artinya tidak akan menulis ke register)
    RegDst   = 1'b0;
    ALUSrc   = 1'b0;
    ALUOp    = 2'b00;
    Jump      = 1'b0;
    Branch   = 1'b0;
    MemRead  = 1'b0;
    MemtoReg = 1'b0;
    MemWrite = 1'b0;
    RegWrite = 1'b0;

    case (Opcode)
        //---------------------------------------------
        // R‐TYPE (Opcode=000000): ADD, ADDU, SUB, SUBU, AND, OR, SLL, SRL, SLT
        //---------------------------------------------
        ADD,
        ADDU,
        SUB,
        SUBU,
        AND,
        OR,
        SLL,
        SRL,
        SLT:
        begin
            // Tulis hasil ke register rd
            RegDst   = 1'b1;    // 1 = pilih rd sebagai tujuan (R-type)
            ALUSrc   = 1'b0;    // operand ALU kedua dari register (bukan immediate)
            ALUOp    = 2'b10;   // kode R‐type → nantinya di‐decode lewat “fno”
            Jump      = 1'b0;    
            Branch   = 1'b0;
            MemRead  = 1'b0;
            MemtoReg = 1'b0;
            MemWrite = 1'b0;
            RegWrite = 1'b1;    // harus tulis ke register
end

        //---------------------------------------------
        // ADDI (Opcode=001000): I‐type Add Immediate
        //---------------------------------------------
        ADDI:
        begin
            RegDst   = 1'b0;    // 0 = pilih rt sebagai tujuan (I-type)
            ALUSrc   = 1'b1;    // operand ALU kedua dari “immediate”
            ALUOp    = 2'b01;   // kode I‐type → operasi ADD
            Jump      = 1'b0;
            Branch   = 1'b0;
            MemRead  = 1'b0;
            MemtoReg = 1'b0;
            MemWrite = 1'b0;
            RegWrite = 1'b1;    // tulis ke register (rt)
        end

        //---------------------------------------------
        // LW (Opcode=100011): Load Word
        //---------------------------------------------
        LW:
        begin
            RegDst   = 1'b0;    // tulis ke rt
            ALUSrc   = 1'b1;    // operand kedua = immediate (offset)
            ALUOp    = 2'b01;   // ADD untuk menjumlah base+offset
            Jump      = 1'b0;
            Branch   = 1'b0;
            MemRead  = 1'b1;    // baca data memory
            MemtoReg = 1'b1;    // tulis data memory ke register
            MemWrite = 1'b0;
            RegWrite = 1'b1;
        end

        //---------------------------------------------
        // SW (Opcode=101011): Store Word
        //---------------------------------------------
        SW:
        begin
            RegDst   = 1'b0;    // “don’t care” karena tidak menulis register
            ALUSrc   = 1'b1;    // operand kedua = immediate (offset)
            ALUOp    = 2'b01;   // ADD untuk menghitung alamat base+offset
            Jump      = 1'b0;
            Branch   = 1'b0;
            MemRead  = 1'b0;
            MemtoReg = 1'b0;    // tidak digunakan
            MemWrite = 1'b1;    // tulis data ke memory
            RegWrite = 1'b0;    // tidak menulis register
        end

        //---------------------------------------------
        // BEQ (Opcode=000100): Branch if Equal
        //---------------------------------------------
        BEQ:
        begin
            RegDst   = 1'b0;    // “don’t care” (tidak menulis register)
            ALUSrc   = 1'b0;    // operand kedua dari register
            ALUOp    = 2'b00;   // SUB + cek zero (ALUOp=00 menurut skema ini)
            Jump      = 1'b0;
            Branch   = 1'b1;    // sinyal Branch diaktifkan
            MemRead  = 1'b0;
            MemtoReg = 1'b0;
            MemWrite = 1'b0;
            RegWrite = 1'b0;
        end

        //---------------------------------------------
        // BNE (Opcode=000101): Branch if Not Equal
        //---------------------------------------------
        BNE:
        begin
            RegDst   = 1'b0;
            ALUSrc   = 1'b0;
            ALUOp    = 2'b11;   // SUB + cek bukan zero (ALUOp=11 untuk BNE)
            Jump      = 1'b0;
            Branch   = 1'b1;
            MemRead  = 1'b0;
            MemtoReg = 1'b0;
            MemWrite = 1'b0;
            RegWrite = 1'b0;
        end

        //---------------------------------------------
        // J (Opcode=000010): Jump
        //---------------------------------------------
        J:
        begin
            RegDst   = 1'b0;    // “don’t care”
            ALUSrc   = 1'b0;    // tidak digunakan
            ALUOp    = 2'b00;   // default (ADD/SUB tidak digunakan)
            Jump      = 1'b1;    // sinyal jump diaktifkan
            Branch   = 1'b0;
            MemRead  = 1'b0;
            MemtoReg = 1'b0;
            MemWrite = 1'b0;
            RegWrite = 1'b0;
        end

        //---------------------------------------------
        // Default: Opcode yang tidak dikenali
 //---------------------------------------------
        default:
        begin
            RegDst   = 1'b0;
            ALUSrc   = 1'b0;
            ALUOp    = 2'b00;
            Jump      = 1'b0;
            Branch   = 1'b0;
            MemRead  = 1'b0;
            MemtoReg = 1'b0;
            MemWrite = 1'b0;
            RegWrite = 1'b0;
        end
    endcase
end

//=================================================
// 5) ALU DECODE: terjemahkan “funct” (funct) → kode fno (4-bit)
//    Selalu dijalankan saat “funct” berubah
//    Hasil fno akan dipakai oleh blok ALUOp/fno di bawah
//=================================================
always @ (funct) begin
    case (funct)
        ADDFN:   fno = 4'b0000;  // ADD
        ADDUFN:  fno = 4'b0001;  // ADDU
        SUBFN:   fno = 4'b0010;  // SUB
        SUBUFN:  fno = 4'b0011;  // SUBU
        ANDFN:   fno = 4'b0100;  // AND
        ORFN:    fno = 4'b0101;  // OR
        SLLFN:   fno = 4'b0110;  // SLL (logical shift left)
        SRLFN:   fno = 4'b0111;  // SRL (logical shift right)
        SLTFN:   fno = 4'b1000;  // SLT (set‐on‐less‐than)
        default: fno = 4'b0000;  // default → ADD (agar tidak latched)
    endcase
end

//=================================================
// 6) FINAL ALU CONTROL: tetapkan ALUControl berdasarkan ALUOp & fno
//    – Jika ALUOp=2’b10 (R‐type), pakai fno
//    – Jika ALUOp=2’b01 (I‐type), pakai ADD (0000)
//    – Jika ALUOp=2’b00 (BEQ), pakai cek sama (1001)
//    – Jika ALUOp=2’b11 (BNE), pakai cek tidak sama (1010)
//    Selalu dijalankan saat ALUOp atau fno berubah
//=================================================
always @ (ALUOp or fno) begin
    case (ALUOp)
        2'b10: ALUControl = fno;       // R‐type: langsung dari decoding funct
        2'b01: ALUControl = 4'b0000;   // I‐type (ADDI, LW, SW) → ADD
        2'b00: ALUControl = 4'b1001;   // BEQ  → set if equal (A==B)
        2'b11: ALUControl = 4'b1010;   // BNE  → set if not equal (A!=B)
 default: ALUControl = 4'b0000; // safe default (ADD)
    endcase
end

endmodule
