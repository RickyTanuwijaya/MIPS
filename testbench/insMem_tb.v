`include "../insMem.v"

module imem_test;

    reg [31:0] PC;
    wire [31:0] Instr;

    InstructionMemory uut (
        .A(PC),
        .RD(Instr)
    );

    integer index;

    initial begin
        $display("=== Instruction Memory Test ===");

        // Test fetch dari beberapa alamat
        PC = 32'h00000000; #1;
        index = PC[9:2];
        $display("PC = %08h (line %0d) => Instr = %08h", PC, index, Instr);

        PC = 32'h00000004; #1;
        index = PC[9:2];
        $display("PC = %08h (line %0d) => Instr = %08h", PC, index, Instr);

        PC = 32'h00000008; #1;
        index = PC[9:2];
        $display("PC = %08h (line %0d) => Instr = %08h", PC, index, Instr);

        PC = 32'h0000000C; #1;
        index = PC[9:2];
        $display("PC = %08h (line %0d) => Instr = %08h", PC, index, Instr);

        PC = 32'h00000010; #1;
        index = PC[9:2];
        $display("PC = %08h (line %0d) => Instr = %08h", PC, index, Instr);

        PC = 32'h0000003C; #1;
        index = PC[9:2];
        $display("PC = %08h (line %0d) => Instr = %08h", PC, index, Instr);

        $display("=== Test Complete ===");
        $finish;
    end
endmodule

