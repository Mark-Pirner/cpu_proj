#!/usr/bin/env bash
# Run a single numbered test within a group and open its waveform in gtkwave.
#
# Usage:
#   ./run_test.bash <test_group> <test_#>
#
# Test groups and numbered tests:
#   alu_i      — 1:ADDI  2:sign_extension
#   alu_r      — 1:ADD  2:SUB  3:AND  4:OR  5:XOR
#   mem        — 1:SW/LW
#   forwarding — 1:EX->EX  2:MEM->EX  3:both_operands  4:load-use_stall
#   sequences  — 1:running_sum  2:store/load_chain  3:LW_then_ALU
#   edge       — 1:x0_immutable

set -e

print_usage() {
    echo "Usage: ./run_test.bash <test_group> <test_#>"
    echo ""
    echo "Test groups and numbered tests:"
    echo "  alu_i      — 1:ADDI  2:sign_extension"
    echo "  alu_r      — 1:ADD  2:SUB  3:AND  4:OR  5:XOR"
    echo "  mem        — 1:SW/LW"
    echo "  forwarding — 1:EX->EX  2:MEM->EX  3:both_operands  4:load-use_stall"
    echo "  sequences  — 1:running_sum  2:store/load_chain  3:LW_then_ALU"
    echo "  edge       — 1:x0_immutable"
}

if [ -z "$1" ] || [ -z "$2" ]; then
    print_usage
    exit 1
fi

GROUP=$1
NUM=$2

# Map group+number to a single task call and description
case "${GROUP}_${NUM}" in
    alu_i_1)      CALL="test_addi();"              DESC="ADDI" ;;
    alu_i_2)      CALL="test_sign_extension();"    DESC="sign_extension" ;;
    alu_r_1)      CALL="test_add();"               DESC="ADD" ;;
    alu_r_2)      CALL="test_sub();"               DESC="SUB" ;;
    alu_r_3)      CALL="test_and();"               DESC="AND" ;;
    alu_r_4)      CALL="test_or();"                DESC="OR" ;;
    alu_r_5)      CALL="test_xor();"               DESC="XOR" ;;
    mem_1)        CALL="test_sw_lw();"             DESC="SW/LW" ;;
    forwarding_1) CALL="test_fwd_ex_ex();"         DESC="EX-EX_fwd" ;;
    forwarding_2) CALL="test_fwd_mem_ex();"        DESC="MEM-EX_fwd" ;;
    forwarding_3) CALL="test_fwd_both_operands();" DESC="both_operands_fwd" ;;
    forwarding_4) CALL="test_load_use_stall();"    DESC="load-use_stall" ;;
    sequences_1)  CALL="test_running_sum();"       DESC="running_sum" ;;
    sequences_2)  CALL="test_store_load_chain();"  DESC="store_load_chain" ;;
    sequences_3)  CALL="test_alu_after_load();"    DESC="ALU_after_load" ;;
    edge_1)       CALL="test_x0_immutable();"      DESC="x0_immutable" ;;
    *)
        echo "Unknown test: group='$GROUP' number='$NUM'"
        echo ""
        print_usage
        exit 1
        ;;
esac

VCD="tb_${GROUP}_${NUM}.vcd"
BIN="sim_${GROUP}_${NUM}"

