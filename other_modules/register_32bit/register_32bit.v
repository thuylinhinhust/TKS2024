module register_32bit (IN, OUT, RESET, CLK);

    input [31:0] IN;
    input RESET, CLK;
    output reg [31:0] OUT;

    always @(posedge CLK or posedge RESET) 
    begin
        if (RESET)  OUT <= -32'd4;
        else  OUT <= IN;
    end

endmodule