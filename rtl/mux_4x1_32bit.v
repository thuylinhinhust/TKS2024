module mux_4x1_32bit (IN0, IN1, IN2, IN3, OUT, SELECT);

    input [31:0] IN0, IN1, IN2, IN3;
    input [1:0] SELECT;
    output reg [31:0] OUT;

    always @(SELECT or IN0 or IN1 or IN2 or IN3) begin
        case (SELECT)
            2'b11: OUT = IN3;
            2'b10: OUT = IN2;
            2'b01: OUT = IN1;
            default: OUT = IN0;
        endcase
    end

endmodule