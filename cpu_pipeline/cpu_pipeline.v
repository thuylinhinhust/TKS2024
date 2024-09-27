`include "../other_modules/mux_2x1_32bit/mux_2x1_32bit.v"
`include "../other_modules/mux_4x1_32bit/mux_4x1_32bit.v"
`include "../other_modules/register_32bit/register_32bit.v"
`include "../other_modules/adder_32bit/adder_32bit.v"
`include "../reg_file_module/reg_file.v"
`include "../control_unit_module/control_unit.v"
`include "../immediate_gen_module/immediate_generate.v"
`include "../alu_module/alu.v"
`include "../bj_detect_module/bj_detect.v"
`include "../pipeline_reg_modules/EX_MEM_pipeline_reg_module/ex_mem_pipeline_reg.v"
`include "../pipeline_reg_modules/ID_EX_pipeline_reg_module/id_ex_pipeline_reg.v"
`include "../pipeline_reg_modules/IF_ID_pipeline_reg_module/if_id_pipeline_reg.v"
`include "../pipeline_reg_modules/MEM_WB_pipeline_reg_module/mem_wb_pipeline_reg.v"
`include "../forwarding_unit_module/forwarding_unit.v"
`include "../stall_module/stall.v"
`include "../compress_decoder_module/compress_decoder.v"
`include "../interface_imem/interface_imem.v"
`include "../load_store_unit/load_store_unit.v"

module cpu_pipeline (CLK, RST_N, test_en_i, ram_cfg_i, hart_id_i, boot_addr_i, 
                     instr_req_o, instr_gnt_i, instr_rvalid_i, instr_addr_o, instr_rdata_i,
                     instr_rdata_intg_i, instr_err_i, data_req_o, data_gnt_i,
                     data_rvalid_i, data_we_o, data_be_o, data_addr_o, data_wdata_o,
                     data_wdata_intg_o, data_rdata_i, data_rdata_intg_i, data_err_i);

input CLK, RST_N;
input test_en_i, ram_cfg_i;
input [31:0] hart_id_i, boot_addr_i;

input instr_gnt_i, instr_rvalid_i, instr_err_i;
input [31:0] instr_rdata_i;
input [6:0] instr_rdata_intg_i;
output instr_req_o;
output [31:0] instr_addr_o;

input data_gnt_i, data_rvalid_i, data_err_i;
input [31:0] data_rdata_i;
input [6:0] data_rdata_intg_i;
output data_req_o, data_we_o;
output [3:0] data_be_o;
output [31:0] data_addr_o;
output [31:0] data_wdata_o;
output [6:0] data_wdata_intg_o;

wire [31:0] PC_4_OUT, ALU_OUT, PC_SEL_MUX_OUT, INSTRUCTION, INSTRUCTION_IF, INSTRUCTION_ID, PC_OUT_ID, WB_MUX_OUT, REG_FILE_OUT1, REG_FILE_OUT2, IMM_GEN_OUT, PC_OUT_EX, REG_FILE_OUT1_EX, REG_FILE_OUT2_EX, IMM_GEN_OUT_EX, OPERAND1, OPERAND2, PC_OUT_MEM, ALU_OUT_MEM, IMM_GEN_OUT_MEM, PC_4_WB_OUT, PC_4_WB_OUT_WB, ALU_OUT_WB, IMM_GEN_OUT_WB, READDATA_WB;
wire PC_SEL, REG_WRITE_EN_WB, WRITE_ENABLE, OP1SEL, OP2SEL, REG_WRITE_EN, REG_WRITE_EN_EX, REG_WRITE_EN_MEM;
wire [4:0] WRITE_ADDRESS_WB, WRITE_ADDRESS_EX, WRITE_ADDRESS_MEM;
wire [2:0] IMM_SEL, BRANCH_JUMP, BRANCH_JUMP_EX;
wire [1:0] WB_SEL, WB_SEL_EX, WB_SEL_MEM, WB_SEL_WB;
wire [4:0] ALUOP, ALUOP_EX;
wire [3:0] READ_WRITE, READ_WRITE_EX, READ_WRITE_EN;
wire DATA1IDSEL, DATA2IDSEL, DATAMEMSEL, DATAMEMSEL_EX , DATAMEMSEL_MEM;
wire [1:0] DATA1ALUSEL, DATA2ALUSEL, DATA1BJSEL, DATA2BJSEL;
wire [1:0] DATA1ALUSEL_EX, DATA2ALUSEL_EX, DATA1BJSEL_EX, DATA2BJSEL_EX;
wire [31:0] DATA1_ID, DATA2_ID;
wire [31:0] MUX_EX_BJ1_OUT, MUX_EX_BJ2_OUT;
wire [31:0] MUX_EX_OUT, MUX_EX_OUT_MEM;
wire [31:0] MUX_MEM_OUT;
wire STALL;
wire COMPRESS_INSTR, ILLEGAL_INSTR;
wire PC_ADDRESS;
wire [31:0] lsu_wdata, lsu_rdata;

