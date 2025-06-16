`include "alu.v"
`include "insMem.v"
`include "regsFile.v"
`include "dataMem.v"
`include "control.v"
`timescale 1ns / 1ps

module cpu(
    input clk,
    input reset
);

    // Define state constants
    parameter IF = 3'b000, ID = 3'b001, EX = 3'b010, MEM = 3'b011, WB = 3'b100;

    reg [2:0] stage;
    reg [31:0] PC;
    reg [31:0] instruction;
    reg [31:0] NextAdd;
    reg [31:0] ScrA, ScrB;
    reg [31:0] SignImm;
    reg [31:0] ALUResult;
    reg [31:0] rgwdata;
    reg [31:0] MemData;
    reg MemopInProg;
    wire [31:0] PCNext = PC + NextAdd;
    reg memRWPin;

    // Wires for control unit outputs
	wire [31:0] ALUResultWire;
    wire [1:0] contAluop;
    wire contALUSrc;
    wire contRegWrite;
    wire contMemWrite;
    wire contMemRead;
    wire contMemtoReg;
    wire contBranch;
    wire contJmp;
    wire contRegDst;
	
		
    // Wires for decoded instruction fields
    wire [4:0] rs = instruction[25:21];
    wire [4:0] rt = instruction[20:16];
    wire [4:0] rd = instruction[15:11];
    wire [15:0] imm = instruction[15:0];
    wire [5:0] opcode = instruction[31:26];
    wire [5:0] funct = instruction[5:0];
    wire [25:0] instidx = instruction[25:0];
    wire [31:0] addrim = {{14{instruction[15]}}, instruction[15:0]};

    wire [31:0] RD1, RD2;
    wire [3:0] aluCtrl;
    reg aluSrc;
    wire [31:0] ALUIn2 = aluSrc ? SignImm : ScrB;
    wire Zero;
    wire Overflow;
    wire [31:0] dataBus;
    wire [31:0] addressBus = ALUResult;

    reg [4:0] A3;
    reg [31:0] WD3;
    reg WE3;

    wire [31:0] fetchedInst;
    wire memOpDone = 1'b1; // Simplified assumption for memory timing

    InstructionMemory imem(
        .PC(PC),
        .RD(fetchedInst)
    );

    regsFile regfile(
        .A1(rs),
        .A2(rt),
        .WE3(WE3),
        .A3(A3),
        .WD3(WD3),
        .RD1(RD1),
        .RD2(RD2)
    );

    control control_unit(
        .Opcode(opcode),
        .funct(funct),
        .RegDst(contRegDst),
        .ALUSrc(contALUSrc),
        .MemtoReg(contMemtoReg),
        .RegWrite(contRegWrite),
        .MemRead(contMemRead),
        .MemWrite(contMemWrite),
        .Branch(contBranch),
        .Jump(contJmp),
        .ALUOp(contAluop)
    );

    ALUControl alu_ctrl(
        .ALUOp(contAluop),
        .funct(funct),
        .aluCtrl(aluCtrl)
    );

    alu alu_unit(
        .ALUSrc(aluSrc),
        .SrcA(ScrA),
        .RD2(ScrB),
        .SignImm(SignImm),
        .aluCtrl(aluCtrl),
        .ALUResult(ALUResultWire),
        .Zero(Zero),
        .overflow(Overflow)
    );

    dmem data_memory(
        .clk(clk),
        .WE(memRWPin),
        .A(addressBus),
        .WD(MemData),
        .RD(dataBus)
    );

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            PC <= 32'b0;
            stage <= IF;
            NextAdd <= 32'd4;
            memRWPin <= 1'bz;
            MemData <= 32'b0;
            ScrA <= 0;
            ScrB <= 0;
        end else begin
            case (stage)
                IF: begin
                    WE3 <= 1'b0;
                    instruction <= fetchedInst;
                    stage <= ID;
                    memRWPin <= 1'bz;
                    ScrA <= 0;
                    ScrB <= 0;
                end
                ID: begin
                    aluSrc <= contALUSrc;
                    ScrA <= RD1;
                    ScrB <= RD2;
                    SignImm <= {{16{imm[15]}}, imm};
                    A3 <= contRegDst ? rd : rt;
                    stage <= EX;
                end
                EX: begin
					ALUResult <= ALUResultWire;
                    memRWPin <= 1'bz;
                    if (contJmp) begin
                        PC <= instidx << 2;
                        stage <= IF;
                    end else if (contBranch && Zero == 1'b0) begin
                        NextAdd <= addrim << 2;
                        PC <= PCNext;
                        stage <= IF;
                    end else if (contMemRead || contMemWrite) begin
                        stage <= MEM;
                    end else if (contRegWrite) begin
                        stage <= WB;
                        rgwdata <= ALUResult;
                    end else begin
                        NextAdd <= 4;
                        PC <= PCNext;
                        stage <= IF;
                    end
                end
                MEM: begin
                    ScrA <= 0;
                    ScrB <= 0;
                    if (MemopInProg) begin
                        if (memOpDone) begin
                            MemopInProg <= 1'b0;
                            if (contMemtoReg) begin
                                rgwdata <= dataBus;
                                stage <= WB;
                            end else begin
                                stage <= IF;
                                NextAdd <= 4;
                                PC <= PCNext;
                            end
                        end
                    end else if (contMemWrite) begin
                        MemData <= RD2;
                        memRWPin <= 1'b1;
                        MemopInProg <= 1'b1;
                    end else if (contMemRead) begin
                        memRWPin <= 1'b0;
                        MemopInProg <= 1'b1;
                    end
                end
                WB: begin
                    ScrA <= 0;
                    ScrB <= 0;
                    memRWPin <= 1'bz;
                    WE3 <= 1'b1;
                    WD3 <= rgwdata;
                    stage <= IF;
                    PC <= PCNext;
                end
                default: begin
                    stage <= IF;
                    PC <= PCNext;
                    WE3 <= 1'b0;
                end
            endcase
        end
    end
endmodule
