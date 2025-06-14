`include "fullAdder.v"
`include "fullAddSub32.v"

module alu(
    input  wire        ALUSrc,       // 1: operand kedua = SignImm, 0: operand kedua = RD2
    input  wire [31:0] SrcA,         // nilai dari register pertama (A)
    input  wire [31:0] RD2,          // nilai dari register kedua (B), kecuali untuk shift
    input  wire [31:0] SignImm,      // immediate sign‐extend (untuk I‐type)
    input  wire [4:0]  sa,        // shift‐amount (bit 10:6 dari instruksi), hanya untuk SLL/SRL
    input  wire [3:0]  ALUControl,   // 4-bit kontrol ALU dari control unit

    output reg  [31:0] ALUResult,    // hasil operasi ALU
    output wire        Zero,         // 1 jika ALUResult == 0 (untuk BEQ/BNE)
    output wire        overflow      // overflow only for signed ADD/SUB
);

    wire [31:0] d2;      // operand kedua final ke adder/subtractor
    wire [31:0] sum;     // hasil fullAddSub32 (ADD/SUB)
    wire        carry;   // carry‐out penuh

    // Tentukan operand kedua: register atau immediate
    assign d2 = (ALUSrc == 1'b1) ? SignImm : RD2;

    // Circuit adder/subtractor 32‐bit
    // op = 1 untuk SUB/SUBU, op = 0 untuk ADD/ADDU
    wire op;
    assign op = (ALUControl == 4'b0010)  // SUB
             || (ALUControl == 4'b0011)  // SUBU
             || (ALUControl == 4'b1001)  // BEQ (pakai SUB)
             || (ALUControl == 4'b1010)  // BNE (pakai SUB)
             ? 1'b1 : 1'b0;

    fullAddSub32 addsub (
        .num1  (SrcA),
        .num2  (d2),
        .op    (op),
        .sumO  (sum),
        .carryO(carry)
    );

    // Zero flag = 1 jika hasil subtract/add == 0
    assign Zero = (sum == 32'b0) ? 1'b1 : 1'b0;

    //    Deteksi overflow signed
    //    – Untuk ADD (controller=0000): overflow_add
    //    – Untuk SUB (controller=0010): overflow_sub
    //    – Lainnya (ADDU, SUBU, AND, OR, SLL, SRL, SLT, BEQ, BNE, dsb.): overflow=0
    wire overflow_add  = (SrcA[31] & d2[31] & ~sum[31]) |
                         (~SrcA[31] & ~d2[31] & sum[31]);

    wire overflow_sub  = (SrcA[31] & ~d2[31] & ~sum[31]) |
                         (~SrcA[31] & d2[31] & sum[31]);

    assign overflow = (ALUControl == 4'b0000) ? overflow_add  : 
                      (ALUControl == 4'b0010) ? overflow_sub  : 1'b0;

    //====================================================
    // Pilih hasil ALU berdasarkan ALUControl
    //====================================================
    always @(*) begin
        case (ALUControl)
            // ------------------------------------------------
            // 0000: ADD (I‐type ADDI atau R‐type ADD)
            // 0001: ADDU (R‐type ADDU)
            // 0010: SUB (R‐type SUB)
            // 0011: SUBU (R‐type SUBU)
            // ------------------------------------------------
            4'b0000,  // ADD
            4'b0001,  // ADDU
            4'b0010,  // SUB
            4'b0011:  // SUBU
                ALUResult = sum;  // Hasil fullAddSub32

            // ------------------------------------------------
            // 0100: AND
            // ------------------------------------------------
            4'b0100:
                ALUResult = SrcA & RD2;

            // ------------------------------------------------
            // 0101: OR
            // ------------------------------------------------
            4'b0101:
                ALUResult = SrcA | RD2;

            // ------------------------------------------------
            // 0110: SLL (shift left logical)
            //         – operand: register kedua (RD2?), 
            //           shift‐amount dari sa (5 bit)
            // ------------------------------------------------
            4'b0110:
                ALUResult = RD2 << sa;

            // ------------------------------------------------
            // 0111: SRL (shift right logical)
            // ------------------------------------------------
            4'b0111:
                ALUResult = RD2 >> sa;

            // ------------------------------------------------
            // 1000: SLT (set on less than, signed)
            // ------------------------------------------------
            4'b1000:
                ALUResult = ($signed(SrcA) < $signed(RD2)) ? 32'b1 : 32'b0;

            // ------------------------------------------------
            // 1001: BEQ (pakai subtract, cek Zero saja)
            // 1010: BNE (pakai subtract, cek Zero saja)
            // – Untuk BEQ/BNE, ALUResult = sum = SrcA – RD2
            // – Zero flag akan high jika sum==0
            // ------------------------------------------------
            4'b1001,  // BEQ
            4'b1010:  // BNE
                ALUResult = sum;

            // ------------------------------------------------
            // Default: instruksi tidak dikenal → ALUResult=0
            // ------------------------------------------------
            default:
                ALUResult = 32'b0;
        endcase
    end

endmodule

