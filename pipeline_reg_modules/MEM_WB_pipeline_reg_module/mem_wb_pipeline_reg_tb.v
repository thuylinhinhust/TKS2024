`include "../../utils/macros.v" 
`include "mem_wb_pipeline_reg.v"

module mem_wb_pipeline_reg_tb;

    reg [4:0] IN_INSTRUCTION;
    reg [1:0] IN_WB_SEL;
    reg [31:0] IN_PC_4, IN_ALU_RESULT, IN_IMMEDIATE, IN_DMEM_OUT;             
    reg IN_REG_WRITE_EN, CLK, RESET, BUSYWAIT;

    wire [4:0] OUT_INSTRUCTION;
    wire [1:0] OUT_WB_SEL;
    wire [31:0] OUT_PC_4, OUT_ALU_RESULT, OUT_IMMEDIATE, OUT_DMEM_OUT; 
    wire OUT_REG_WRITE_EN;

    mem_wb_pipeline_reg my_mem_wb_pipeline_reg (IN_INSTRUCTION, 
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
                                                RESET,
                                                BUSYWAIT);
    
    initial begin
        
        CLK = 1'b0;
        RESET = 1'b0;
        BUSYWAIT = 1'b0;

        // set arbitrary values to inputs
        IN_INSTRUCTION = 5'd15; 
        IN_PC_4 = 32'd23;
        IN_ALU_RESULT = 32'd45;  
        IN_IMMEDIATE = 32'd56; 
        IN_DMEM_OUT = 32'd35;
        IN_WB_SEL = 2'b01;
        IN_REG_WRITE_EN = 1'b1;

        $dumpfile("mem_wb_pipeline_reg.vcd");
        $dumpvars(0, mem_wb_pipeline_reg_tb);

        /*
            Test 01 : RESET TEST
        */

        #1
        RESET = 1'b1;

        #5
        RESET = 1'b0;

        `assert(OUT_INSTRUCTION, 5'dx);
        `assert(OUT_PC_4, 32'dx);
        `assert(OUT_ALU_RESULT, 32'dx);
        `assert(OUT_IMMEDIATE, 32'dx);
        `assert(OUT_DMEM_OUT, 32'dx);
        `assert(OUT_WB_SEL, 2'bx);
        `assert(OUT_REG_WRITE_EN, 1'bx);

        $display("TEST 01 : RESET TEST Passed!");

        /* Test 01 ends here! */

        /*
            Test 02 : BUSYWAIT TEST 0
            Module should be able to write to Pipeline register when BUSYWAIT is set to 0
        */
        #1
        BUSYWAIT = 1'b0;

        // set arbitrary values to inputs
        IN_INSTRUCTION = 5'd15; 
        IN_PC_4 = 32'd23;
        IN_ALU_RESULT = 32'd45;  
        IN_IMMEDIATE = 32'd56; 
        IN_DMEM_OUT = 32'd35;
        IN_WB_SEL = 2'b01;
        IN_REG_WRITE_EN = 1'b1;

        @(posedge CLK) begin
            
            // wait for write to happen.
            #3
            `assert(OUT_INSTRUCTION, 5'd15);
            `assert(OUT_PC_4, 32'd23);
            `assert(OUT_ALU_RESULT, 32'd45);
            `assert(OUT_IMMEDIATE, 32'd56);
            `assert(OUT_DMEM_OUT, 32'd35);
            `assert(OUT_WB_SEL, 2'b01);
            `assert(OUT_REG_WRITE_EN, 1'b1);

            $display("TEST 02 : BUSYWAIT_0 TEST Passed!");

        end

        /* Test 02 ends here! */
        
        /*
            Test 03 : BUSYWAIT TEST 1
            Module should be not beable to write to Pipeline register when BUSYWAIT is set to 1
        */
        
        // set BUSYWAIT to 1
        #1
        BUSYWAIT = 1'b1;

        // set arbitrary values to inputs
        IN_INSTRUCTION = 5'd10; 
        IN_PC_4 = 32'd20;
        IN_ALU_RESULT = 32'd40;  
        IN_IMMEDIATE = 32'd50; 
        IN_DMEM_OUT = 32'd38;
        IN_WB_SEL = 2'b11;
        IN_REG_WRITE_EN = 1'b0;

        @(posedge CLK) begin
            
            // wait for write to happen.
            #3

            `assert(OUT_INSTRUCTION, 5'd15);
            `assert(OUT_PC_4, 32'd23);
            `assert(OUT_ALU_RESULT, 32'd45);
            `assert(OUT_IMMEDIATE, 32'd56);
            `assert(OUT_DMEM_OUT, 32'd35);
            `assert(OUT_WB_SEL, 2'b01);
            `assert(OUT_REG_WRITE_EN, 1'b1);

            $display("Test 03 : BUSYWAIT_1 TEST Passed!");

        end

        /* Test 03 ends here! */

        #100
        $finish;
    end

    // clock genaration.
    always begin
        #4 CLK = ~CLK;
    end

endmodule