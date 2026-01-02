//clocked dual port ram with write-through and async reset
module data_mem #(
	parameter A_WIDTH = 8,
	parameter D_WIDTH = 32
)
(
	`ifdef LTB_EN
		initial begin
			$readmemh("data_mem_test_stimuli.hex", mem);
		end
	`endif

	input clk,
	input rst,
	input we,
	input [A_WIDTH-1:0] w_addr,
	input [D_WIDTH-1:0] w_data,
	input re,
	input [A_WIDTH-1:0] r_addr,
	output reg [D_WIDTH-1:0] r_data
);
	reg [D_WIDTH] mem [0:(1<<A_WIDTH)-1];

	always @(posedge clk, posedge rst)
	begin
		if (rst)
			r_data <= 0;
		else
		begin	
			if (we)
                mem[w_addr] <= w_data;
            if (re)
                r_data <= (we && (w_addr == r_addr)) ? w_data : mem[r_addr];
		end
	end
endmodule