cat > /tmp/tb_single.sv << EOF
\`timescale 1ns/1ps
module tb_cpu;
localparam CLK_HALF = 5;
logic clk = 0, rst;
always #CLK_HALF clk = ~clk;
top_inst dut (.clk(clk), .rst(rst));
\`define RF   dut.id_stage_u.rf_u.mem
\`define IMEM dut.isu_mem_u.mem
\`define DMEM dut.mem_intf_u.data_mem_u.mem
int pass_cnt = 0, fail_cnt = 0;
localparam logic [31:0] NOP = 32'h00000013;
function automatic logic [31:0] ADDI(input [4:0] rd, rs1, input signed [11:0] imm);
    return {imm, rs1, 3'b000, rd, 7'b0010011};
endfunction
function automatic logic [31:0] ADD(input [4:0] rd, rs1, rs2);
    return {7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011};
endfunction
function automatic logic [31:0] SUB(input [4:0] rd, rs1, rs2);
    return {7'b0100000, rs2, rs1, 3'b000, rd, 7'b0110011};
endfunction
function automatic logic [31:0] AND_R(input [4:0] rd, rs1, rs2);
    return {7'b0000000, rs2, rs1, 3'b111, rd, 7'b0110011};
endfunction
function automatic logic [31:0] OR_R(input [4:0] rd, rs1, rs2);
    return {7'b0000000, rs2, rs1, 3'b110, rd, 7'b0110011};
endfunction
function automatic logic [31:0] XOR_R(input [4:0] rd, rs1, rs2);
    return {7'b0000000, rs2, rs1, 3'b100, rd, 7'b0110011};
endfunction
function automatic logic [31:0] LW(input [4:0] rd, rs1, input signed [11:0] imm);
    return {imm, rs1, 3'b010, rd, 7'b0000011};
endfunction
function automatic logic [31:0] SW(input [4:0] rs2, rs1, input signed [11:0] imm);
    return {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011};
endfunction
logic [31:0] prog [0:255];
task automatic load_program();
    for (int i = 0; i < 256; i++) begin
        \`IMEM[i] = prog[i];
        \`DMEM[i] = 32'h0;
    end
endtask
task automatic init_prog();
    for (int i = 0; i < 256; i++) prog[i] = NOP;
endtask
task automatic do_reset();
    rst = 1; repeat(4) @(posedge clk); @(negedge clk); rst = 0;
endtask
task automatic run(input int cycles);
    repeat(cycles) @(posedge clk); #1;
endtask
task automatic check_reg(input [4:0] reg_num, input logic [31:0] expected, input string desc);
    if (\`RF[reg_num] === expected) begin
        \$display("  PASS  %-30s  x%0d = 32'h%08X", desc, reg_num, expected); pass_cnt++;
    end else begin
        \$display("  FAIL  %-30s  x%0d: expected 32'h%08X  got 32'h%08X", desc, reg_num, expected, \`RF[reg_num]); fail_cnt++;
    end
endtask
task automatic check_dmem(input [7:0] word_idx, input logic [31:0] expected, input string desc);
    if (\`DMEM[word_idx] === expected) begin
        \$display("  PASS  %-30s  MEM[%0d] = 32'h%08X", desc, word_idx, expected); pass_cnt++;
    end else begin
        \$display("  FAIL  %-30s  MEM[%0d]: expected 32'h%08X  got 32'h%08X", desc, word_idx, expected, \`DMEM[word_idx]); fail_cnt++;
    end
endtask
\`include "tests/test_alu_i.sv"
\`include "tests/test_alu_r.sv"
\`include "tests/test_mem.sv"
\`include "tests/test_forwarding.sv"
\`include "tests/test_sequences.sv"
\`include "tests/test_edge.sv"
initial begin
    \$dumpfile("$VCD");
    \$dumpvars(0, dut);
    \$display("================================================================");
    \$display("  Test: $GROUP #$NUM — $DESC");
    \$display("================================================================");
    $CALL
    \$display("\n================================================================");
    \$display("  %0d passed  |  %0d failed", pass_cnt, fail_cnt);
    \$display("================================================================");
    if (fail_cnt == 0) \$display("  ALL TESTS PASSED");
    else               \$display("  *** %0d FAILURE(S) ***", fail_cnt);
    \$finish;
end
endmodule
EOF

rm -f "$BIN"
iverilog -g2012 -DLTB_EN -I../rtl -o "$BIN" ../rtl/cpu.v /tmp/tb_single.sv
vvp "$BIN"
gtkwave "$VCD" &
