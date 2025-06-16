`include "./fullAdder.v"
`include "./fullAddSub32.v"

module ALUControl (
    input  wire [1:0] ALUOp,    // dari control unit
    input  wire [5:0] funct,    // dari field funct di instruksi R-type
    output reg  [3:0] aluCtrl   // untuk ke ALU utama
);

parameter ADDFN  = 6'b100000;
parameter ADDUFN = 6'b100001;
parameter SUBFN  = 6'b100010;
parameter SUBUFN = 6'b100011;
parameter ANDFN  = 6'b100100;
parameter ORFN   = 6'b100101;
parameter SLLFN  = 6'b000000;
parameter SRLFN  = 6'b000010;
parameter SLTFN  = 6'b101010;

reg [3:0] fno;
/* aluCtrl: 
    0: Add
    1: addu
    2: subtract
    3: subu
    4: and
    5: or
    6: sll
    7: srl
    8: slt
//    9: lw , sw
10  9: beq
11  10: bne

*/

    always @ (funct)
    begin
        case(funct)
            ADDFN: fno = 4'b0000;
            ADDUFN: fno = 4'b0001;
            SUBFN: fno = 4'b0010;
            SUBUFN: fno = 4'b0011;
            ANDFN: fno = 4'b0100;
            ORFN: fno = 4'b0101;
            SLLFN: fno = 4'b0110;
            SRLFN: fno = 4'b0111;
            SLTFN: fno = 4'b1000;
            default: fno = 4'b0000;
        endcase
    end

/* ALUOP: 2 bits: 
00 RTYPE
01 SW LW ADDI 
10 BEQ
11 BNE
*/
    always @ (ALUOp)
    begin
        case(ALUOp)
            2'b00: aluCtrl = fno;
            2'b01: aluCtrl = 4'b0000;// normal ADD op but immediate source 
            2'b10: aluCtrl = 4'b1001;//9
            2'b11: aluCtrl = 4'b1010;//10
            default: aluCtrl = 4'b0000;
        endcase
    end
endmodule


module alu(
    input  wire        ALUSrc,
    input  wire [31:0] SrcA,
    input  wire [31:0] RD2,
    input  wire [31:0] SignImm,
    input  wire [4:0]  sa,
    input  wire [3:0]  aluCtrl,

    output reg  [31:0] ALUResult,
    output wire        Zero,
    output wire        overflow
);

    wire [31:0] d2;
    wire [31:0] sum;
    wire        carry;

    assign d2 = (ALUSrc == 1'b1) ? SignImm : RD2;

    wire op;
    assign op = (aluCtrl == 4'b0010)  // SUB
             || (aluCtrl == 4'b0011)  // SUBU
             || (aluCtrl == 4'b1001)  // BEQ
             || (aluCtrl == 4'b1010)  // BNE
             ? 1'b1 : 1'b0;

    fullAddSub32 addsub (
        .num1   (SrcA),
        .num2   (d2),
        .op     (op),
        .sumO   (sum),
        .carryO (carry)
    );

    assign Zero = (sum == 32'b0) ? 1'b1 : 1'b0;

    wire overflow_add = (SrcA[31] & d2[31] & ~sum[31]) |
                        (~SrcA[31] & ~d2[31] & sum[31]);

    wire overflow_sub = (SrcA[31] & ~d2[31] & ~sum[31]) |
                        (~SrcA[31] & d2[31] & sum[31]);

    assign overflow = (aluCtrl == 4'b0000) ? overflow_add :
                      (aluCtrl == 4'b0010) ? overflow_sub : 1'b0;

    always @(*) begin
        case (aluCtrl)
            4'b0000, 4'b0001, 4'b0010, 4'b0011: ALUResult = sum;              // ADD, ADDU, SUB, SUBU
            4'b0100: ALUResult = SrcA & RD2;                                  // AND
            4'b0101: ALUResult = SrcA | RD2;                                  // OR
            4'b0110: ALUResult = RD2 << sa;                                   // SLL
            4'b0111: ALUResult = RD2 >> sa;                                   // SRL
            4'b1000: ALUResult = ($signed(SrcA) < $signed(RD2)) ? 32'b1 : 32'b0; // SLT
            4'b1001, 4'b1010: ALUResult = sum;                                // BEQ, BNE
            default: ALUResult = 32'b0;
        endcase
    end

endmodule

