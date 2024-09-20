module instruction_memory (ADDRESS, READDATA);

input [31:0] ADDRESS;
output [31:0] READDATA;

//Declare memory array 1024x8-bits 
reg [7:0] MEM_ARRAY [0:1023];

//Read
assign READDATA[7:0]     =  MEM_ARRAY[ADDRESS];
assign READDATA[15:8]    =  MEM_ARRAY[ADDRESS+1];
assign READDATA[23:16]   =  MEM_ARRAY[ADDRESS+2];
assign READDATA[31:24]   =  MEM_ARRAY[ADDRESS+3];

endmodule