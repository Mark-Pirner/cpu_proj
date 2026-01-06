module mem_wb #(
    parameter D_WIDTH = 32,
    parameter RF_SIZE = 5
)(
    input                           clk,
    input                           rst,

    input   [D_WIDTH-1:0]           alu_out_mem,
    input   [D_WIDTH-1:0]           r_data_mem,
    input   [RF_SIZE-1:0]           rd_mem,
    input                           reg_write_mem,
    input                           mem_to_reg_mem,

    output reg [D_WIDTH-1:0]        alu_out_wb,
    output reg [D_WIDTH-1:0]        mem_data_wb,
    output reg [RF_SIZE-1:0]        rd_wb,
    output reg                      reg_write_wb,
    output reg                      mem_to_reg_wb
);
    always @(posedge clk or posedge rst) 
    begin
        if (rst) 
        begin
            alu_out_wb   <= {D_WIDTH{1'b0}};
            mem_data_wb  <= {D_WIDTH{1'b0}};
            rd_wb        <= {RF_SIZE{1'b0}};
            reg_write_wb <= 1'b0;
            mem_to_reg_wb <= 1'b0;
        end 
        else 
        begin
            alu_out_wb   <= alu_out_mem;
            mem_data_wb  <= r_data_mem;
            rd_wb        <= rd_mem;
            reg_write_wb <= reg_write_mem;
            mem_to_reg_wb <= mem_to_reg_mem;
        end
    end
endmodule