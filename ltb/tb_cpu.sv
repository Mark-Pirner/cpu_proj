// Self-checking SystemVerilog testbench for the RISC-V CPU pipeline.
//
// Compile & run:   cd ltb && ./run_tb.bash
// With waveform:   cd ltb && ./run_tb.bash -w

`timescale 1ns/1ps

module tb_cpu;

// ─────────────────────────────────────────────────────────────────────────────
// 1.  Clock & reset
// ─────────────────────────────────────────────────────────────────────────────
localparam CLK_HALF = 5;

logic clk = 0;
logic rst;

always #CLK_HALF clk = ~clk;

// ─────────────────────────────────────────────────────────────────────────────
// 2.  DUT
// ─────────────────────────────────────────────────────────────────────────────
top_inst dut (.clk(clk), .rst(rst));

`define RF   dut.id_stage_u.rf_u.mem
`define IMEM dut.isu_mem_u.mem
`define DMEM dut.mem_intf_u.data_mem_u.mem

// ─────────────────────────────────────────────────────────────────────────────
// 3.  Test statistics
// ─────────────────────────────────────────────────────────────────────────────
int pass_cnt = 0;
int fail_cnt = 0;

// ─────────────────────────────────────────────────────────────────────────────
// 4.  Instruction encoding helpers
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// 5.  Infrastructure tasks
// ─────────────────────────────────────────────────────────────────────────────
logic [31:0] prog [0:255];

task automatic load_program();
    for (int i = 0; i < 256; i++) begin
        `IMEM[i] = prog[i];
        `DMEM[i] = 32'h0;
    end
endtask

task automatic init_prog();
    for (int i = 0; i < 256; i++)
        prog[i] = NOP;
endtask

task automatic do_reset();
    rst = 1;
    repeat(4) @(posedge clk);
    @(negedge clk);
    rst = 0;
endtask

task automatic run(input int cycles);
    repeat(cycles) @(posedge clk);
    #1;
endtask

task automatic check_reg(
    input [4:0]        reg_num,
    input logic [31:0] expected,
    input string       desc
);
    if (`RF[reg_num] === expected) begin
        $display("  PASS  %-30s  x%0d = 32'h%08X", desc, reg_num, expected);
        pass_cnt++;
    end else begin
        $display("  FAIL  %-30s  x%0d: expected 32'h%08X  got 32'h%08X",
                 desc, reg_num, expected, `RF[reg_num]);
        fail_cnt++;
    end
endtask

task automatic check_dmem(
    input [7:0]        word_idx,
    input logic [31:0] expected,
    input string       desc
);
    if (`DMEM[word_idx] === expected) begin
        $display("  PASS  %-30s  MEM[%0d] = 32'h%08X", desc, word_idx, expected);
        pass_cnt++;
    end else begin
        $display("  FAIL  %-30s  MEM[%0d]: expected 32'h%08X  got 32'h%08X",
                 desc, word_idx, expected, `DMEM[word_idx]);
        fail_cnt++;
    end
endtask

// ─────────────────────────────────────────────────────────────────────────────
// 6.  Test tasks (one file per group under tests/)
// ─────────────────────────────────────────────────────────────────────────────
`include "tests/test_alu_i.sv"
`include "tests/test_alu_r.sv"
`include "tests/test_mem.sv"
`include "tests/test_forwarding.sv"
`include "tests/test_sequences.sv"
`include "tests/test_edge.sv"

// ─────────────────────────────────────────────────────────────────────────────
// 7.  Main
// ─────────────────────────────────────────────────────────────────────────────
initial begin
    $dumpfile("tb_cpu.vcd");
    $dumpvars(0, dut);

    $display("================================================================");
    $display("  CPU Testbench");
    $display("================================================================");

    test_addi();
    test_sign_extension();

    test_add();
    test_sub();
    test_and();
    test_or();
    test_xor();

    test_sw_lw();

    test_fwd_ex_ex();
    test_fwd_mem_ex();
    test_fwd_both_operands();
    test_load_use_stall();

    test_running_sum();
    test_store_load_chain();
    test_alu_after_load();

    test_x0_immutable();

    $display("\n================================================================");
    $display("  %0d passed  |  %0d failed", pass_cnt, fail_cnt);
    $display("================================================================");
    if (fail_cnt == 0)
        $display("  ALL TESTS PASSED");
    else
        $display("  *** %0d FAILURE(S) — see FAIL lines above ***", fail_cnt);

    $finish;
end

endmodule
