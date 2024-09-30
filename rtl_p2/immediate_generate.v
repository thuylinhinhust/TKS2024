`include "encodings.v"

module immediate_generate (IN, OUT, IMM_SEL);

    input [24:0] IN;            // instruction[31:7]
    input [2:0] IMM_SEL;        // immediate select op
    output reg [31:0] OUT;      // sign extended 32-bit value

    wire [31:0] U_OUT,
                J_OUT,
                B_OUT,
                S_OUT,
                I_SIGN_OUT,
                I_UNSIGN_OUT,
                I_SHIFT_OUT;

    // U Type Immediate -> LUI, AUIPC
    assign U_OUT[11:0] = {12{1'b0}};
    assign U_OUT[31:12] = IN[24:5];
               
    // J type Immediate -> JAL
    assign J_OUT[0] = 1'b0;        
    assign J_OUT[10:1] = IN[23:14];
    assign J_OUT[11] = IN[13];
    assign J_OUT[19:12] = IN[12:5];
    assign J_OUT[31:20] = {12{IN[24]}};

    // B Type Immediate -> beq, bne, blt, bgu, bltu, bgeu
    assign B_OUT[0] = 1'b0;
    assign B_OUT[4:1] = IN[4:1];
    assign B_OUT[10:5] = IN[23:18];
    assign B_OUT[11] = IN[0];
    assign B_OUT[31:12] = {20{IN[24]}};

    // S Type Immediate -> sw, sh, sb
    assign S_OUT[4:0] = IN[4:0] ;
    assign S_OUT[11:5] = IN[24:18];
    assign S_OUT[31:12] = {20{IN[24]}};

    //I Type Immediate
    assign I_SIGN_OUT[11:0] = IN[24:13] ;
    assign I_SIGN_OUT[31:12] = {20{IN[24]}};

    //IU --> unsigned extend Immediate -> SLTIU
    assign I_UNSIGN_OUT[11:0] = IN[24:13] ;
    assign I_UNSIGN_OUT[31:12] = {20{1'b0}};

    // SFT -> slli, srli, srai 
    assign I_SHIFT_OUT[4:0] = IN[17:13];
    assign I_SHIFT_OUT[31:5] = {27{1'b0}};    
    
    always @(IMM_SEL or U_OUT or J_OUT or S_OUT or B_OUT or 
             I_SIGN_OUT or I_SHIFT_OUT or I_UNSIGN_OUT)
    begin
        case (IMM_SEL)
            `U_TYPE: OUT = U_OUT;
            `J_TYPE: OUT = J_OUT;
            `S_TYPE: OUT = S_OUT;
            `B_TYPE: OUT = B_OUT;     
            `I_SIGNED_TYPE: OUT = I_SIGN_OUT;          
            `I_SHIFT_TYPE: OUT = I_SHIFT_OUT;         
            `I_UNSIGNED_TYPE: OUT = I_UNSIGN_OUT;           
            default: OUT = 0 ;                         
        endcase
    end

endmodule