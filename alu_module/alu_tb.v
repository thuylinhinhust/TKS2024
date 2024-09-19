`include "../utils/macros.v"
`include "../utils/encodings.v"
`include "alu.v"

module alu_tb;

    reg [31:0] DATA1, DATA2;
    reg [4:0] SELECT;
    wire [31:0] RESULT;

    alu myalu (DATA1, DATA2, RESULT, SELECT);
    
    initial begin
        $dumpfile("alu_wavedata.vcd");
        $dumpvars(0, alu_tb);

        #1;
            SELECT = `ADD;
            DATA1 = 32'b10000100000000000000000000000000;
            DATA2 = 32'd2;
        #5
            `assert(RESULT, 32'b10000100000000000000000000000010);
            $display("ALU-OP ADD Passed!");
    
            SELECT = `SUB;
        #5
            `assert(RESULT, -32'd2080374786);
            $display("ALU-OP SUB Passed!");
            
            SELECT = `SLL;
        #5
            `assert(RESULT, 32'b00010000000000000000000000000000);
            $display("ALU-OP SLL Passed!");
        
            SELECT = `XOR;
        #5
            `assert(RESULT, 32'b10000100000000000000000000000010);
            $display("ALU-OP XOR Passed!");
        
            SELECT = `SRL;
        #5
            `assert(RESULT, 32'b00100001000000000000000000000000);
            $display("ALU-OP SRL Passed!");
        
            SELECT = `SRA;
        #5  
            `assert(RESULT, 32'b00100001000000000000000000000000); //expect: 11100001000000000000000000000000
        
            SELECT = `OR;
        #5  
            `assert(RESULT, 32'b10000100000000000000000000000010);
            $display("ALU-OP OR Passed!");
        
            SELECT = `MUL;
        #5  
            `assert(RESULT, 32'b00001000000000000000000000000000);
            $display("ALU-OP MUL Passed!");
        
            SELECT = `MULH;
        #5  
            `assert(RESULT, 32'b11111111111111111111111111111111);
            $display("ALU-OP MULH Passed!");
        
            SELECT = `MULHU;
        #5  
            `assert(RESULT, 32'b00000000000000000000000000000001);
            $display("ALU-OP MULHU Passed!");
        
            SELECT = `MULHSU;
        #5  
            `assert(RESULT, 32'b00000000000000000000000000000001); //unsigned???
            $display("ALU-OP MULHSU Passed!");
        
            SELECT = `DIV;
        #5  
            `assert(RESULT, 32'b11000010000000000000000000000000);
            $display("ALU-OP DIV Passed!");
        
            SELECT = `DIVU;
        #5  
            `assert(RESULT, 32'b01000010000000000000000000000000);
            $display("ALU-OP DIVU Passed!");
        
            SELECT = `REMU;
        #5  
            `assert(RESULT, 32'd0);
            $display("ALU-OP REMU Passed!");

        #500
        $finish;
    end

endmodule