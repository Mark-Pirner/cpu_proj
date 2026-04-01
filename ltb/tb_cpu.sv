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

function automatic logic [31:0] SLT_R(input [4:0] rd, rs1, rs2);
    return {7'b0000000, rs2, rs1, 3'b010, rd, 7'b0110011};
endfunction

function automatic logic [31:0] SLTU_R(input [4:0] rd, rs1, rs2);
    return {7'b0000000, rs2, rs1, 3'b011, rd, 7'b0110011};
endfunction

function automatic logic [31:0] SLL_R(input [4:0] rd, rs1, rs2);
    return {7'b0000000, rs2, rs1, 3'b001, rd, 7'b0110011};
endfunction

function automatic logic [31:0] SRL_R(input [4:0] rd, rs1, rs2);
    return {7'b0000000, rs2, rs1, 3'b101, rd, 7'b0110011};
endfunction

function automatic logic [31:0] SRA_R(input [4:0] rd, rs1, rs2);
    return {7'b0100000, rs2, rs1, 3'b101, rd, 7'b0110011};
endfunction

function automatic logic [31:0] ANDI(input [4:0] rd, rs1, input signed [11:0] imm);
    return {imm, rs1, 3'b111, rd, 7'b0010011};
endfunction

function automatic logic [31:0] ORI(input [4:0] rd, rs1, input signed [11:0] imm);
    return {imm, rs1, 3'b110, rd, 7'b0010011};
endfunction

function automatic logic [31:0] XORI(input [4:0] rd, rs1, input signed [11:0] imm);
    return {imm, rs1, 3'b100, rd, 7'b0010011};
endfunction

function automatic logic [31:0] SLTI(input [4:0] rd, rs1, input signed [11:0] imm);
    return {imm, rs1, 3'b010, rd, 7'b0010011};
endfunction

function automatic logic [31:0] SLTIU(input [4:0] rd, rs1, input signed [11:0] imm);
    return {imm, rs1, 3'b011, rd, 7'b0010011};
endfunction

function automatic logic [31:0] SLLI(input [4:0] rd, rs1, input [4:0] shamt);
    return {7'b0000000, shamt, rs1, 3'b001, rd, 7'b0010011};
endfunction

function automatic logic [31:0] SRLI(input [4:0] rd, rs1, input [4:0] shamt);
    return {7'b0000000, shamt, rs1, 3'b101, rd, 7'b0010011};
endfunction

function automatic logic [31:0] SRAI(input [4:0] rd, rs1, input [4:0] shamt);
    return {7'b0100000, shamt, rs1, 3'b101, rd, 7'b0010011};
endfunction

function automatic logic [31:0] LW(input [4:0] rd, rs1, input signed [11:0] imm);
    return {imm, rs1, 3'b010, rd, 7'b0000011};
endfunction

function automatic logic [31:0] SW(input [4:0] rs2, rs1, input signed [11:0] imm);
    return {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011};
endfunction

function automatic logic [31:0] LUI(input [4:0] rd, input [19:0] imm);
    return {imm, rd, 7'b0110111};
endfunction

function automatic logic [31:0] AUIPC(input [4:0] rd, input [19:0] imm);
    return {imm, rd, 7'b0010111};
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
`include "tests/test_lui.sv"

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
    test_andi();
    test_ori();
    test_xori();
    test_slti();
    test_sltiu();
    test_slli();
    test_srli();
    test_srai();
    test_sign_extension();

    test_add();
    test_sub();
    test_and();
    test_or();
    test_xor();
    test_slt_r();
    test_sltu_r();
    test_sll_r();
    test_srl_r();
    test_sra_r();

    test_sw_lw();

    test_fwd_ex_ex();
    test_fwd_mem_ex();
    test_fwd_both_operands();
    test_load_use_stall();

    test_running_sum();
    test_store_load_chain();
    test_alu_after_load();

    // 125 LW/ADD/SW combos: fixed order LW→ADD→SW, no NOPs
    for (int nl = 1; nl <= 5; nl++)
        for (int na = 1; na <= 5; na++)
            for (int ns = 1; ns <= 5; ns++)
                test_lw_add_sw(nl, na, ns);

    // 750 permutation tests: all 6 block orderings × 125 combos
    for (int nl = 1; nl <= 5; nl++)
        for (int na = 1; na <= 5; na++)
            for (int ns = 1; ns <= 5; ns++)
                for (int perm = 0; perm < 6; perm++)
                    test_lw_add_sw_perm(nl, na, ns, perm);

    // 1250 LW/R-type/SW combos: 10 ops × 125 count combos, fixed order
    for (int rtype = 0; rtype < 10; rtype++)
        for (int nl = 1; nl <= 5; nl++)
            for (int nr = 1; nr <= 5; nr++)
                for (int ns = 1; ns <= 5; ns++)
                    test_lw_rtype_sw(nl, nr, ns, rtype);

    // 7500 LW/R-type/SW permutation tests: 10 ops × 6 orderings × 125 combos
    for (int rtype = 0; rtype < 10; rtype++)
        for (int nl = 1; nl <= 5; nl++)
            for (int nr = 1; nr <= 5; nr++)
                for (int ns = 1; ns <= 5; ns++)
                    for (int perm = 0; perm < 6; perm++)
                        test_lw_rtype_sw_perm(nl, nr, ns, rtype, perm);

    // 875 LW/I-type/SW combos: 7 ops × 125 count combos, fixed LW→I-type→SW order
    for (int itype = 0; itype < 7; itype++)
        for (int nl = 1; nl <= 5; nl++)
            for (int ni = 1; ni <= 5; ni++)
                for (int ns = 1; ns <= 5; ns++)
                    test_lw_itype_sw(nl, ni, ns, itype);

    // 5250 LW/I-type/SW permutation tests: 7 ops × 6 orderings × 125 combos
    for (int itype = 0; itype < 7; itype++)
        for (int nl = 1; nl <= 5; nl++)
            for (int ni = 1; ni <= 5; ni++)
                for (int ns = 1; ns <= 5; ns++)
                    for (int perm = 0; perm < 6; perm++)
                        test_lw_itype_sw_perm(nl, ni, ns, itype, perm);

    test_lui_basic();
    test_lui_addi();
    test_lui_forwarding();
    test_lui_overwrite();

    test_auipc_basic();
    test_auipc_addi();
    test_auipc_forwarding();

    // 25 LUI/SW combos: nl=1..5, ns=1..5
    for (int nl = 1; nl <= 5; nl++)
        for (int ns = 1; ns <= 5; ns++)
            test_lui_sw(nl, ns);

    // 25 LUI+ADDI/SW combos: nl=1..5, ns=1..5
    for (int nl = 1; nl <= 5; nl++)
        for (int ns = 1; ns <= 5; ns++)
            test_lui_addi_sw(nl, ns);

    // 25 AUIPC/SW combos: nl=1..5, ns=1..5
    for (int nl = 1; nl <= 5; nl++)
        for (int ns = 1; ns <= 5; ns++)
            test_auipc_sw(nl, ns);

    // 25 AUIPC+ADDI/SW combos: nl=1..5, ns=1..5
    for (int nl = 1; nl <= 5; nl++)
        for (int ns = 1; ns <= 5; ns++)
            test_auipc_addi_sw(nl, ns);

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
