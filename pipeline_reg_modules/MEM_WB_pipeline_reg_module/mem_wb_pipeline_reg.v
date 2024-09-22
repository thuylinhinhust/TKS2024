module mem_wb_pipeline_reg(
    IN_INSTRUCTION,  //INSTRUCTION [11:7]
    IN_PC_4,
    IN_ALU_RESULT, 
    IN_IMMEDIATE,
    IN_DMEM_OUT,
    IN_WB_SEL,
    IN_REG_WRITE_EN,
    OUT_INSTRUCTION,
    OUT_PC_4,
    OUT_ALU_RESULT,
    OUT_IMMEDIATE, 
    OUT_DMEM_OUT,
    OUT_WB_SEL,
    OUT_REG_WRITE_EN,
    CLK, 
    RESET);

    input [4:0] IN_INSTRUCTION;
    input [1:0] IN_WB_SEL;
    input [31:0] IN_PC_4, IN_ALU_RESULT, IN_IMMEDIATE, IN_DMEM_OUT;   
    input IN_REG_WRITE_EN, CLK, RESET;

    output reg [4:0] OUT_INSTRUCTION;
    output reg [1:0] OUT_WB_SEL;
    output reg [31:0] OUT_PC_4, OUT_ALU_RESULT, OUT_IMMEDIATE, OUT_DMEM_OUT; 
    output reg OUT_REG_WRITE_EN;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            OUT_INSTRUCTION <= 5'b0;
            OUT_PC_4 <= 32'b0;
            OUT_ALU_RESULT <= 32'b0;
            OUT_IMMEDIATE <=  32'b0;
            OUT_DMEM_OUT <= 32'b0;
            OUT_WB_SEL <= 2'bx;
            OUT_REG_WRITE_EN <= 1'bx;
        end
        else begin
            OUT_INSTRUCTION <= IN_INSTRUCTION;
            OUT_PC_4 <= IN_PC_4;
            OUT_ALU_RESULT <= IN_ALU_RESULT;
            OUT_IMMEDIATE <= IN_IMMEDIATE;
            OUT_DMEM_OUT <= IN_DMEM_OUT;
            OUT_WB_SEL <= IN_WB_SEL;
            OUT_REG_WRITE_EN <= IN_REG_WRITE_EN;
        end
    end

endmodule