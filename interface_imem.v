module interface_imem (
    //interface with cpu
    input [31:0] PC,
    output [31:0] instruction,

    //interface with ram
    output instr_req_o,
    input instr_gnt_i,
    input instr_rvalid_i,
    output [31:0] instr_addr_o,
    input [31:0] instr_rdata_i,
    input [6:0] instr_rdata_intg_i,
    input instr_err_i
);

wire [6:0] unused_intg_i;
wire unused_err_i;

// unused input signal
assign unused_intg_i = instr_rdata_intg_i;
assign unused_err_i = instr_err_i;

assign instr_req_o = (PC == -4) ? 0 : 1;
assign instr_addr_o = PC;
assign instruction = (instr_gnt_i & instr_rvalid_i) ? instr_rdata_i : 32'bx;

endmodule