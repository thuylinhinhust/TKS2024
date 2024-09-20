module if_id_pipeline_reg (IN_INSTRUCTION, IN_PC, OUT_INSTRUCTION, OUT_PC, CLK, RESET, PC_SEL);

    input CLK, RESET;
    input PC_SEL;
    input [31:0] IN_INSTRUCTION, IN_PC;
    output reg [31:0] OUT_INSTRUCTION, OUT_PC;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            OUT_PC <= 32'dx;
            OUT_INSTRUCTION <= 32'dx;
        end
        else if (PC_SEL) begin
            OUT_PC <= 32'dx;
            OUT_INSTRUCTION <= 32'dx;
        end
        else begin    
            OUT_PC <= IN_PC;
            OUT_INSTRUCTION <= IN_INSTRUCTION;
        end
    end

endmodule