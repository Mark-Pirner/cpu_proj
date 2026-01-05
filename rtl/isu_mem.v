//clocked read-only ram with async reset
module isu_mem #(
	parameter MEM_A_WIDTH = 8,
	parameter D_WIDTH = 32
)
(
	input clk,
	input rst,
	input [31:0] addr,
	output reg [D_WIDTH-1:0] dout
);

	reg [D_WIDTH-1:0] mem [0:(1<<A_WIDTH)-1];

	wire [MEM_A_WIDTH-1:0] mem_index;
	assign mem_index = addr[MEM_A_WIDTH + 1 : 2];

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
			dout <= [mem_index];
	end
endmodule