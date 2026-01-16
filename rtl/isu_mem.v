//clocked read-only rom with async reset
module isu_mem #(
	parameter MEM_A_WIDTH = 8,
	parameter D_WIDTH = 32,
	parameter A_WIDTH = 32
)
(
	input 						clk,
	input 						en,
	input 						rst,
	input [A_WIDTH-1:0] 		addr,
	output reg [D_WIDTH-1:0] 	dout
);

	reg [D_WIDTH-1:0] mem [0:(1<<MEM_A_WIDTH)-1];

	wire [MEM_A_WIDTH-1:0] mem_index;
	assign mem_index = addr[MEM_A_WIDTH + 1 : 2];

	`ifdef LTB_ENV
		initial 
		begin
			$readmemh("../ltb/isu_mem_test_stimuli.hex", mem);
		end
	`endif

	always @(posedge clk, posedge rst)
	begin
		if (rst)
			dout <= 32'h00000000;
		else if (en)
			dout <= mem[mem_index];
	end
endmodule