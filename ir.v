//funct7 [31:25], rs2 [24:20], rs1 [19:15], funct3[14:12], rd[11:7], opcode[6:0]
//instruction register, pipeline (future proof)
module ir #(
	parameter D_WIDTH = 32,
	parameter N_REGS  = 32,
	parameter RF_SIZE = $clog2(N_REGS),
	parameter OP_CODE_SIZE = 7,
	parameter FUNCT_3_SIZE = 3, 
	parameter FUNCT_7_SIZE = 7
)
(
	input clk,
	input rst,
	input en,
	input [D_WIDTH-1:0] isu,
	output reg [RF_SIZE-1:0] rs2,
	output reg [RF_SIZE-1:0] rs1,
	output reg [RF_SIZE-1:0] rd
	output reg [FUNCT_7_SIZE-1:0] funct7,
	output reg [FUNCT_3_SIZE-1:0] funct3,
	output reg [OP_CODE_SIZE-1:0] op_code
)
	always @(posedge clk, posedge rst)
	begin
		if (rst)
		begin
			rs2 <= 0;
			rs1 <= 0;
			rd <= 0;
			funct7 <= 0;
			funct3 <= 0;
			op_code <= 0;
		end
		else if (en)
		begin
			funct7 <= isu[31:25];
			rs2 <= isu[24:20];
			rs1 <= isu[19:15];
			funct3 <= [14:12];
			rd <=  isu[11:7];
			op_code <= isu[6:0];
		end
	end
endmodule