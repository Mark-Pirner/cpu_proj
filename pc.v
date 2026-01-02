//basic program counter
module pc #(
	parameter D_WIDTH = 32
)
(
	input clk,
	input rst,
	input en,
	input [D_WIDTH-1:0] next_pc,
	output reg pc
)
	always @(posedge clk)
	begin
		if (rst)
			pc <= 0;
		else if (en)
			pc <= next_pc;
	end
endmodule