// R-type ALU tests: ADD, SUB, AND, OR, XOR
task automatic test_add();
    $display("\n[ADD]");
    init_prog();
    prog[0] = ADDI(1, 0, 15);
    prog[1] = ADDI(2, 0,  7);
    prog[2] = ADD(3, 1, 2);       // x3 = 22
    prog[3] = ADD(4, 3, 3);       // x4 = 44  (back-to-back dependent)
    load_program(); do_reset(); run(20);
    check_reg(3, 32'd22, "ADD 15+7"  );
    check_reg(4, 32'd44, "ADD x3+x3" );
endtask

task automatic test_sub();
    $display("\n[SUB]");
    init_prog();
    prog[0] = ADDI(1, 0, 10);
    prog[1] = ADDI(2, 0,  4);
    prog[2] = SUB(3, 1, 2);       // x3 =  6
    prog[3] = SUB(4, 2, 1);       // x4 = -6
    load_program(); do_reset(); run(20);
    check_reg(3, 32'd6,        "SUB  pos" );
    check_reg(4, 32'hFFFFFFFA, "SUB  neg" );
endtask

task automatic test_and();
    $display("\n[AND]");
    init_prog();
    prog[0] = ADDI(1, 0, 12'h07F); // x1 = 0x7F
    prog[1] = ADDI(2, 0, 12'h00F); // x2 = 0x0F
    prog[2] = AND_R(3, 1, 2);      // x3 = 0x0F
    load_program(); do_reset(); run(20);
    check_reg(3, 32'h0000000F, "AND 0x7F & 0x0F");
endtask

task automatic test_or();
    $display("\n[OR]");
    init_prog();
    prog[0] = ADDI(1, 0, 12'h05A); // x1 = 0x5A
    prog[1] = ADDI(2, 0, 12'h025); // x2 = 0x25
    prog[2] = OR_R(3, 1, 2);        // x3 = 0x7F
    load_program(); do_reset(); run(20);
    check_reg(3, 32'h0000007F, "OR 0x5A | 0x25");
endtask

task automatic test_xor();
    $display("\n[XOR]");
    init_prog();
    prog[0] = ADDI(1, 0, 12'h05A); // x1 = 0x5A
    prog[1] = ADDI(2, 0, 12'h03C); // x2 = 0x3C
    prog[2] = XOR_R(3, 1, 2);       // x3 = 0x66
    load_program(); do_reset(); run(20);
    check_reg(3, 32'h00000066, "XOR 0x5A ^ 0x3C");
endtask

task automatic test_slt_r();
    $display("\n[SLT]");
    init_prog();
    prog[0] = ADDI(1, 0,  -5);      // x1 = -5
    prog[1] = ADDI(2, 0,   3);      // x2 =  3
    prog[2] = SLT_R(3, 1, 2);       // x3 = 1  (-5 < 3)
    prog[3] = SLT_R(4, 2, 1);       // x4 = 0  (3 >= -5)
    prog[4] = SLT_R(5, 2, 2);       // x5 = 0  (equal)
    load_program(); do_reset(); run(20);
    check_reg(3, 32'd1, "SLT -5 < 3"  );
    check_reg(4, 32'd0, "SLT 3 >= -5" );
    check_reg(5, 32'd0, "SLT equal"   );
endtask

task automatic test_sltu_r();
    $display("\n[SLTU]");
    init_prog();
    prog[0] = ADDI(1, 0,   0);      // x1 = 0
    prog[2] = ADDI(2, 0,  -1);      // x2 = 0xFFFFFFFF
    prog[3] = SLTU_R(3, 1, 2);      // x3 = 1  (0 <u 0xFFFFFFFF)
    prog[4] = SLTU_R(4, 2, 1);      // x4 = 0  (0xFFFFFFFF >=u 0)
    load_program(); do_reset(); run(20);
    check_reg(3, 32'd1, "SLTU 0 <u 0xFFFFFFFF"  );
    check_reg(4, 32'd0, "SLTU 0xFFFFFFFF >=u 0" );
endtask

task automatic test_sll_r();
    $display("\n[SLL]");
    init_prog();
    prog[0] = ADDI(1, 0,   1);      // x1 = 1
    prog[1] = ADDI(2, 0,   4);      // x2 = 4  (shamt)
    prog[2] = SLL_R(3, 1, 2);       // x3 = 16
    prog[3] = ADDI(4, 0,  12'h0FF); // x4 = 0xFF
    prog[4] = ADDI(5, 0,   8);      // x5 = 8  (shamt)
    prog[5] = SLL_R(6, 4, 5);       // x6 = 0xFF00
    load_program(); do_reset(); run(20);
    check_reg(3, 32'd16,       "SLL 1 << 4"    );
    check_reg(6, 32'h0000FF00, "SLL 0xFF << 8" );
endtask

task automatic test_srl_r();
    $display("\n[SRL]");
    init_prog();
    prog[0] = ADDI(1, 0,  -8);      // x1 = 0xFFFFFFF8
    prog[1] = ADDI(2, 0,   4);      // x2 = 4  (shamt)
    prog[2] = SRL_R(3, 1, 2);       // x3 = 0x0FFFFFFF
    prog[3] = ADDI(4, 0,  16);      // x4 = 16
    prog[4] = ADDI(5, 0,   2);      // x5 = 2  (shamt)
    prog[5] = SRL_R(6, 4, 5);       // x6 = 4
    load_program(); do_reset(); run(20);
    check_reg(3, 32'h0FFFFFFF, "SRL 0xFFFFFFF8 >> 4" );
    check_reg(6, 32'd4,        "SRL 16 >> 2"          );
endtask

task automatic test_sra_r();
    $display("\n[SRA]");
    init_prog();
    prog[0] = ADDI(1, 0,  -8);      // x1 = 0xFFFFFFF8
    prog[1] = ADDI(2, 0,   2);      // x2 = 2  (shamt)
    prog[2] = SRA_R(3, 1, 2);       // x3 = -2 = 0xFFFFFFFE
    prog[3] = ADDI(4, 0,  16);      // x4 = 16
    prog[4] = ADDI(5, 0,   2);      // x5 = 2  (shamt)
    prog[5] = SRA_R(6, 4, 5);       // x6 = 4
    load_program(); do_reset(); run(20);
    check_reg(3, 32'hFFFFFFFE, "SRA -8 >>> 2"  );
    check_reg(6, 32'd4,        "SRA 16 >>> 2"  );
endtask
