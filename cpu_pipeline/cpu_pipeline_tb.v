`include "../data_memory_module/data_memory.v"
`include "../instruction_memory_module/instruction_memory.v"
`include "cpu_pipeline.v"

module cpu_pipeline_tb();

reg RESET, CLK;
wire [31:0] INST_MEM_READDATA;
wire [31:0] DATA_MEM_READDATA, DATA_MEM_WRITEDATA;
wire [31:0] INST_MEM_ADDRESS;
wire [31:0] DATA_MEM_ADDRESS;
wire [3:0] READ_WRITE_EN;
    
cpu_pipeline cpu (
    .RESET (RESET), 
    .CLK (CLK), 
    .INST_MEM_READDATA (INST_MEM_READDATA), 
    .DATA_MEM_READDATA (DATA_MEM_READDATA), 
    .DATA_MEM_WRITEDATA (DATA_MEM_WRITEDATA), 
    .INST_MEM_ADDRESS (INST_MEM_ADDRESS), 
    .DATA_MEM_ADDRESS (DATA_MEM_ADDRESS), 
    .READ_WRITE_EN (READ_WRITE_EN)
);

data_memory d_mem (
    .CLK (CLK), 
    .RESET (RESET), 
    .READ_WRITE_EN (READ_WRITE_EN), 
    .ADDRESS (DATA_MEM_ADDRESS), 
    .WRITEDATA (DATA_MEM_WRITEDATA), 
    .READDATA (DATA_MEM_READDATA)
);

instruction_memory inst_mem (
    .ADDRESS (INST_MEM_ADDRESS), 
    .READDATA (INST_MEM_READDATA)
);

integer j;

initial begin
    $readmemb("../instruction_memory_module/instr_mem.mem", inst_mem.MEM_ARRAY);
    $dumpfile("cpu_pipeline_wavedata.vcd");
    $dumpvars(0, cpu_pipeline_tb);
    for(j = 0; j < 32; j = j + 1) $dumpvars(0, cpu.register_file.REGISTER[j]);
    for(j = 0; j < 112; j = j + 1) $dumpvars(0, inst_mem.MEM_ARRAY[j]);
    for(j = 0; j < 112; j = j + 1) $dumpvars(0, d_mem.MEM_ARRAY[j]);

    CLK = 1'b0;
    RESET = 1'b0;

    #5;
    RESET = 1'b1;

    #5;
    RESET = 1'b0;
    
    #5000;
    $finish;
    
end

// clock genaration.
always begin
    #2 CLK = ~CLK;
end

endmodule