//alu code

module alu #(
    parameter D_WIDTH = 32,
    parameter OP_SIZE = 4
)
(
    input [OP_SIZE-1:0] alu_op, //operand select
    input [D_WIDTH-1:0] a, //operand 1 (from RF)
    input [D_WIDTH-1:0] b, //operand 2 (from RF or immediate)
    output [D_WIDTH-1:0] y,
    output zero
)
    always @(*)
    begin
        case (alu_op)
            4'b0000:    y = a + b; 
            4'b0001:    y = a - b;
            4'b0010:    y = a & b;
            4'b0011:    y = a | b;
            4'b0100:    y = a ^ b;
            4'b0101:    y = ($signed(a) < $signed(b)) ? 1 : 0;
            4'b0110:    y = a << b[4:0];
            4'b0111:    y = a >> b[4:0];
            default:    y <= 0;
        endcase
    end

    assign zero = (y == 0'b1);

endmodule