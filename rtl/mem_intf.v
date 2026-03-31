`include "data_mem.v"
module mem_intf #(
	parameter MEM_A_WIDTH = 8,
	parameter D_WIDTH = 32,
	parameter A_WIDTH =32
)
(
	input 						clk,
	input 						rst,
	//request
	input 						v_in,
	output wire 		 		r_in,
	input [A_WIDTH-1:0] 		mem_in_addr,
	input [D_WIDTH-1:0] 		mem_in_data,
	input 						mem_in_we,
	input 						mem_in_re,
	//response
	input 				 		r_out,
	output reg 					we_q,
	output reg					re_q,
	output reg	 				v_out,
	output wire [D_WIDTH-1:0] 	mem_out_rdata
);
	//manage requests
	reg [A_WIDTH-1:0] addr_q;
	reg [D_WIDTH-1:0] wdata_q;

	//instantiate data_mem
	wire [D_WIDTH-1:0] data_mem_rdata;
	data_mem #(
		.MEM_A_WIDTH(MEM_A_WIDTH),
		.D_WIDTH(D_WIDTH),
		.A_WIDTH(A_WIDTH)
	) data_mem_u (
		.clk(clk),
		.rst(rst),
		.we(we_q),
		.re(re_q), 
		.w_addr(we_q ? addr_q : {A_WIDTH{1'b0}}),
		.r_addr(re_q ? addr_q : {A_WIDTH{1'b0}}),
		.w_data(wdata_q),
		.r_data(data_mem_rdata)
	);

	//STATE LOGIC
	assign r_in = r_out | ~v_out;
	assign mem_out_rdata = data_mem_rdata;

	always @(posedge clk, negedge rst)
	begin
		if (rst)
		begin
			v_out <= 1'b0;
			addr_q <= 1'b0;
			wdata_q <= 1'b0;
			we_q <= 1'b0;
		end
		else
		begin
			if (r_in && v_in)
			begin
				addr_q 	<= mem_in_addr;
				wdata_q <= mem_in_data;
				we_q	<= mem_in_we;
				re_q 	<= mem_in_re;
				v_out 	<= 1'b1;
			end
			else if (v_out && r_out)
				v_out 	<= 1'b0;
		end
	end
endmodule
