`include "../dataMem.v"

module dmem_tb;
    // Sinyal untuk testbench
    reg clk;
    reg WE;             // Write Enable (memWrite)
    reg [31:0] A;       // Address input (ALUResult)
    reg [31:0] WD;      // Write Data
    wire [31:0] RD;     // Read Data

    // Instantiate modul dmem
    dmem uut (
        .clk(clk),
        .WE(WE),
        .A(A),
        .WD(WD),
        .RD(RD)
    );

    // Clock generator: toggle setiap 5 time units
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Urutan pengujian
    initial begin
        // Inisialisasi awal
        WE = 0;
        A  = 0;
        WD = 0;

        // Tunggu beberapa waktu
        #10;

        // --- Tes Penulisan ke alamat 0x04 ---
        A = 32'h04;
        WD = 32'hDEADBEEF;
        WE = 1;
        #10;        // Tunggu 1 siklus clock
        WE = 0;     // Matikan sinyal write

        // --- Tes Penulisan ke alamat 0x08 ---
        A = 32'h08;
        WD = 32'hCAFEBABE;
        WE = 1;
        #10;
        WE = 0;

        // --- Tes Pembacaan dari alamat 0x04 ---
        A = 32'h04;
        #1;         // Tunggu sedikit supaya RD stabil
        $display("Read from 0x04: %h (expected: DEADBEEF)", RD);
        #9;

        // --- Tes Pembacaan dari alamat 0x08 ---
        A = 32'h08;
        #1;
        $display("Read from 0x08: %h (expected: CAFEBABE)", RD);
        #9;

        // --- Tes Pembacaan dari alamat 0x0C (belum ditulis) ---
        A = 32'h0C;
        #1;
        $display("Read from 0x0C: %h (expected: 00000000)", RD);

        // Selesai
        #10;
        $finish;
    end
endmodule
