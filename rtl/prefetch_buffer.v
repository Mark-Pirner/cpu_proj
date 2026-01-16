module prefetch_buf #(
    parameter D_WIDTH = 32
)
(
    input                    clk,
    input                    rst,

    input                    in_valid,
    input  [D_WIDTH-1:0]     in_instr,

    input                    out_ready,

    output reg               out_valid,
    output reg [D_WIDTH-1:0] out_instr
);

    always @(posedge clk) 
    begin
        if (rst) 
        begin
            out_valid <= 1'b0;
            out_instr <= 32'h00000000;
        end 
        else 
        begin
            case ({in_valid, out_ready, out_valid})
                3'b100: 
                begin
                    out_instr <= in_instr;
                    out_valid <= 1'b1;
                end

                3'b011: 
                begin
                    out_valid <= 1'b0;
                end

                3'b111: 
                begin
                    out_instr <= in_instr;
                    out_valid <= 1'b1;
                end

                default: 
                begin
                end
            endcase
        end
    end
endmodule
