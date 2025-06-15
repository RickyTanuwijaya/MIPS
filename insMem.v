module InstructionMemory (
    input  [31:0] PC,       // Alamat instruksi (Program Counter)
    output [31:0] RD        // Instruksi keluar
);
    reg [31:0] memory [0:255]; // Memori 256 word (32-bit)
    parameter IM_DATA = "im.mips";

    // Word-aligned access: ambil word ke-n dari PC
    assign RD = memory[PC[9:2]];

    // Load instruksi dari file eksternal (.mips file)
    initial begin
        $readmemh(IM_DATA, memory); // Format HEX
        // $readmemb(IM_DATA, memory); // Format BIN (jika perlu)
    end

endmodule
