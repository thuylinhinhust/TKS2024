module register_32bit (IN, OUT, RESET, CLK, ENA);

    input [31:0] IN;
    input RESET, CLK, ENA;
    output reg [31:0] OUT;

    always @(posedge CLK or posedge RESET) 
    begin
        if (RESET)  OUT <= 32'b0;
        else if (ENA)  OUT <= IN;
    end

endmodule