assign WRITE_ENABLE = REG_WRITE_EN_WB;

// Instruction fetch stage
mux_2x1_32bit pc_sel_mux (
    .IN0 (PC_4_OUT),
    .IN1 (ALU_OUT),
    .OUT (PC_SEL_MUX_OUT),
    .SELECT (PC_SEL)
);

register_32bit program_counter (
    .IN (PC_SEL_MUX_OUT),
    .OUT (PC_ADDRESS),
    .RST_N (RST_N),
    .CLK (CLK),
    .ENA (~STALL)
);

adder_32bit pc_4_adder (
    .IN (PC_ADDRESS),
    .OUT (PC_4_OUT)
);

interface_imem imem (
    .PC (PC_ADDRESS),
    .instruction (INSTRUCTION),
    .instr_req_o (instr_req_o),
    .instr_gnt_i (instr_gnt_i),
    .instr_rvalid_i (instr_rvalid_i),
    .instr_addr_o (instr_addr_o),
    .instr_rdata_i (instr_rdata_i),
    .instr_rdata_intg_i (instr_rdata_intg_i),
    .instr_err_i (instr_err_i)
);

compress_decoder comp_decode (
    .instr_i (INSTRUCTION),
    .instr_o (INSTRUCTION_IF),
    .is_compressed_o (COMPRESS_INSTR),
    .illegal_instr_o (ILLEGAL_INSTR)
);

if_id_pipeline_reg if_id_reg (
    .IN_INSTRUCTION (INSTRUCTION_IF),
    .IN_PC (PC_ADDRESS),
    .IN_COMPRESS (COMPRESS_INSTR), 
    .IN_ILLEGAL (ILLEGAL_INSTR),
    .OUT_INSTRUCTION (INSTRUCTION_ID),
    .OUT_PC (PC_OUT_ID),
    .OUT_COMPRESS (), 
    .OUT_ILLEGAL (),
    .CLK (CLK),
    .RST_N (RST_N),
    .PC_SEL (PC_SEL),
    .ENA (~STALL)
);

// Instruction decode stage
reg_file register_file (
    .WRITE_DATA (WB_MUX_OUT),
    .DATA1 (REG_FILE_OUT1),
    .DATA2 (REG_FILE_OUT2),
    .WRITE_ADDRESS (WRITE_ADDRESS_WB),
    .DATA1_ADDRESS (INSTRUCTION_ID[19:15]),
    .DATA2_ADDRESS (INSTRUCTION_ID[24:20]),
    .WRITE_ENABLE (WRITE_ENABLE),
    .CLK (CLK),
    .RST_N (RST_N)
);

immediate_generate imm_gen (
    .IN (INSTRUCTION_ID[31:7]),
    .OUT (IMM_GEN_OUT),
    .IMM_SEL (IMM_SEL)
);

