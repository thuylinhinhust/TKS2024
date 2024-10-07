module cpu_pipeline_top (CLK, RST_N, test_en_i, ram_cfg_i, hart_id_i, boot_addr_i, 
                        instr_req_o, instr_gnt_i, instr_rvalid_i, instr_addr_o, instr_rdata_i,
                        instr_rdata_intg_i, instr_err_i, data_req_o, data_gnt_i,
                        data_rvalid_i, data_we_o, data_be_o, data_addr_o, data_wdata_o,
                        data_wdata_intg_o, data_rdata_i, data_rdata_intg_i, data_err_i,
                        rvfi_valid, rvfi_order);

input CLK;
output

wire WRITE_DATA, DATA1, DATA2, WRITE_ADDRESS, DATA1_ADDRESS, DATA2_ADDRESS, WRITE_ENABLE;

cpu_pipeline my_cpu_pipeline (
    .CLK (CLK), 
    .RST_N (RST_N), 
    .test_en_i (test_en_i), 
    .ram_cfg_i (ram_cfg_i), 
    .hart_id_i (hart_id_i), 
    .boot_addr_i(boot_addr_i), 
    .instr_req_o (instr_req_o), 
    .instr_gnt_i (instr_gnt_i), 
    .instr_rvalid_i (instr_rvalid_i), 
    .instr_addr_o (instr_addr_o), 
    .instr_rdata_i (instr_rdata_i),
    .instr_rdata_intg_i (instr_rdata_intg_i), 
    .instr_err_i (instr_err_i), 
    .data_req_o (data_req_o), 
    .data_gnt_i (data_gnt_i),
    .data_rvalid_i (data_rvalid_i), 
    .data_we_o (data_we_o), 
    .data_be_o (data_be_o), 
    .data_addr_o (data_addr_o), 
    .data_wdata_o (data_wdata_o),
    .data_wdata_intg_o (data_wdata_intg_o), 
    .data_rdata_i (data_rdata_i), 
    .data_rdata_intg_i (data_rdata_intg_i), 
    .data_err_i (data_err_i),
    .WB_MUX_OUT (WRITE_DATA), 
    .REG_FILE_OUT1 (DATA1), 
    .REG_FILE_OUT2 (DATA2), 
    .WRITE_ADDRESS_WB (WRITE_ADDRESS), 
    .DATA1_ADDRESS (DATA1_ADDRESS), 
    .DATA2_ADDRESS (DATA2_ADDRESS), 
    .REG_WRITE_EN_WB (WRITE_ENABLE)
);

reg_file my_reg_file (
    .WRITE_DATA (WRITE_DATA), 
    .DATA1 (DATA1), 
    .DATA2 (DATA2), 
    .WRITE_ADDRESS (WRITE_ADDRESS), 
    .DATA1_ADDRESS (DATA1_ADDRESS), 
    .DATA2_ADDRESS (DATA2_ADDRESS), 
    .WRITE_ENABLE (WRITE_ENABLE), 
    .CLK (CLK), 
    .RST_N (RST_N) 
);

endmodule