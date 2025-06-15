`include "fullAdder.v"
`include "fullAddSub32.v"

module ALUControl (
    input [1:0] ALUOp,
    input [5:0] funct,
    output reg [3:0] aluCtrl
);

    always @(*) begin
        case (ALUOp)
            2'b00: aluCtrl = 4'b0010; // LW or SW → ADD
            2'b01: aluCtrl = 4'b0110; // BEQ → SUB
            2'b10: begin // R-type
                case (funct)
                    6'b100000: aluCtrl = 4'b0010; // ADD
                    6'b100010: aluCtrl = 4'b0110; // SUB
                    6'b100100: aluCtrl = 4'b0000; // AND
                    6'b100101: aluCtrl = 4'b0001; // OR
                    6'b101010: aluCtrl = 4'b0111; // SLT
                    default:   aluCtrl = 4'b1111; // INVALID
                endcase
            end
            default: aluCtrl = 4'b1111; // INVALID
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
