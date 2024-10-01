module control_unit (OPCODE, FUNCT3, FUNCT7, OP1SEL, OP2SEL, REG_WRITE_EN, WB_SEL, ALUOP, BRANCH_JUMP, IMM_SEL, READ_WRITE);

input [31:0] IN_INSTRUCTION;
input [6:0] OPCODE;
input [2:0] FUNCT3;
input [6:0] FUNCT7;
output OP1SEL, OP2SEL, REG_WRITE_EN;
output [1:0] WB_SEL;
output [4:0] ALUOP;
output [2:0] BRANCH_JUMP;
output [2:0] IMM_SEL;
output [3:0] READ_WRITE;
output ecall_insn_o, dret_insn_o, mret_insn_o, wfi_insn_o, ebrk_insn_o;

wire LUI, AUIPC, JAL, JALR, B_TYPE, LOAD, STORE, I_TYPE, R_TYPE;
wire ALUOP_TYPE, BJ_TYPE;
wire [2:0] IMM_TYPE; 
wire SYSTEM; 

//xac dinh lenh dua tren opcode
and lui (LUI, !OPCODE[6], OPCODE[5], OPCODE[4], !OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]); //opcode = 0110111
and auipc (AUIPC, !OPCODE[6], !OPCODE[5], OPCODE[4], !OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]);
and jal (JAL, OPCODE[6], OPCODE[5], !OPCODE[4], OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]);
and jalr (JALR, OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]);
and b_type (B_TYPE, OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and load (LOAD, !OPCODE[6], !OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and store (STORE, !OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and i_type (I_TYPE, !OPCODE[6], !OPCODE[5], OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and r_type (R_TYPE, !OPCODE[6], OPCODE[5], OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);

and system_inst(SYSTEM, OPCODE[6], OPCODE[5], OPCODE[4], !OPCODE[3], !OPCODE[2], !OPCODE[1], OPCODE[0]); //system opcode = 1110011

or op1sel (OP1SEL, AUIPC, JAL, B_TYPE);  //use PC+imm //neu lenh la AUIPC, JAL, B_TYPE thi toan hang dau tien la PC+imm
or op2sel (OP2SEL, AUIPC, JAL, JALR, B_TYPE, LOAD, STORE, I_TYPE);  //use imm -> except R-type, LUI (imm from WB mux) //neu lenh la AUIPC, JAL, JALR, B_TYPE, LOAD, STORE, I_TYPE thi toan hang thu hai la immediate (tru R_TYPE va LUI)
or reg_write_en (REG_WRITE_EN, LUI, AUIPC, JAL, JALR, LOAD, I_TYPE, R_TYPE); // xac dinh khi nao thanh ghi can ghi du lieu
or wb_sel1 (WB_SEL[1], LUI, JAL, JALR);  //WB (PC+4) -> JAL, JALR; imm -> LUI //ghi du lieu vao thanh ghi
or wb_sel0 (WB_SEL[0], JAL, JALR, LOAD);  //(PC+4), LOAD
or aluop_type (ALUOP_TYPE, I_TYPE, R_TYPE);
or bj_type (BJ_TYPE, JAL, JALR, B_TYPE);
or imm_type2 (IMM_TYPE[2], JALR, I_TYPE, LOAD);
or imm_type1 (IMM_TYPE[1], B_TYPE, STORE);
or imm_type0 (IMM_TYPE[0], JAL, B_TYPE);

//////////////////////////////////////////////
//  BRANCH_JUMP generation unit
//////////////////////////////////////////////
wire BRANCH0_OR_OUTPUT;

// BRANCH_JUMP[2] bit
and branch2 (BRANCH_JUMP[2], !OPCODE[2], BJ_TYPE, FUNCT3[2]);

// BRANCH_JUMP[1] bit
or branch1 (BRANCH_JUMP[1], OPCODE[2], !BJ_TYPE, FUNCT3[1]);

// BRANCH_JUMP[0] bit
or branch0_or (BRANCH0_OR_OUTPUT, OPCODE[2], FUNCT3[0]);
and branch0 (BRANCH_JUMP[0], BRANCH0_OR_OUTPUT, BJ_TYPE);

//////////////////////////////////////////////
// IMM_SEL generation unit
//////////////////////////////////////////////
wire IMM_SEL1_AND1_OUTPUT, IMM_SEL1_AND2_OUTPUT, IMM_SEL0_OR1_OUTPUT, IMM_SEL0_AND1_OUTPUT, IMM_SEL0_AND2_OUTPUT, IMM_SEL1_OR_OUTPUT, IMM_SEL0_OR2_OUTPUT;

// IMM_SEL[2] bit
assign IMM_SEL[2] = IMM_TYPE[2];

// IMM_SEL[1] bit
and imm_sel1_and1 (IMM_SEL1_AND1_OUTPUT, IMM_TYPE[2], !FUNCT3[2], FUNCT3[1], FUNCT3[0]);
and imm_sel1_and2 (IMM_SEL1_AND2_OUTPUT, !IMM_TYPE[2], IMM_TYPE[1]);
or imm_sel1_or (IMM_SEL1_OR_OUTPUT, IMM_SEL1_AND1_OUTPUT, IMM_SEL1_AND2_OUTPUT);
and imm_sel1_and3 (IMM_SEL[1], !LOAD, IMM_SEL1_OR_OUTPUT);

// IMM_SEL[0] bit
or imm_sel0_or1 (IMM_SEL0_OR1_OUTPUT, !FUNCT3[2], !FUNCT3[1]);
and imm_sel0_and1 (IMM_SEL0_AND1_OUTPUT, IMM_SEL0_OR1_OUTPUT, FUNCT3[0], IMM_TYPE[2]);
and imm_sel0_and2 (IMM_SEL0_AND2_OUTPUT, !IMM_TYPE[2], IMM_TYPE[0]);
or imm_sel0_or2 (IMM_SEL0_OR2_OUTPUT, IMM_SEL0_AND1_OUTPUT, IMM_SEL0_AND2_OUTPUT);
and imm_sel0_and3 (IMM_SEL[0], !LOAD, IMM_SEL0_OR2_OUTPUT);

//////////////////////////////////////////////
// ALUOP generation unit
//////////////////////////////////////////////
wire I_SHIFT, FUNCT7_EN, FUNCT7_5, FUNCT7_0;

and i_shift (I_SHIFT, IMM_SEL[2], !IMM_SEL[1], IMM_SEL[0]);
or r_type_or_i_shift (FUNCT7_EN, I_SHIFT, R_TYPE);

and funct7_5_en (FUNCT7_5, FUNCT7[5], FUNCT7_EN);
and funct7_0_en (FUNCT7_0, FUNCT7[0], FUNCT7_EN);

and aluop4 (ALUOP[4], FUNCT3[2], ALUOP_TYPE);    // ALUOP[4] bit
and aluop3 (ALUOP[3], FUNCT3[1], ALUOP_TYPE);    // ALUOP[3] bit
and aluop2 (ALUOP[2], FUNCT3[0], ALUOP_TYPE);    // ALUOP[2] bit
and aluop1 (ALUOP[1], FUNCT7_5, ALUOP_TYPE);     // ALUOP[1] bit
and aluop0 (ALUOP[0], FUNCT7_0, ALUOP_TYPE);     // ALUOP[0] bit

//////////////////////////////////////////////
// READ_WRITE to data memory
//////////////////////////////////////////////
wire LBU, LHU, SH, SW, SB, LW, LH;

and lbu (LBU, !STORE, LOAD, FUNCT3[2], !FUNCT3[1], !FUNCT3[0]);
and lhu (LHU, !STORE, LOAD, FUNCT3[2], !FUNCT3[1], FUNCT3[0]);
and sh (SH, STORE, !LOAD, !FUNCT3[2], !FUNCT3[1], FUNCT3[0]);
and sw (SW, STORE, !LOAD, !FUNCT3[2], FUNCT3[1], !FUNCT3[0]);
and sb (SB, STORE, !LOAD, !FUNCT3[2], !FUNCT3[1], !FUNCT3[0]);
and lw (LW, !STORE, LOAD, !FUNCT3[2], FUNCT3[1], !FUNCT3[0]);
and lh (LH, !STORE, LOAD, !FUNCT3[2], !FUNCT3[1], FUNCT3[0]);

or mem_rw3 (READ_WRITE[3], LOAD, STORE);
or mem_rw2 (READ_WRITE[2], LBU, LHU, SH, SW);
or mem_rw1 (READ_WRITE[1], SH, SW, SB, LW);
or mem_rw0 (READ_WRITE[0], SW, SB, LHU, LH);

//SYSTEM opcode decoding (opcode = 1110011)
// ecall, ebreak, mret, dret, wfi signals
and ecall_inst (ecall_insn_o, SYSTEM, (FUNCT3 == 3'b000), (IN_INSTRUCTION[31:20] == 12'h000));
and ebreak_inst (ebrk_insn_o, SYSTEM, (FUNCT3 == 3'b000), (IN_INSTRUCTION[31:20] == 12'h001));
and mret_inst (mret_insn_o, SYSTEM, (FUNCT3 == 3'b000), (IN_INSTRUCTION[31:20] == 12'h302));
and dret_inst (dret_insn_o, SYSTEM, (FUNCT3 == 3'b000), (IN_INSTRUCTION[31:20] == 12'h7b2));
and wfi_inst (wfi_insn_o, SYSTEM, (FUNCT3 == 3'b000), (IN_INSTRUCTION[31:20] == 12'h105));

endmodule