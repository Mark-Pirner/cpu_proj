//register filer, synchronous writes, combinational reads
module rf #(
	parameter D_WIDTH = 32,
	parameter N_REGS = 32,
	parameter REG_L2 = $clog2(N_REGS)
)
(
	input clk,
	input rst,
	input we,
	input [REG_L2-1:0] w_addr,
	input [D_WIDTH-1:0] w_data,
	input [REG_L2-1:0] rs2,
	input [REG_L2-1:0] rs1,
	output reg [D_WIDTH-1:0] rs2_d,
	output reg [D_WIDTH-1:0] rs1_d
)

	reg [D_WIDTH-1:0] mem [0:N_REGS-1];

	assign rs2_d = mem[rs2];
	assign rs1_d = mem[rs1];

	always @(posedge clk, posedge rst)
	begin
		if (rst)
		begin
    		for (i = 0; i < N_REGS; i = i+1)
        		mem[i] <= 0;
		end
		if (we)
			mem[w_addr] <= w_data; 
	end
endmodule