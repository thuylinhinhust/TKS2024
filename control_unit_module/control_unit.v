module control_unit (OPCODE, FUNCT3, FUNCT7, OP1SEL_OUT, OP2SEL_OUT, REG_WRITE_EN_OUT, WB_SEL_OUT, ALUOP_OUT, BRANCH_JUMP_OUT, IMM_SEL_OUT, READ_WRITE_OUT);

input [6:0] OPCODE;
input [2:0] FUNCT3;
input [6:0] FUNCT7;
output OP1SEL_OUT, OP2SEL_OUT, REG_WRITE_EN_OUT;
output [1:0] WB_SEL_OUT;
output [4:0] ALUOP_OUT;
output [2:0] BRANCH_JUMP_OUT;
output [2:0] IMM_SEL_OUT;
output [3:0] READ_WRITE_OUT;

wire OP1SEL, OP2SEL, REG_WRITE_EN;
wire [1:0] WB_SEL;
wire [4:0] ALUOP;
wire [2:0] BRANCH_JUMP;
wire [2:0] IMM_SEL;
wire [3:0] READ_WRITE;

assign OP1SEL_OUT = OP1SEL;
assign OP2SEL_OUT = OP2SEL;
assign REG_WRITE_EN_OUT = REG_WRITE_EN;
assign WB_SEL_OUT = WB_SEL;
assign ALUOP_OUT = ALUOP;
assign BRANCH_JUMP_OUT = BRANCH_JUMP;
assign IMM_SEL_OUT = IMM_SEL;
assign READ_WRITE_OUT = READ_WRITE;

wire LUI, AUIPC, JAL, JALR, B_TYPE, LOAD, STORE, I_TYPE, R_TYPE;
wire ALUOP_TYPE, BL;
wire [2:0] IMM_TYPE; 

