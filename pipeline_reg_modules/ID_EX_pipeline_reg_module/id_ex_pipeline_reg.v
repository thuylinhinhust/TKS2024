module id_ex_pipeline_reg(
    IN_INSTRUCTION,  //INSTRUCTION [11:7]
    IN_PC,
    IN_DATA1, 
    IN_DATA2, 
    IN_IMMEDIATE,
    IN_DATA1ALUSEL,
    IN_DATA2ALUSEL,
    IN_DATA1BJSEL,
    IN_DATA2BJSEL,
    IN_ALU_OP,
    IN_BRANCH_JUMP,
    IN_DATAMEMSEL,
    IN_READ_WRITE,
    IN_WB_SEL,
    IN_REG_WRITE_EN,
    OUT_INSTRUCTION,
    OUT_PC,
    OUT_DATA1,
    OUT_DATA2,
    OUT_IMMEDIATE, 
    OUT_DATA1ALUSEL,
    OUT_DATA2ALUSEL,
    OUT_DATA1BJSEL,
    OUT_DATA2BJSEL,
    OUT_ALU_OP,
    OUT_BRANCH_JUMP,
    OUT_DATAMEMSEL,
    OUT_READ_WRITE,
    OUT_WB_SEL,
    OUT_REG_WRITE_EN,
    CLK, 
    RESET,
    PC_SEL);

    input CLK, RESET, PC_SEL;
    input [4:0] IN_ALU_OP, IN_INSTRUCTION;
    input [2:0] IN_BRANCH_JUMP;
    input [1:0] IN_WB_SEL, IN_DATA1ALUSEL, IN_DATA2ALUSEL, IN_DATA1BJSEL, IN_DATA2BJSEL;
    input [3:0] IN_READ_WRITE;
    input [31:0] IN_PC, IN_DATA1, IN_DATA2, IN_IMMEDIATE;   
    input IN_DATAMEMSEL, IN_REG_WRITE_EN;

    output reg [4:0] OUT_ALU_OP, OUT_INSTRUCTION;
    output reg [2:0] OUT_BRANCH_JUMP;
    output reg [1:0] OUT_WB_SEL, OUT_DATA1ALUSEL, OUT_DATA2ALUSEL, OUT_DATA1BJSEL, OUT_DATA2BJSEL;
    output reg [3:0] OUT_READ_WRITE;
    output reg [31:0] OUT_PC, OUT_DATA1, OUT_DATA2, OUT_IMMEDIATE; 
    output reg OUT_DATAMEMSEL, OUT_REG_WRITE_EN;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            OUT_INSTRUCTION <= 5'dx;
            OUT_PC <= 32'dx;
            OUT_DATA1 <= 32'dx;
            OUT_DATA2 <= 32'dx;
            OUT_IMMEDIATE <= 32'dx;
            OUT_DATA1ALUSEL <= 2'dx;
            OUT_DATA2ALUSEL <= 2'dx;
            OUT_DATA1BJSEL <= 2'dx;
            OUT_DATA2BJSEL <= 2'dx;
            OUT_ALU_OP <= 5'dx;
            OUT_BRANCH_JUMP <= 3'dx;
            OUT_DATAMEMSEL <= 1'dx;
            OUT_READ_WRITE <= 4'dx;
            OUT_WB_SEL <= 2'dx;
            OUT_REG_WRITE_EN <= 1'dx;
        end
        else if (PC_SEL) begin
            OUT_INSTRUCTION <= 5'dx;
            OUT_PC <= 32'dx;
            OUT_DATA1 <= 32'dx;
            OUT_DATA2 <= 32'dx;
            OUT_IMMEDIATE <= 32'dx;
            OUT_DATA1ALUSEL <= 2'dx;
            OUT_DATA2ALUSEL <= 2'dx;
            OUT_DATA1BJSEL <= 2'dx;
            OUT_DATA2BJSEL <= 2'dx;
            OUT_ALU_OP <= 5'dx;
            OUT_BRANCH_JUMP <= 3'dx;
            OUT_DATAMEMSEL <= 1'dx;
            OUT_READ_WRITE <= 4'dx;
            OUT_WB_SEL <= 2'dx;
            OUT_REG_WRITE_EN <= 1'dx;
        end
        else begin
            OUT_INSTRUCTION <= IN_INSTRUCTION;
            OUT_PC <= IN_PC;
            OUT_DATA1 <= IN_DATA1;
            OUT_DATA2 <= IN_DATA2;
            OUT_IMMEDIATE <= IN_IMMEDIATE;
            OUT_DATA1ALUSEL <= IN_DATA1ALUSEL;
            OUT_DATA2ALUSEL <= IN_DATA2ALUSEL;
            OUT_DATA1BJSEL <= IN_DATA1BJSEL;
            OUT_DATA2BJSEL <= IN_DATA2BJSEL;
            OUT_ALU_OP <= IN_ALU_OP;
            OUT_BRANCH_JUMP <= IN_BRANCH_JUMP;
            OUT_DATAMEMSEL <= IN_DATAMEMSEL;
            OUT_READ_WRITE <= IN_READ_WRITE;
            OUT_WB_SEL <= IN_WB_SEL;
            OUT_REG_WRITE_EN <= IN_REG_WRITE_EN;
        end
    end

endmodule