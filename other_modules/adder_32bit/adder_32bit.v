module adder_32bit (IN1, OUT);

    input [31:0] IN1;
    output [31:0] OUT;

    assign OUT = IN1 + 32'd4;

endmodule