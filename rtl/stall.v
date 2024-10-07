module stall (OPCODE, ADDR1, ADDR2, EXE_ADDR, READ_WRITE, STALL);

input [6:0] OPCODE;
input [4:0] ADDR1, ADDR2, EXE_ADDR;
input [3:0] READ_WRITE;
output reg STALL;

wire LB, LH, LW, LBU, LHU, LOAD;

assign LB = READ_WRITE[3] & !READ_WRITE[2] & !READ_WRITE[1] & !READ_WRITE[0];
assign LH = READ_WRITE[3] & !READ_WRITE[2] & !READ_WRITE[1] & READ_WRITE[0];
assign LW = READ_WRITE[3] & !READ_WRITE[2] & READ_WRITE[1] & !READ_WRITE[0];
assign LBU = READ_WRITE[3] & READ_WRITE[2] & !READ_WRITE[1] & !READ_WRITE[0];
assign LHU = READ_WRITE[3] & READ_WRITE[2] & !READ_WRITE[1] & READ_WRITE[0];

assign LOAD = LB | LH | LW | LBU | LHU;

wire JALR, B_TYPE, I_TYPE, R_TYPE, LOAD_ID, STORE, INST_MASK1, INST_MASK2;

and jalr (JALR, OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], OPCODE[2], OPCODE[1], OPCODE[0]);
and b_type (B_TYPE, OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and i_type (I_TYPE, !OPCODE[6], !OPCODE[5], OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and r_type (R_TYPE, !OPCODE[6], OPCODE[5], OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and load (LOAD_ID, !OPCODE[6], !OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);
and store (STORE, !OPCODE[6], OPCODE[5], !OPCODE[4], !OPCODE[3], !OPCODE[2], OPCODE[1], OPCODE[0]);

//instruction have rs1 at ID stage
assign INST_MASK1 = (JALR | B_TYPE | I_TYPE | R_TYPE | LOAD_ID | STORE);
//instruction have rs2 at ID stage
assign INST_MASK2 = (B_TYPE | R_TYPE);

initial
begin
    STALL = 1'b0;
end

always @(ADDR1, ADDR2, EXE_ADDR, LOAD)
begin
    if (LOAD && (((ADDR1 == EXE_ADDR) && INST_MASK1) || ((ADDR2 == EXE_ADDR) && INST_MASK2)))
        STALL = 1'b1;
    else
        STALL = 1'b0;
end
 
endmodule