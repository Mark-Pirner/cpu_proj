//main block + control logic
`include "isu_mem.v"
`include "data_mem.v"
`include "pc.v"
`include "ir.v"
`include "alu.v"
`include "id_stage.v"

`define D_WIDTH         32
`define A_WIDTH         32
`define N_REGS          32
`define MEM_A_WIDTH     8
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

    pc # (
        .A_WIDTH(`A_WIDTH)
    )    
    pc_u(
        .clk(clk),
        .rst(rst),
        .en(pc_en),
        .next_pc(pc_next),
        .pc(pc_cur)
    );

    //instantiate isu memory
    wire[`D_WIDTH-1:0]                  cur_isu;

    isu_mem # (
        .MEM_A_WIDTH(`MEM_A_WIDTH),
        .D_WIDTH(`D_WIDTH)
    )    
    isu_mem_u(
        .clk(clk),
        .rst(rst),
        .addr(pc_cur), // get the instruction from the isu_mem indexed pc
        .dout(cur_isu)
    );

    //instantiate instruction register
    wire                                ir_en;
    assign ir_en = 1'b1;

    wire [`D_WIDTH-1:0]                 instr;
    wire [`RF_SIZE-1:0]                 rs2;
    wire [`RF_SIZE-1:0]                 rs1;
    wire [`RF_SIZE-1:0]                 rd;
    wire [`FUNCT_7_SIZE-1:0]            funct7;
    wire [`FUNCT_3_SIZE-1:0]            funct3;
    wire [`OP_CODE_SIZE-1:0]            opcode;

    ir # (
        .D_WIDTH(`D_WIDTH),
        .N_REGS(`N_REGS),
        .RF_SIZE(`RF_SIZE),
        .OP_CODE_SIZE(`OP_CODE_SIZE),
        .FUNCT_3_SIZE(`FUNCT_3_SIZE),
        .FUNCT_7_SIZE(`FUNCT_7_SIZE)
    )    
    ir_u(
        .clk(clk),
        .rst(rst),
        .en(ir_en),
        .isu(cur_isu),
        .instr(instr),
        .rs2(rs2),
        .rs1(rs1),
        .rd(rd),
        .funct7(funct7),
        .funct3(funct3),
        .op_code(opcode)
    );

    wire                                id_en;
    assign id_en = 1'b1;

    wire [`D_WIDTH-1:0]                 idex_rs1_val, idex_rs2_val, idex_imm;
    wire [`RF_SIZE-1:0]                 idex_rd;
    wire                                idex_reg_write, idex_alu_src_imm, idex_mem_we, idex_mem_re;
    wire [`OP_SIZE-1:0]                 idex_alu_op;
    wire ex_                            reg_write;
    wire [`RF_SIZE-1:0]                 ex_rd;

    assign ex_reg_write = idex_reg_write;
    assign ex_rd = idex_rd;

    wire                                wb_data;
    assign wb_data = idex_mem_re ? r_data : alu_out;


    id_stage #(
        .D_WIDTH(`D_WIDTH),
        .N_REGS(`N_REGS),
        .RF_SIZE(`RF_SIZE),
        .OP_SIZE(`OP_SIZE)
    ) id_stage_u (
        .clk(clk),
        .rst(rst),
        .en(id_en),

        .instr(instr),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),

        .wb_we(ex_reg_write && (ex_rd != 0)),
        .wb_rd(ex_rd),
        .wb_data(wb_data),

        .rs1_val_ex(idex_rs1_val),
        .rs2_val_ex(idex_rs2_val),
        .imm_ex(idex_imm),
        .rd_ex(idex_rd),
        .reg_write_ex(idex_reg_write),
        .alu_src_imm_ex(idex_alu_src_imm),
        .alu_op_ex(idex_alu_op),
        .mem_we_ex(idex_mem_we),
        .mem_re_ex(idex_mem_re)
    );

    //instantiate data mem
    //need to handle control logic for these signals
    wire [`D_WIDTH-1:0]                 r_data;

    data_mem # (
        .MEM_A_WIDTH(`MEM_A_WIDTH),
        .D_WIDTH(`D_WIDTH)
    )    
    data_mem_u(
        .clk(clk),
        .rst(rst),
        .we(idex_mem_we),
        .w_addr(alu_out),
        .w_data(idex_rs2_val),
        .re(idex_mem_re),
        .r_addr(alu_out),
        .r_data(r_data)
    );

    //instantiate alu, need to add control logic for immediate later
    wire [`D_WIDTH-1:0]                 a_in;
    assign a_in = idex_rs1_val;
    
    //modify b_in later to switch between imm and rs2_d
    wire [`D_WIDTH-1:0]                 b_in;
    assign b_in = idex_alu_src_imm ? idex_imm : idex_rs2_val;

    wire [`D_WIDTH-1:0]                 alu_out;
    wire                                alu_zero;

    alu # (
        .D_WIDTH(`D_WIDTH),
        .OP_SIZE(`OP_SIZE)
    )    
    alu_u(
        .alu_op(idex_alu_op),
        .a(a_in),
        .b(b_in),
        .y(alu_out),
        .zero(alu_zero)
    );
endmodule


