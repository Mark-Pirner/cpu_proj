//clocked read-only ram with async reset
module isu_mem #(
	parameter A_WIDTH = 8,
	parameter D_WIDTH = 32
)
(
	input clk,
	input rst,
	input [A_WIDTH-1:0] addr,
	output reg [D_WIDTH-1:0] dout
);

	reg [D_WIDTH-1:0] mem [0:(1<<A_WIDTH)-1];

	`ifdef LTB_EN
		initial begin
			$readmemh("isu_mem_test_stimuli.hex", mem);
		end
	1endif

	always @(posedge clk, posedge rst)
	begin
		if (rst)
			dout <= 0;
		else
			dout <= mem[addr];
	end
endmodule