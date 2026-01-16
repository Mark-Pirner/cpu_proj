`include "rf.v"

module id_stage #(
    parameter D_WIDTH = 32,
    parameter N_REGS  = 32,
    parameter RF_SIZE = $clog2(N_REGS),
    parameter OP_SIZE = 4
)(
    input                       clk,
    input                       rst,
    input                       en,

    //from IF   
    input   [D_WIDTH-1:0]       instr,
    input   [RF_SIZE-1:0]       rs1,
    input   [RF_SIZE-1:0]       rs2,
    input   [RF_SIZE-1:0]       rd,
    input   [6:0]               opcode,
    input   [2:0]               funct3,
    input   [6:0]               funct7, 

    //from WB
    input                       wb_we,
    input  [RF_SIZE-1:0]        wb_rd,
    input  [D_WIDTH-1:0]        wb_data,

    //ID
    output reg  [RF_SIZE-1:0]   rs1_ex,
    output reg  [RF_SIZE-1:0]   rs2_ex,
    output reg  [D_WIDTH-1:0]   rs1_val_ex,
    output reg  [D_WIDTH-1:0]   rs2_val_ex,
    output reg  [D_WIDTH-1:0]   imm_ex,
    output reg  [RF_SIZE-1:0]   rd_ex,
    output reg                  reg_write_ex,
    output reg                  alu_src_imm_ex,
    output reg  [OP_SIZE-1:0]   alu_op_ex,
    output reg                  mem_we_ex,
    output reg                  mem_re_ex,
    output reg                  mem_to_reg_ex
);

    wire [D_WIDTH-1:0]                 rs1_val_in;
    wire [D_WIDTH-1:0]                 rs2_val_in;

    rf rf_u(
        .clk(clk),
        .rst(rst),
        .we(wb_we),
        .w_addr(wb_rd),
        .w_data(wb_data),
        .rs2(rs2),
        .rs1(rs1),
        .rs2_d(rs2_val_in),
        .rs1_d(rs1_val_in)
    );

    reg                  reg_write_d;
    reg                  alu_src_imm_d;
    reg  [OP_SIZE-1:0]   alu_op_d;
    reg                  mem_we_d;
    reg                  mem_re_d;
    reg  [D_WIDTH-1:0]   imm_d;
    reg                  mem_to_reg_d;

    //immediate 12 bits, sign extended
    wire [D_WIDTH-1:0] imm_i_ext = {{20{instr[31]}}, instr[31:20]};

    always @(*) 
    begin
        reg_write_d  = 1'b0;
        alu_src_imm_d = 1'b0;
        alu_op_d     = {OP_SIZE{1'b0}};
        mem_we_d     = 1'b0;
        mem_re_d     = 1'b0;
        imm_d        = {D_WIDTH{1'b0}};
        mem_to_reg_d = 1'b0;
        

        //-----------------------R_TYPE ISU------------------------------------
        if (opcode == 7'b0110011) 
        begin
            reg_write_d   = 1'b1;
            alu_src_imm_d = 1'b0;
            mem_to_reg_d  = 1'b0;
            mem_we_d =      1'b0;
            mem_re_d =      1'b0;

            case(funct3)
                3'b000:  alu_op_d = (funct7 == 7'b0000000) ? 4'b0000 : 4'b0001;
                3'b111:  alu_op_d = 4'b0010;
                3'b110:  alu_op_d = 4'b0011;
                3'b100:  alu_op_d = 4'b0100;
                3'b010:  alu_op_d = 4'b0101;
                default: alu_op_d = 4'b1111;
            endcase
        end
        //-----------------------I_TYPE ISU------------------------------------
        else if (opcode == 7'b0010011)
        begin
            reg_write_d =   1'b1;
            alu_src_imm_d = 1'b1;
            mem_to_reg_d =  1'b0;
            mem_we_d =      1'b0;
            mem_re_d =      1'b0;
            imm_d =         imm_i_ext;

            case(funct3)
                3'b000:  alu_op_d = (funct7 == 7'b0000000) ? 4'b0000 : 4'b0001;
                3'b111:  alu_op_d = 4'b0010;
                3'b110:  alu_op_d = 4'b0011;
                3'b100:  alu_op_d = 4'b0100;
                3'b010:  alu_op_d = 4'b0101;
                default: alu_op_d = 4'b1111;
            endcase
        end
        //-----------------------LOAD WORD------------------------------------
        else if (opcode == 7'b0000011)
        begin
            reg_write_d =   1'b1;
            alu_src_imm_d = 1'b1;
            mem_to_reg_d =  1'b1;
            mem_we_d =      1'b0;
            mem_re_d =      1'b1;
            imm_d =         imm_i_ext;
            alu_op_d =        4'b0000;
        end
        //-----------------------STORE WORD------------------------------------
        else if(opcode == 7'b0100011)
        begin
            reg_write_d = 1'b0;
            alu_src_imm_d = 1'b1;
            mem_to_reg_d = 1'b0;
            mem_we_d = 1'b1;
            mem_re_d = 1'b0;
            imm_d = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            alu_op_d = 4'b0000;
        end
    end

    always @(posedge clk or posedge rst) 
    begin
        if (rst) 
        begin
            rs1_val_ex      <= {D_WIDTH{1'b0}};
            rs2_val_ex      <= {D_WIDTH{1'b0}};
            imm_ex          <= {D_WIDTH{1'b0}};
            rd_ex           <= {RF_SIZE{1'b0}};
            reg_write_ex    <= 1'b0;
            alu_src_imm_ex  <= 1'b0;
            alu_op_ex       <= {OP_SIZE{1'b0}};
            mem_we_ex       <= 1'b0;
            mem_re_ex       <= 1'b0;
            mem_to_reg_ex   <= 1'b0;
            rs1_ex          <= {RF_SIZE{1'b0}};
            rs2_ex          <= {RF_SIZE{1'b0}};
        end
        else if (en) 
        begin
            rs1_val_ex      <= rs1_val_in;
            rs2_val_ex      <= rs2_val_in;
            imm_ex          <= imm_d;
            rd_ex           <= rd;
            reg_write_ex    <= reg_write_d;
            alu_src_imm_ex  <= alu_src_imm_d;
            alu_op_ex       <= alu_op_d;
            mem_we_ex       <= mem_we_d;
            mem_re_ex       <= mem_re_d;
            mem_to_reg_ex   <= mem_to_reg_d;
            rs1_ex          <= rs1;
            rs2_ex          <= rs2;
        end
    end
endmodule