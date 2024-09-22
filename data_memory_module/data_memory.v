module data_memory (CLK, RESET, READ_WRITE_EN, ADDRESS, WRITEDATA, READDATA);

input				CLK;
input           	RESET;
input [3:0]         READ_WRITE_EN;  
input [31:0]      	ADDRESS;
input [31:0]     	WRITEDATA;
output reg [31:0]	READDATA;

//Declare memory array 524288x8-bits
//512kByte
reg [7:0] MEM_ARRAY [524287:0];

wire [31:0] LW;
wire [15:0] LH;
wire [7:0] LB;

assign LW = {MEM_ARRAY[ADDRESS+3], MEM_ARRAY[ADDRESS+2], MEM_ARRAY[ADDRESS+1], MEM_ARRAY[ADDRESS]};
assign LH = {MEM_ARRAY[ADDRESS+1], MEM_ARRAY[ADDRESS]};
assign LB = MEM_ARRAY[ADDRESS];

always @(READ_WRITE_EN or LB or LH or LW)
begin
	begin
		case (READ_WRITE_EN[3:0])
		4'b1000: READDATA <= {{24{LB[7]}},LB};
		4'b1001: READDATA <= {{16{LH[15]}},LH};
		4'b1010: READDATA <= LW;
		4'b1100: READDATA <= {{24{1'b0}},LB};
		4'b1101: READDATA <= {{16{1'b0}},LH};
		default: READDATA <= 32'b0;
		endcase
	end
end

//Write
always @(posedge CLK)
begin
	if (READ_WRITE_EN[3]) begin
		case (READ_WRITE_EN[2:0])
		3'b011: MEM_ARRAY[ADDRESS] <= WRITEDATA[7:0];
		3'b110: {MEM_ARRAY[ADDRESS+1], MEM_ARRAY[ADDRESS]} <= WRITEDATA[15:0];
		3'b111: {MEM_ARRAY[ADDRESS+3], MEM_ARRAY[ADDRESS+2], MEM_ARRAY[ADDRESS+1], MEM_ARRAY[ADDRESS]} <= WRITEDATA;
	    endcase
	end
end

//Reset memory
integer i;

always @(posedge CLK or posedge RESET)
begin
    if (RESET)
    begin
        for (i = 0; i < 524288; i = i + 1)
            MEM_ARRAY[i] <= 8'b0;
    end
end

endmodule