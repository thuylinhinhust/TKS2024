module bj_detect (BRANCH_JUMP, DATA1, DATA2, PC_SEL_OUT);
    input [2:0] BRANCH_JUMP;
    input [31:0] DATA1, DATA2;
    output PC_SEL_OUT;

    wire eq, unsign_lt, sign_lt;
    reg lt;
    wire out1, out2, out3, out4, out5, out6, out7;

    assign eq = (DATA1 == DATA2) ? 1 : 0;
    assign unsign_lt = ($unsigned(DATA1) < $unsigned(DATA2)) ? 1 : 0;
    assign sign_lt = ($signed(DATA1) < $signed(DATA2)) ? 1 : 0;

    always @(BRANCH_JUMP or unsign_lt or sign_lt) begin
        case (BRANCH_JUMP[2:1])
            2'b11: lt = unsign_lt;
            default: lt = sign_lt;
        endcase
    end

    and logicAnd1(out1, !BRANCH_JUMP[2], !BRANCH_JUMP[1], BRANCH_JUMP[0], !eq);
    and logicAnd2(out2, !BRANCH_JUMP[2], BRANCH_JUMP[1], BRANCH_JUMP[0]);
    and logicAnd3(out3, BRANCH_JUMP[2], !BRANCH_JUMP[1], !BRANCH_JUMP[0], lt);
    and logicAnd4(out4, BRANCH_JUMP[2], !BRANCH_JUMP[1], BRANCH_JUMP[0], !lt);
    and logicAnd5(out5, BRANCH_JUMP[2], BRANCH_JUMP[1], !BRANCH_JUMP[0], lt);
    and logicAnd6(out6, BRANCH_JUMP[2], BRANCH_JUMP[1], BRANCH_JUMP[0], !lt);
    and logicAnd7(out7, !BRANCH_JUMP[2], !BRANCH_JUMP[1], !BRANCH_JUMP[0], eq);

    or logicOr(PC_SEL_OUT, out1, out2, out3, out4, out5, out6, out7);    

endmodule