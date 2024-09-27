module if_id_pipeline_reg (IN_INSTRUCTION, IN_PC, IN_COMPRESS, IN_ILLEGAL, OUT_INSTRUCTION, OUT_PC, OUT_COMPRESS, OUT_ILLEGAL, CLK, RST_N, PC_SEL, ENA);

    input CLK, RST_N;
    input PC_SEL, ENA;
    input IN_COMPRESS, IN_ILLEGAL;
    input [31:0] IN_INSTRUCTION, IN_PC;
    output reg OUT_COMPRESS, OUT_ILLEGAL;
    output reg [31:0] OUT_INSTRUCTION, OUT_PC;

    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            OUT_PC <= 32'b0;
            OUT_INSTRUCTION <= 32'b0;
            OUT_COMPRESS <= 1'bx; 
            OUT_ILLEGAL <= 1'bx;
        end
        else if (PC_SEL) begin
            OUT_PC <= 32'b0;
            OUT_INSTRUCTION <= 32'b0;
            OUT_COMPRESS <= 1'bx; 
            OUT_ILLEGAL <= 1'bx;
        end
        else if (ENA) begin    
            OUT_PC <= IN_PC;
            OUT_INSTRUCTION <= IN_INSTRUCTION;
            OUT_COMPRESS <= IN_COMPRESS; 
            OUT_ILLEGAL <= IN_ILLEGAL;
        end
    end

endmodule