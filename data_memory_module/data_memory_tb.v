`include "data_memory.v"

module data_memory_tb();

    reg CLK, RESET;
    reg [3:0] READ_WRITE_EN;
    reg [31:0] ADDRESS;
    reg [31:0] WRITEDATA;
    wire [31:0] READDATA;

    integer j;
    
    data_memory my_data_memory (
    .CLK (CLK), 
    .RESET (RESET), 
    .READ_WRITE_EN (READ_WRITE_EN), 
    .ADDRESS (ADDRESS), 
    .WRITEDATA (WRITEDATA), 
    .READDATA (READDATA)    
);

    initial begin
        $dumpfile("data_memory_wavedata.vcd");
        $dumpvars(0, data_memory_tb);
        for(j = 0; j < 100; j = j + 1) $dumpvars(0, my_data_memory.MEM_ARRAY[j]);

        CLK = 1'b0;
        RESET = 1'b0;

        READ_WRITE_EN = 4'b1111;
        ADDRESS = 32'h00000000;
        WRITEDATA = 32'h1234ABCD;
        
        #5;
        RESET = 1'b1;
        #4;
        RESET = 1'b0;
        
        #10;
        READ_WRITE_EN = 4'b1010;
        ADDRESS = 32'h00000004;
        WRITEDATA = 32'hABCD1235;

        #10;
        READ_WRITE_EN = 4'b1010;
        ADDRESS = 32'h00000000;
        WRITEDATA = 32'hABCD1236;

        #10;
        READ_WRITE_EN = 4'b1000;
        ADDRESS = 32'h00000000;
        WRITEDATA = 32'hABCD1233;

        #10;
        READ_WRITE_EN = 4'b1101;
        ADDRESS = 32'h00000000;
        WRITEDATA = 32'hABCD1224;

        #10;
        READ_WRITE_EN = 4'b1110;
        ADDRESS = 32'h00000004;
        WRITEDATA = 32'h32341234;

        #10;
        READ_WRITE_EN = 4'b1111;
        ADDRESS = 32'h00000008;
        WRITEDATA = 32'h32341234;

        #10;
        READ_WRITE_EN = 4'b1100;
        ADDRESS = 32'h00000008;
        WRITEDATA = 32'h32331234;

        #500;
        $finish;
    end

    // clock genaration.
    always begin
        #4 CLK = ~CLK;
    end

endmodule