and lui(LUI, !OPCODE[6], OPCODE[5], OPCODE[4], !OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]);
and auipc(AUIPC, !OPCODE[6], !OPCODE[5], OPCODE[4], !OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]);
and jal(JAL, OPCODE[6], OPCODE[5], !OPCODE[4], OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]);
and jalr(JALR, OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]);
and b_type(B_TYPE, OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and load(LOAD, !OPCODE[6], !OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and store(STORE, !OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and i_type(I_TYPE, !OPCODE[6], !OPCODE[5], OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and r_type(R_TYPE, !OPCODE[6], OPCODE[5], OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);

or op1sel(OP1SEL, AUIPC, JAL, B_TYPE);
or op2sel(OP2SEL, AUIPC, JAL, JALR, B_TYPE, LOAD, STORE, I_TYPE);
or reg_write_en(REG_WRITE_EN, LUI, AUIPC, JAL, JALR, LOAD, I_TYPE, R_TYPE);
or wb_sel1(WB_SEL[1], LUI, JAL, JALR);
or wb_sel0(WB_SEL[0], JAL, JALR, LOAD);
or aluop_type(ALUOP_TYPE, I_TYPE, R_TYPE);
or bl(BL, JAL, JALR, B_TYPE);
or imm_type2(IMM_TYPE[2], JALR, I_TYPE,LOAD);
or imm_type1(IMM_TYPE[1], B_TYPE, STORE);
or imm_type0(IMM_TYPE[0], JAL, B_TYPE);

//////////////////////////////////////////////
//  BRANCH_JUMP generation unit
//////////////////////////////////////////////
wire BRANCH0_OR_OUTPUT;

// BRANCH_JUMP[2] bit
and branch2(BRANCH_JUMP[2], !OPCODE[2], BL, FUNCT3[2]);

// BRANCH_JUMP[1] bit
or branch1(BRANCH_JUMP[1], OPCODE[2], !BL, FUNCT3[1]);

// BRANCH_JUMP[0] bit
or branch0_or(BRANCH0_OR_OUTPUT, OPCODE[2], FUNCT3[0]);
and branch0(BRANCH_JUMP[0], BRANCH0_OR_OUTPUT, BL);

//////////////////////////////////////////////
// IMM_SEL generation unit
//////////////////////////////////////////////
wire IMM_SEL1_AND1_OUTPUT, IMM_SEL1_AND2_OUTPUT, IMM_SEL0_OR1_OUTPUT, IMM_SEL0_AND1_OUTPUT, IMM_SEL0_AND2_OUTPUT, IMM_SEL1_OR_OUTPUT, IMM_SEL0_OR2_OUTPUT;

// IMM_SEL[2] bit
assign IMM_SEL[2] = IMM_TYPE[2];

// IMM_SEL[1] bit
and imm_sel1_and1(IMM_SEL1_AND1_OUTPUT, IMM_TYPE[2], !FUNCT3[2], FUNCT3[1], FUNCT3[0]);
and imm_sel1_and2(IMM_SEL1_AND2_OUTPUT, !IMM_TYPE[2], IMM_TYPE[1]);
or imm_sel1_or(IMM_SEL1_OR_OUTPUT, IMM_SEL1_AND1_OUTPUT, IMM_SEL1_AND2_OUTPUT);
and imm_sel1_and3(IMM_SEL[1], !LOAD, IMM_SEL1_OR_OUTPUT);

// IMM_SEL[0] bit
or imm_sel0_or1(IMM_SEL0_OR1_OUTPUT, !FUNCT3[2], !FUNCT3[1]);
and imm_sel0_and1(IMM_SEL0_AND1_OUTPUT, IMM_SEL0_OR1_OUTPUT, FUNCT3[0], IMM_TYPE[2]);
and imm_sel0_and2(IMM_SEL0_AND2_OUTPUT, !IMM_TYPE[2], IMM_TYPE[0]);
or imm_sel0_or2(IMM_SEL0_OR2_OUTPUT, IMM_SEL0_AND1_OUTPUT, IMM_SEL0_AND2_OUTPUT);
and imm_sel0_and3(IMM_SEL[0], !LOAD, IMM_SEL0_OR2_OUTPUT);

//////////////////////////////////////////////
// ALUOP generation unit
//////////////////////////////////////////////
wire I_SHIFT, FUNCT7_EN, FUNCT7_5, FUNCT7_0;

and i_shift(I_SHIFT, IMM_SEL[2], !IMM_SEL[1], IMM_SEL[0]);
or r_type_or_i_shift(FUNCT7_EN, I_SHIFT, R_TYPE);

and funct7_5_en(FUNCT7_5, FUNCT7[5], FUNCT7_EN);
and funct7_0_en(FUNCT7_0, FUNCT7[0], FUNCT7_EN);

and aluop4(ALUOP[4], FUNCT3[2], ALUOP_TYPE);    // ALUOP[4] bit
and aluop3(ALUOP[3], FUNCT3[1], ALUOP_TYPE);    // ALUOP[3] bit
and aluop2(ALUOP[2], FUNCT3[0], ALUOP_TYPE);    // ALUOP[2] bit
and aluop1(ALUOP[1], FUNCT7_5, ALUOP_TYPE);     // ALUOP[1] bit
and aluop0(ALUOP[0], FUNCT7_0, ALUOP_TYPE);     // ALUOP[0] bit

//////////////////////////////////////////////
// READ_WRITE to cache memory
//////////////////////////////////////////////
wire READ_WRITE_AND1, READ_WRITE_AND2, READ_WRITE_AND3, READ_WRITE_AND4, READ_WRITE_AND5, READ_WRITE_AND6, READ_WRITE_AND7;

and mem_rw_and1(READ_WRITE_AND1, !STORE, LOAD, FUNCT3[2], !FUNCT3[1], !FUNCT3[0]);
and mem_rw_and2(READ_WRITE_AND2, !STORE, LOAD, FUNCT3[2], !FUNCT3[1], FUNCT3[0]);
and mem_rw_and3(READ_WRITE_AND3, STORE, !LOAD, !FUNCT3[2], !FUNCT3[1], FUNCT3[0]);
and mem_rw_and4(READ_WRITE_AND4, STORE, !LOAD, !FUNCT3[2], FUNCT3[1], !FUNCT3[0]);
and mem_rw_and5(READ_WRITE_AND5, STORE, !LOAD, !FUNCT3[2], !FUNCT3[1], !FUNCT3[0]);
and mem_rw_and6(READ_WRITE_AND6, !STORE, LOAD, !FUNCT3[2], FUNCT3[1], !FUNCT3[0]);
and mem_rw_and7(READ_WRITE_AND7, !STORE, LOAD, !FUNCT3[2], !FUNCT3[1], FUNCT3[0]);

or mem_rw3(READ_WRITE[3], LOAD, STORE);
or mem_rw2(READ_WRITE[2], READ_WRITE_AND1, READ_WRITE_AND2, READ_WRITE_AND3, READ_WRITE_AND4);
or mem_rw1(READ_WRITE[1], READ_WRITE_AND3, READ_WRITE_AND4, READ_WRITE_AND5, READ_WRITE_AND6);
or mem_rw0(READ_WRITE[0], READ_WRITE_AND4, READ_WRITE_AND5, READ_WRITE_AND2, READ_WRITE_AND7);

endmodule