control_unit ctrl_unit ( //doc lai sau
    .OPCODE (INSTRUCTION_ID[6:0]),
    .FUNCT3 (INSTRUCTION_ID[14:12]),
    .FUNCT7 (INSTRUCTION_ID[31:25]),
    .OP1SEL (OP1SEL),
    .OP2SEL (OP2SEL),
    .REG_WRITE_EN (REG_WRITE_EN),
    .WB_SEL (WB_SEL),
    .ALUOP (ALUOP), 
    .BRANCH_JUMP (BRANCH_JUMP), 
    .IMM_SEL (IMM_SEL), 
    .READ_WRITE (READ_WRITE)
);

forwarding_unit fwd_unit ( //doc lai sau
    .ADDR1 (INSTRUCTION_ID[19:15]), 
    .ADDR2 (INSTRUCTION_ID[24:20]), 
    .WB_ADDR (WRITE_ADDRESS_WB), 
    .MEM_ADDR (WRITE_ADDRESS_MEM), 
    .EXE_ADDR (WRITE_ADDRESS_EX), 
    .OP1SEL (OP1SEL), 
    .OP2SEL (OP2SEL), 
    .OPCODE (INSTRUCTION_ID[6:0]),
    .DATA1IDSEL (DATA1IDSEL), 
    .DATA2IDSEL (DATA2IDSEL), 
    .DATA1ALUSEL (DATA1ALUSEL), 
    .DATA2ALUSEL (DATA2ALUSEL), 
    .DATA1BJSEL (DATA1BJSEL), 
    .DATA2BJSEL (DATA2BJSEL),
    .DATAMEMSEL (DATAMEMSEL)
);

stall stall_unit ( 
    .OPCODE (INSTRUCTION_ID[6:0]),
    .ADDR1 (INSTRUCTION_ID[19:15]),
    .ADDR2 (INSTRUCTION_ID[24:20]),
    .EXE_ADDR (WRITE_ADDRESS_EX),
    .READ_WRITE (READ_WRITE_EX),
    .STALL (STALL)
);

mux_2x1_32bit mux_id_1 (
    .IN0 (REG_FILE_OUT1),
    .IN1 (WB_MUX_OUT),
    .OUT (DATA1_ID),
    .SELECT (DATA1IDSEL)
 );

mux_2x1_32bit mux_id_2 (
    .IN0 (REG_FILE_OUT2),
    .IN1 (WB_MUX_OUT),
    .OUT (DATA2_ID),
    .SELECT (DATA2IDSEL)
);

id_ex_pipeline_reg id_ex_reg (
    .IN_INSTRUCTION (INSTRUCTION_ID[11:7]),
    .IN_PC (PC_OUT_ID),
    .IN_DATA1 (DATA1_ID), 
    .IN_DATA2 (DATA2_ID), 
    .IN_IMMEDIATE (IMM_GEN_OUT),
    .IN_DATA1ALUSEL (DATA1ALUSEL),
    .IN_DATA2ALUSEL (DATA2ALUSEL),
    .IN_DATA1BJSEL (DATA1BJSEL),
    .IN_DATA2BJSEL (DATA2BJSEL),
    .IN_ALU_OP (ALUOP),
    .IN_BRANCH_JUMP (BRANCH_JUMP),
    .IN_DATAMEMSEL (DATAMEMSEL),
    .IN_READ_WRITE (READ_WRITE),
    .IN_WB_SEL (WB_SEL),
    .IN_REG_WRITE_EN (REG_WRITE_EN),
    .OUT_INSTRUCTION (WRITE_ADDRESS_EX),
    .OUT_PC (PC_OUT_EX),
    .OUT_DATA1 (REG_FILE_OUT1_EX),
    .OUT_DATA2 (REG_FILE_OUT2_EX),
    .OUT_IMMEDIATE (IMM_GEN_OUT_EX), 
    .OUT_DATA1ALUSEL (DATA1ALUSEL_EX),
    .OUT_DATA2ALUSEL (DATA2ALUSEL_EX),
    .OUT_DATA1BJSEL (DATA1BJSEL_EX),
    .OUT_DATA2BJSEL (DATA2BJSEL_EX),
    .OUT_ALU_OP (ALUOP_EX),
    .OUT_BRANCH_JUMP (BRANCH_JUMP_EX),
    .OUT_DATAMEMSEL (DATAMEMSEL_EX),
    .OUT_READ_WRITE (READ_WRITE_EX),
    .OUT_WB_SEL (WB_SEL_EX),
    .OUT_REG_WRITE_EN (REG_WRITE_EN_EX),
    .CLK (CLK), 
    .RST_N (RST_N),
    .PC_SEL (PC_SEL),
    .FLUSH_E (STALL)
);

