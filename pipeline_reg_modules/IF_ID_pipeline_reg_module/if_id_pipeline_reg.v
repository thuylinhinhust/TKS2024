module if_id_pipeline_reg(
    IN_INSTRUCTION, 
    IN_PC, 
    OUT_INSTRUCTION, 
    OUT_PC, 
    CLK, 
    RESET, 
    BUSYWAIT,
    PC_SEL);

    input PC_SEL;
    input [31:0] IN_INSTRUCTION, IN_PC;
    input CLK, RESET, BUSYWAIT;
    output reg [31:0] OUT_INSTRUCTION, OUT_PC;

    always @(RESET) begin
        if (RESET) begin
            OUT_PC = 32'dx;
            OUT_INSTRUCTION = 32'dx;
        end
    end

    always @(PC_SEL) begin
        if (PC_SEL) begin
            OUT_PC = 32'dx;
            OUT_INSTRUCTION = 32'dx;
        end
    end
    
    always @(posedge CLK)
    begin
        if (!BUSYWAIT) begin    
            OUT_PC <= IN_PC;
            OUT_INSTRUCTION <= IN_INSTRUCTION;
        end
    end

endmodule