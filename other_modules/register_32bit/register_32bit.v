module register_32bit (IN, OUT, RESET, CLK, BUSYWAIT);

    input [31:0] IN;
    input RESET, CLK, BUSYWAIT;
    output reg [31:0] OUT;

    always @(RESET) begin
        if (RESET)  OUT = -32'd4;
    end

    always @(posedge CLK) begin
        if (!RESET & !BUSYWAIT)  OUT <= IN;
    end

endmodule