// Instruction execution stage
mux_4x1_32bit mux_ex_alu_1 (
    .IN0 (REG_FILE_OUT1_EX), 
    .IN1 (PC_OUT_EX), 
    .IN2 (WB_MUX_OUT), 
    .IN3 (ALU_OUT_MEM), 
    .OUT (OPERAND1), 
    .SELECT (DATA1ALUSEL_EX)
);

mux_4x1_32bit mux_ex_alu_2 (
    .IN0 (REG_FILE_OUT2_EX), 
    .IN1 (IMM_GEN_OUT_EX), 
    .IN2 (WB_MUX_OUT), 
    .IN3 (ALU_OUT_MEM), 
    .OUT (OPERAND2), 
    .SELECT (DATA2ALUSEL_EX)
);
    
alu alu_unit (
    .DATA1 (OPERAND1), 
    .DATA2 (OPERAND2), 
    .RESULT (ALU_OUT), 
    .SELECT (ALUOP_EX)
);

mux_4x1_32bit mux_ex_bj_1 (
    .IN0 (REG_FILE_OUT1_EX), 
    .IN1 (REG_FILE_OUT1_EX), 
    .IN2 (WB_MUX_OUT), 
    .IN3 (ALU_OUT_MEM), 
    .OUT (MUX_EX_BJ1_OUT), 
    .SELECT (DATA1BJSEL_EX)
);   

mux_4x1_32bit mux_ex_bj_2 (
    .IN0 (REG_FILE_OUT2_EX), 
    .IN1 (REG_FILE_OUT2_EX), 
    .IN2 (WB_MUX_OUT), 
    .IN3 (ALU_OUT_MEM), 
    .OUT (MUX_EX_BJ2_OUT), 
    .SELECT (DATA2BJSEL_EX)
);       

mux_4x1_32bit mux_ex (
    .IN0 (REG_FILE_OUT2_EX), 
    .IN1 (REG_FILE_OUT2_EX), 
    .IN2 (WB_MUX_OUT), 
    .IN3 (ALU_OUT_MEM), 
    .OUT (MUX_EX_OUT), 
    .SELECT (DATA2BJSEL_EX)
);         

bj_detect bj_unit (
    .BRANCH_JUMP (BRANCH_JUMP_EX), 
    .DATA1 (MUX_EX_BJ1_OUT), 
    .DATA2 (MUX_EX_BJ2_OUT), 
    .PC_SEL_OUT (PC_SEL)    
);

