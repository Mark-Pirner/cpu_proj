//main block + control logic
`include "isu_mem.v"
`include "data_mem.v"
`include "pc.v"
`include "ir.v"
`include "alu.v"
`include "id_stage.v"
`include "ex_mem.v"
`include "mem_wb.v"

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

    //pc wire
    wire                                pc_en;
    wire [`A_WIDTH-1:0]                 pc_cur;
    wire [`A_WIDTH-1:0]                 pc_next;

    //isu wires
    wire[`D_WIDTH-1:0]                  cur_isu;

    //ir wires
    wire                                ir_en;

    //idex wires
    wire                                id_en;
    wire [`RF_SIZE-1:0]                 idex_rs1;
    wire [`RF_SIZE-1:0]                 idex_rs2;
    wire [`D_WIDTH-1:0]                 idex_rs1_val;
    wire [`D_WIDTH-1:0]                 idex_rs2_val;
    wire [`D_WIDTH-1:0]                 idex_imm;
    wire [`RF_SIZE-1:0]                 idex_rd;
    wire                                idex_reg_write;
    wire                                idex_alu_src_imm;
    wire                                idex_mem_we;
    wire                                idex_mem_re;
    wire                                idex_mem_to_reg;
    wire [`OP_SIZE-1:0]                 idex_alu_op;

    //exmem wires
    wire [`D_WIDTH-1:0]                 exmem_alu_out;
    wire [`D_WIDTH-1:0]                 exmem_rs2_val;
    wire [`RF_SIZE-1:0]                 exmem_rd;
    wire                                exmem_reg_write;
    wire                                exmem_mem_we;
    wire                                exmem_mem_re;
    wire                                exmem_mem_to_reg;
    wire [`D_WIDTH-1:0]                 exmem_r_data;

    //memwb wires
    wire [`D_WIDTH-1:0]                 memwb_alu_out;
    wire [`D_WIDTH-1:0]                 memwb_mem_data;
    wire [`RF_SIZE-1:0]                 memwb_rd;
    wire                                memwb_reg_write;
    wire [`D_WIDTH-1:0]                 wb_data;
    wire                                memwb_mem_to_reg;

    //alu wires + fwd
    wire [`D_WIDTH-1:0]                 alu_a_w;
    wire [`D_WIDTH-1:0]                 rs2_fwd_w;
    wire [`D_WIDTH-1:0]                 alu_b_w;
    wire [`D_WIDTH-1:0]                 b_in;
    wire [`D_WIDTH-1:0]                 alu_out;
    wire                                alu_zero;

    //stall
    wire load_use_stall = idex_mem_re && (idex_rd != 0) && ((idex_rd == rs1 && rs1 != 5'b0) || (idex_rd == rs2 && rs2 != 5'b0));

    //----------------------------------INSTRUCTION FETCH--------------------------------------------
    //instantiate pc register 
    assign pc_en = ~load_use_stall;
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
    isu_mem # (
        .MEM_A_WIDTH(`MEM_A_WIDTH),
        .D_WIDTH(`D_WIDTH),
        .A_WIDTH(`A_WIDTH)
    )    
    isu_mem_u(
        .clk(clk),
        .rst(rst),
        .addr(pc_cur),
        .dout(cur_isu)
    );

    //instantiate instruction register
    assign ir_en = ~load_use_stall;

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

    //----------------------------------INSTRUCTION DECODE--------------------------------------------
    assign id_en = 1'b1;
    assign wb_data = memwb_mem_to_reg ? memwb_mem_data : memwb_alu_out;

    id_stage #(
        .D_WIDTH(`D_WIDTH),
        .N_REGS(`N_REGS),
        .RF_SIZE(`RF_SIZE),
        .OP_SIZE(`OP_SIZE)
    ) id_stage_u (
        .clk(clk),
        .rst(rst),
        .en(id_en),
        .bubble(load_use_stall),

        .instr(instr),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),

        .wb_we(memwb_reg_write && (memwb_rd != 0)),
        .wb_rd(memwb_rd),
        .wb_data(wb_data),

        .rs1_ex(idex_rs1),
        .rs2_ex(idex_rs2),
        .rs1_val_ex(idex_rs1_val),
        .rs2_val_ex(idex_rs2_val),
        .imm_ex(idex_imm),
        .rd_ex(idex_rd),
        .reg_write_ex(idex_reg_write),
        .alu_src_imm_ex(idex_alu_src_imm),
        .alu_op_ex(idex_alu_op),
        .mem_we_ex(idex_mem_we),
        .mem_re_ex(idex_mem_re),
        .mem_to_reg_ex(idex_mem_to_reg)
    );

    //----------------------------------INSTRUCTION EXEC--------------------------------------------
    //instantiate alu and add forwarding muxes
    assign alu_a_w = (exmem_reg_write && (exmem_rd != 0) && (exmem_rd == idex_rs1)) ? exmem_alu_out :
                 (memwb_reg_write && (memwb_rd != 0) && (memwb_rd == idex_rs1)) ? wb_data :
                 idex_rs1_val;

    assign rs2_fwd_w = (exmem_reg_write && (exmem_rd != 0) && (exmem_rd == idex_rs2)) ? exmem_alu_out :
                    (memwb_reg_write && (memwb_rd != 0) && (memwb_rd == idex_rs2)) ? wb_data :
                    idex_rs2_val;
    
    assign alu_b_w = idex_alu_src_imm ? idex_imm : rs2_fwd_w;

    alu # (
        .D_WIDTH(`D_WIDTH),
        .OP_SIZE(`OP_SIZE)
    )    
    alu_u(
        .alu_op(idex_alu_op),
        .a(alu_a_w),
        .b(alu_b_w),
        .y(alu_out),
        .zero(alu_zero)
    );

    //----------------------------------MEM EXEC--------------------------------------------
    //instantiate data mem
    data_mem # (
        .MEM_A_WIDTH(`MEM_A_WIDTH),
        .D_WIDTH(`D_WIDTH),
        .A_WIDTH(`A_WIDTH)
    )    
    data_mem_u(
        .clk(clk),
        .rst(rst),
        .we(exmem_mem_we),
        .w_addr(exmem_alu_out),
        .w_data(exmem_rs2_val),
        .re(exmem_mem_re),
        .r_addr(exmem_alu_out),
        .r_data(exmem_r_data)
    );

    //instantiate exmem
    ex_mem #(
        .D_WIDTH(`D_WIDTH),
        .RF_SIZE(`RF_SIZE)
    ) 
    ex_mem_u (
        .clk(clk),
        .rst(rst),

        .alu_out_ex(alu_out),
        .rs2_val_ex(rs2_fwd_w),
        .rd_ex(idex_rd),
        .reg_write_ex(idex_reg_write),
        .mem_we_ex(idex_mem_we),
        .mem_re_ex(idex_mem_re),
        .mem_to_reg_ex(idex_mem_to_reg),

        .alu_out_mem(exmem_alu_out),
        .rs2_val_mem(exmem_rs2_val),
        .rd_mem(exmem_rd),
        .reg_write_mem(exmem_reg_write),
        .mem_we_mem(exmem_mem_we),
        .mem_re_mem(exmem_mem_re),
        .mem_to_reg_mem(exmem_mem_to_reg)
    );

    //----------------------------------WB--------------------------------------------
    //instantiate mem_wb
    mem_wb #(
        .D_WIDTH(`D_WIDTH),
        .RF_SIZE(`RF_SIZE)
    ) mem_wb_u (
        .clk(clk),
        .rst(rst),

        .alu_out_mem(exmem_alu_out),
        .r_data_mem(exmem_r_data),
        .rd_mem(exmem_rd),
        .reg_write_mem(exmem_reg_write),
        .mem_to_reg_mem(exmem_mem_to_reg),

        .alu_out_wb(memwb_alu_out),
        .mem_data_wb(memwb_mem_data),
        .rd_wb(memwb_rd),
        .reg_write_wb(memwb_reg_write),
        .mem_to_reg_wb(memwb_mem_to_reg)
    );
endmodule