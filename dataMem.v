module dmem (
    input clk,
    input WE,
    input [31:0] A,
    input [31:0] WD,
    output [31:0] RD
);
    reg [31:0] RAM [0:255];  // 256 x 32-bit word memory

    // Inisialisasi awal (semua nol)
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            RAM[i] = 32'h00000000;
    end

    // Operasi write
    always @(posedge clk) begin
        if (WE)
            RAM[A[9:2]] <= WD;  // Asumsikan word-aligned addressing
    end

    // Operasi read
    assign RD = RAM[A[9:2]];
endmodule
