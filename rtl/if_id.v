module if_id #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 32
)
(
    input                   clk,
    input                   rst,
    input                   en,

    input  [D_WIDTH-1:0]    instr_in,
    input  [A_WIDTH-1:0]    pc_in,

    output reg [D_WIDTH-1:0] instr_out,
    output reg [A_WIDTH-1:0] pc_out
);

    always @(posedge clk)
    begin
        if (rst) 
        begin
            instr_out <= 32'h00000000;
            pc_out    <= 32'b0;
        end
        else if (en) 
        begin
            instr_out <= instr_in;
            pc_out    <= pc_in;
        end
    end
endmodule
