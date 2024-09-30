module reg_file (WRITE_DATA, DATA1, DATA2, WRITE_ADDRESS, DATA1_ADDRESS, DATA2_ADDRESS, WRITE_ENABLE, CLK, RST_N);

    input [31:0] WRITE_DATA;
    input [4:0] DATA1_ADDRESS, DATA2_ADDRESS, WRITE_ADDRESS;
    input WRITE_ENABLE, CLK, RST_N;
    output [31:0] DATA1, DATA2;

    reg [31:0] REGISTER[0:31];
    
    //read
    assign DATA1 = REGISTER[DATA1_ADDRESS];
    assign DATA2 = REGISTER[DATA2_ADDRESS];

    integer i;
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin  
            for (i = 0; i < 32; i = i + 1)
                REGISTER[i] <= 32'b0;
        end
        else if (WRITE_ENABLE && (WRITE_ADDRESS != 0)) begin
            REGISTER[WRITE_ADDRESS] <= WRITE_DATA;
        end
    end

endmodule