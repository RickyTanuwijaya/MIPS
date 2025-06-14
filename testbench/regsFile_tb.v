`timescale 1ns / 1ps
`include "../regsFile.v"
module regsFile_tb;

  // Sinyal internal
  reg [4:0] A1, A2, A3;
  reg [31:0] WD3;
  reg WE3;
  wire [31:0] RD1, RD2;

  // Instansiasi modul
  regsFile uut (
    .A1(A1),
    .A2(A2),
    .WE3(WE3),
    .A3(A3),
    .WD3(WD3),
    .RD1(RD1),
    .RD2(RD2)
  );

  integer i;

  initial begin
    $display("Starting extended testbench...");
    $dumpfile("regsFile_tb.vcd");
    $dumpvars(0, regsFile_tb);

    // Inisialisasi awal
    WE3 = 0;
    A1 = 0;
    A2 = 0;
    A3 = 0;
    WD3 = 0;

    #10;
    // --- Write ke semua register (kecuali reg[0])
    for (i = 1; i < 32; i = i + 1) begin
		A3 = i[4:0];
		WD3 = i * 16;
		WE3 = 1;
		#1; // Tambahkan delay kecil sebelum display agar urut
		$display("Writing reg[%0d] <= %h", i, WD3);
		#4;
		WE3 = 0;
		#5;
	end

    // --- Baca balik semua register
    for (i = 1; i < 32; i = i + 1) begin
      A1 = i[4:0];
      #5;
      $display("Read reg[%0d]=%0d (expected %0d)", i, RD1, i * 16);
    end

    // --- Tes $zero tetap 0
    A3 = 5'd0;
    WD3 = 32'hFFFFFFFF;
    WE3 = 1;
    #5;
    WE3 = 0;
    A1 = 5'd0;
    #5;
    $display("reg[0] = %h (expected 00000000)", RD1);

    $display("Extended test completed.");
    $finish;
  end

endmodule


