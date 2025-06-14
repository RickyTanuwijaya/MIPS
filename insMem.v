module InstructionMemory (
    input  [31:0] A,        // Disamakan dengan nama sinyal dari testbench (A = PC)
    output [31:0] RD        // Instruksi keluar
);
    reg [31:0] memory [0:255]; // 256 word (32-bit)

    // Word-aligned access: PC[9:2] karena 2^8 = 256 word, dan 32-bit (4 byte)
    assign RD = memory[A[9:2]];

    // Load instruksi dari file eksternal (im.mips)
    initial begin
        $readmemh("im.mips", memory); // Format file hex
    end
endmodule