ex_mem_pipeline_reg ex_mem_reg (
    .IN_INSTRUCTION (WRITE_ADDRESS_EX),
    .IN_PC (PC_OUT_EX),
    .IN_ALU_RESULT (ALU_OUT), 
    .IN_DATA2 (MUX_EX_OUT), 
    .IN_IMMEDIATE (IMM_GEN_OUT_EX),
    .IN_DATAMEMSEL (DATAMEMSEL_EX),
    .IN_READ_WRITE (READ_WRITE_EX),
    .IN_WB_SEL (WB_SEL_EX),
    .IN_REG_WRITE_EN (REG_WRITE_EN_EX),
    .OUT_INSTRUCTION (WRITE_ADDRESS_MEM),
    .OUT_PC (PC_OUT_MEM),
    .OUT_ALU_RESULT (ALU_OUT_MEM),
    .OUT_DATA2 (MUX_EX_OUT_MEM),
    .OUT_IMMEDIATE (IMM_GEN_OUT_MEM), 
    .OUT_DATAMEMSEL (DATAMEMSEL_MEM),
    .OUT_READ_WRITE (READ_WRITE_EN),
    .OUT_WB_SEL (WB_SEL_MEM),
    .OUT_REG_WRITE_EN (REG_WRITE_EN_MEM),
    .CLK (CLK), 
    .RST_N (RST_N)
);

// Memory stage
adder_32bit pc_4_adder_wb (
    .IN (PC_OUT_MEM), 
    .OUT (PC_4_WB_OUT)
);

mux_2x1_32bit mux_mem (
    .IN0 (MUX_EX_OUT_MEM),
    .IN1 (WB_MUX_OUT),
    .OUT (lsu_wdata),
    .SELECT (DATAMEMSEL_MEM)    
);

load_store_unit LSU (
    .CLK (CLK),
    .RST_N (RST_N),
    .data_req_o (data_req_o),
    .data_gnt_i (data_gnt_i),
    .data_rvalid_i (data_rvalid_i),
    .data_bus_err_i (data_err_i),
    .data_addr_o (data_addr_o),
    .data_we_o (data_we_o),
    .data_be_o (data_be_o),
    .data_wdata_o (data_wdata_o),
    .data_wdata_intg_o (data_wdata_intg_o),
    .data_rdata_i (data_rdata_i),
    .data_rdata_intg_i (data_rdata_intg_i),
    .READ_WRITE (READ_WRITE_EN),
    .lsu_wdata_i (lsu_wdata), 
    .lsu_rdata_o (lsu_rdata),          
    .lsu_rdata_valid_o (),
    .adder_result_ex_i (ALU_OUT_MEM),    
    .addr_incr_req_o (),
    .addr_last_o (),
    .lsu_req_done_o (),       
    .lsu_resp_valid_o (), 
    .load_err_o (),
    .load_resp_intg_err_o (),  
    .store_err_o (),
    .store_resp_intg_err_o (), 
    .busy_o (),
    .perf_load_o (),
    .perf_store_o ()
);

mem_wb_pipeline_reg mem_wb_reg (
    .IN_INSTRUCTION (WRITE_ADDRESS_MEM),
    .IN_PC_4 (PC_4_WB_OUT),
    .IN_ALU_RESULT (ALU_OUT_MEM), 
    .IN_IMMEDIATE (IMM_GEN_OUT_MEM),
    .IN_DMEM_OUT (lsu_rdata),
    .IN_WB_SEL (WB_SEL_MEM),
    .IN_REG_WRITE_EN (REG_WRITE_EN_MEM),
    .OUT_INSTRUCTION (WRITE_ADDRESS_WB),
    .OUT_PC_4 (PC_4_WB_OUT_WB),
    .OUT_ALU_RESULT (ALU_OUT_WB),
    .OUT_IMMEDIATE (IMM_GEN_OUT_WB), 
    .OUT_DMEM_OUT (READDATA_WB),
    .OUT_WB_SEL (WB_SEL_WB),
    .OUT_REG_WRITE_EN (REG_WRITE_EN_WB),
    .CLK (CLK), 
    .RST_N (RST_N)
);

// Writeback stage
mux_4x1_32bit wb_mux (
    .IN0 (ALU_OUT_WB), 
    .IN1 (READDATA_WB), 
    .IN2 (IMM_GEN_OUT_WB), 
    .IN3 (PC_4_WB_OUT_WB), 
    .OUT (WB_MUX_OUT), 
    .SELECT (WB_SEL_WB)
);    

endmodule