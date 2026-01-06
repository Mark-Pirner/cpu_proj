module ex_mem #(
    parameter D_WIDTH = 32,
    parameter RF_SIZE = 5
)(
    input                   clk,
    input                   rst,

    //from ex
    input   [D_WIDTH-1:0]   alu_out_ex,
    input   [D_WIDTH-1:0]   rs2_val_ex,
    input   [RF_SIZE-1:0]   rd_ex,
    input                   reg_write_ex,
    input                   mem_we_ex,
    input                   mem_re_ex,
    input                   mem_to_reg_ex,
    //to mem
    output reg  [D_WIDTH-1:0]   alu_out_mem,
    output reg  [D_WIDTH-1:0]   rs2_val_mem,
    output reg  [RF_SIZE-1:0]   rd_mem,
    output reg                  reg_write_mem,
    output reg                  mem_we_mem,
    output reg                  mem_re_mem,
    output reg                  mem_to_reg_mem
);

    always @(posedge clk or posedge rst) 
    begin
        if (rst) 
        begin
            alu_out_mem     <= {D_WIDTH{1'b0}};
            rs2_val_mem     <= {D_WIDTH{1'b0}};
            rd_mem          <= {RF_SIZE{1'b0}};
            reg_write_mem   <= 1'b0;
            mem_we_mem      <= 1'b0;
            mem_re_mem      <= 1'b0;
            mem_to_reg_mem  <= 1'b0;

        end 
        else 
        begin
            alu_out_mem     <= alu_out_ex;
            rs2_val_mem     <= rs2_val_ex;
            rd_mem          <= rd_ex;
            reg_write_mem   <= reg_write_ex;
            mem_we_mem      <= mem_we_ex;
            mem_re_mem      <= mem_re_ex;
            mem_to_reg_mem  <= mem_to_reg_ex;
        end
    end
endmodule