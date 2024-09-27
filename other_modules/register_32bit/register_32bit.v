module register_32bit (IN, OUT, RST_N, CLK, ENA);

    input [31:0] IN;
    input RST_N, CLK, ENA;
    output reg [31:0] OUT;

    always @(posedge CLK or negedge RST_N) 
    begin
        if (!RST_N)  OUT <= 32'b0;
        else if (ENA)  OUT <= IN;
    end

endmodule