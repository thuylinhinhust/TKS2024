`include "../utils/encodings.v"

module alu (DATA1, DATA2, RESULT, SELECT);

    input [31:0] DATA1, DATA2;
    input [4:0] SELECT;     // func3: 3bits + func7[5] + func7[0]
    output reg [31:0] RESULT;
    
    wire [31:0] ADD_RESULT,
                SUB_RESULT,
                SLL_RESULT,
                SLT_RESULT,
                SLTU_RESULT,
                XOR_RESULT,
                SRL_RESULT,
                SRA_RESULT,
                OR_RESULT,
                AND_RESULT,
                DIV_RESULT,
                DIVU_RESULT,
                REM_RESULT,
                REMU_RESULT;
    
    wire [63:0] MUL_RESULT,
                MULHSU_RESULT,
                MULHU_RESULT;

    assign ADD_RESULT = DATA1 + DATA2;       // addition
    assign SUB_RESULT = DATA1 - DATA2;       // subtraction

    assign SLT_RESULT = ($signed(DATA1) < $signed(DATA2)) ? 1'b1 : 1'b0;         // set less than
    assign SLTU_RESULT = ($unsigned(DATA1) < $unsigned(DATA2)) ? 1'b1 : 1'b0;    // set less than unsigned
    
    assign AND_RESULT = DATA1 & DATA2;       // bitwise logical AND
    assign OR_RESULT = DATA1 | DATA2;        // bitwise logical OR
    assign XOR_RESULT = DATA1 ^ DATA2;       // bitwise logical XOR
    assign SLL_RESULT = DATA1 << DATA2;      // Logical Left Shift
    assign SRL_RESULT = DATA1 >> DATA2;      // Logical Right Shift
    assign SRA_RESULT = DATA1 >>> DATA2;     // Arithmetic Right shift
    
    // --> upper 32 bit
    assign MUL_RESULT = $signed(DATA1) * $signed(DATA2);       // Multiplication High Signed x Signed
    assign MULHU_RESULT = $unsigned(DATA1) * $unsigned(DATA2); // Multiplication High Unsigned x Unsigned
    assign MULHSU_RESULT = $signed(DATA1) * $unsigned(DATA2);  // Multiplication High Signed x UnSigned
    
    // DIV --> should round towards zero 
    assign DIV_RESULT = $signed(DATA1) / $signed(DATA2);       // Division
    assign DIVU_RESULT = $unsigned(DATA1) / $unsigned(DATA2);  // Division Unsigned
    assign REM_RESULT = $signed(DATA1) % $signed(DATA2);       // Remainder
    assign REMU_RESULT = $unsigned(DATA1) % $unsigned(DATA2);  // Remainder Unsigned

    always @(SELECT or ADD_RESULT or SUB_RESULT or SLL_RESULT or SLT_RESULT or 
             SLTU_RESULT or XOR_RESULT or SRL_RESULT or SRA_RESULT or OR_RESULT or 
             AND_RESULT or MUL_RESULT or MULHSU_RESULT or MULHU_RESULT or
             DIV_RESULT or DIVU_RESULT or REM_RESULT or REMU_RESULT)
    begin
        case (SELECT)
            `ADD: RESULT = ADD_RESULT; 
            `SUB: RESULT = SUB_RESULT; 
            `SLL: RESULT = SLL_RESULT; 
            `SLT: RESULT = SLT_RESULT; 
            `SLTU: RESULT = SLTU_RESULT; 
            `XOR: RESULT = XOR_RESULT; 
            `SRL: RESULT = SRL_RESULT; 
            `SRA: RESULT = SRA_RESULT; 
            `OR: RESULT = OR_RESULT; 
            `AND: RESULT = AND_RESULT; 
            `MUL: RESULT = MUL_RESULT[31:0];
            `MULH: RESULT = MUL_RESULT[63:32]; 
            `MULHSU: RESULT = MULHSU_RESULT[63:32]; 
            `MULHU: RESULT = MULHU_RESULT[63:32]; 
            `DIV: RESULT = DIV_RESULT; 
            `DIVU: RESULT = DIVU_RESULT; 
            `REM : RESULT = REM_RESULT; 
            `REMU: RESULT = REMU_RESULT; 
                
            default:  RESULT = 0 ;  
                                
        endcase
    end

endmodule