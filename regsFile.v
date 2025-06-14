module regsFile( 
    A1,
    A2,
    WE3,
    A3,
    WD3,
    RD1,
    RD2
);

    input [4:0] A1;
    input [4:0] A2;
    input [4:0] A3;
    input [31:0] WD3;

    input WE3;
    output reg [31:0] RD1;
    output reg [31:0] RD2;
    
    reg [31:0] regMem [31:0]; // register memory
    

  always @(A1 or A2)
  begin
    RD1 = regMem[A1];
    RD2 = regMem[A2];
  end

  always @(posedge WE3)
  begin
    if(A3 == 5'b0) regMem[0] = 5'b0;
    else regMem[A3] = WD3;
  end

    integer i;

    initial 
    begin
        for( i = 0; i < 32; i = i + 1 )
            regMem[i] = i;
    end

endmodule

