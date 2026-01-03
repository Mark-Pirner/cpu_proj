//main block + control logic
`include "isu_mem.v"
`include "data_mem.v"
`include "pc.v"
`include "ir.v"
`include "rf.v"
`include "alu.v"

`define D_WIDTH         32
`define A_WIDTH         32
`define N_REGS          32
`define RF_SIZE         $clog2(`N_REGS)
`define OP_CODE_SIZE    7
`define FUNCT_3_SIZE    3
`define FUNCT_7_SIZE    7
`define OP_SIZE         4

module top_inst(
    input clk,
    input rst
);

    //instanstaite pc register 
    wire                                pc_en;
    wire [`A_WIDTH-1:0]                 pc_cur;
    wire [`A_WIDTH-1:0]                 pc_next;

    assign pc_en = 1'b1;
    assign pc_next = pc_cur + 4; //advance a word

    pc pc_u(
        .clk(clk),
        .rst(rst),
        .en(pc_en),
        .next_pc(pc_next),
        .pc(pc_cur)
    );

    //instantiate isu memory
    wire[`D_WIDTH-1:0]                  cur_isu;

    isu_mem isu_mem_u(
        .clk(clk),
        .rst(rst),
        .addr(pc_cur), // get the instruction from the isu_mem indexed pc
        .dout(cur_isu)
    );

    //instantiate instruction register
    wire                                ir_en;
    assign ir_en = 1'b1;

    wire [`RF_SIZE-1:0]                 rs2;
    wire [`RF_SIZE-1:0]                 rs1;
    wire [`RF_SIZE-1:0]                 rd;
    wire [`FUNCT_7_SIZE-1:0]            funct7;
    wire [`FUNCT_3_SIZE-1:0]            funct3;
    wire [`OP_CODE_SIZE-1:0]            opcode;

    ir ir_u(
        .clk(clk),
        .rst(rst),
        .en(ir_en),
        .isu(cur_isu),
        .rs2(rs2),
        .rs1(rs1),
        .rd(rd),
        .funct7(funct7),
        .funct3(funct3),
        .op_code(opcode)
    );

    //instantiate register filer
    wire                                rf_we;   
    wire [`D_WIDTH-1:0]                 w_data;                        
    assign rf_we = 1'b1; //update logic

    wire [`D_WIDTH-1:0]                 rs2_d;
    wire [`D_WIDTH-1:0]                 rs1_d;

    rf rf_u(
        .clk(clk),
        .rst(rst),
        .we(rf_we),
        .w_addr(rd),
        .w_data(w_data),
        .rs2(rs2),
        .rs1(rs1),
        .rs2_d(rs2_d),
        .rs1_d(rs1_d)
    );

    //instantiate data mem
    wire [`A_WIDTH-1:0]                 data_mem_w_addr;
    assign data_mem_w_addr = {25'b0, rd, 2'b0};
    wire                                re;
    assign re = 1'b0;

    //need to handle control logic for these signals
    wire [`A_WIDTH-1:0]                 r_addr;
    wire [`D_WIDTH-1:0]                 r_data;

    data_mem data_mem_u(
        .clk(clk),
        .rst(rst),
        .we(rf_we),
        .w_addr(data_mem_w_addr),
        .w_data(w_data),
        .re(re),
        .r_addr(r_addr),
        .r_data(r_data)
    )

    //instantiate alu, need to add control logic for immediate later
    wire [`D_WIDTH-1:0]                 a_in;
    assign a_in = rs1_d;
    
    //modify b_in later to switch between imm and rs2_d
    wire [`D_WIDTH-1:0]                 b_in;
    assign b_in = rs2_d;

    //add case statement for cur_op based on ir decode
    wire [`OP_SIZE-1:0]                 cur_op;
    assign cur_op = 4'b1111;

    wire [`D_WIDTH-1:0]                 alu_out;
    wire                                alu_zero;

    alu alu_u(
        .alu_op(cur_op),
        .a(a_in),
        .b(b_in),
        .y(alu_out),
        .zero(alu_zero)
    );
endmodule


