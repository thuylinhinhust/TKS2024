module mux_2x1_32bit (IN0, IN1, OUT, SELECT);

    input [31:0] IN0, IN1;
    input SELECT;
    output reg [31:0] OUT;
    
    always @(SELECT or IN0 or IN1) begin
        case (SELECT)
            1'b1: OUT = IN1;
            default: OUT = IN0;
        endcase
    end

endmodule