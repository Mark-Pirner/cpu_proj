//clocked dual port ram with write-through and async reset
module data_mem #(
	parameter MEM_A_WIDTH = 8,
	parameter D_WIDTH = 32,
	parameter A_WIDTH =32
)
(
	`ifdef LTB_EN
		initial begin
			$readmemh("data_mem_test_stimuli.hex", mem);
		end
	`endif

	input 						clk,
	input 						rst,
	input we,
	input [A_WIDTH-1:0] 		w_addr,
	input [D_WIDTH-1:0] 		w_data,
	input 						re,
	input [A_WIDTH-1:0] 		r_addr,
	output reg [D_WIDTH-1:0] 	r_data
);
	reg [D_WIDTH-1:0] mem [0:(1<<MEM_A_WIDTH)-1];
	
	wire [MEM_A_WIDTH-1:0] mem_w_index;
	assign mem_w_index = w_addr[MEM_A_WIDTH + 1 : 2];
	
	wire [MEM_A_WIDTH-1:0] mem_r_index;
	assign mem_r_index = r_addr [MEM_A_WIDTH + 1 : 2];

	always @(posedge clk, posedge rst)
	begin
		if (rst)
			r_data <= 0;
		else
		begin	
			if (we)
                mem[mem_w_index] <= w_data;
            if (re)
                r_data <= (we && (w_addr == r_addr)) ? w_data : mem[mem_r_index];
		end
	end
endmodule