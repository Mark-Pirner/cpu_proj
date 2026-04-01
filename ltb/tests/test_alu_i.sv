// I-type ALU tests: ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI
task automatic test_addi();
    $display("\n[ADDI]");
    init_prog();
    prog[0] = ADDI(1, 0,   10);   // x1 =  10
    prog[1] = ADDI(2, 0,   -5);   // x2 =  -5
    prog[2] = ADDI(3, 0, 2047);   // x3 =  2047 (max positive imm12)
    prog[3] = ADDI(4, 0,-2048);   // x4 = -2048 (most negative imm12)
    prog[4] = ADDI(5, 1,    3);   // x5 =  13   (x1+3)
    load_program(); do_reset(); run(20);
    check_reg(1, 32'd10,         "ADDI  10"   );
    check_reg(2, 32'hFFFFFFFB,   "ADDI -5"    );
    check_reg(3, 32'd2047,       "ADDI  2047" );
    check_reg(4, 32'hFFFFF800,   "ADDI -2048" );
    check_reg(5, 32'd13,         "ADDI  x1+3" );
endtask

task automatic test_andi();
    $display("\n[ANDI]");
    init_prog();
    prog[0] = ADDI(1, 0, 12'h0FF);   // x1 = 0xFF
    prog[1] = ANDI(2, 1, 12'h00F);   // x2 = 0x0F
    prog[2] = ADDI(3, 0,       -1);  // x3 = 0xFFFFFFFF
    prog[3] = ANDI(4, 3, 12'h0AA);   // x4 = 0xAA
    load_program(); do_reset(); run(20);
    check_reg(2, 32'h0000000F, "ANDI 0xFF & 0x0F");
    check_reg(4, 32'h000000AA, "ANDI -1 & 0xAA"  );
endtask

task automatic test_ori();
    $display("\n[ORI]");
    init_prog();
    prog[0] = ADDI(1, 0, 12'h050);   // x1 = 0x50
    prog[1] = ORI(2, 1,  12'h00F);   // x2 = 0x5F
    prog[2] = ADDI(3, 0,        0);  // x3 = 0
    prog[3] = ORI(4, 3,  12'h7FF);   // x4 = 0x7FF
    load_program(); do_reset(); run(20);
    check_reg(2, 32'h0000005F, "ORI 0x50 | 0x0F");
    check_reg(4, 32'h000007FF, "ORI 0 | 0x7FF"  );
endtask

task automatic test_xori();
    $display("\n[XORI]");
    init_prog();
    prog[0] = ADDI(1, 0, 12'h05A);   // x1 = 0x5A
    prog[1] = XORI(2, 1, 12'h0FF);   // x2 = 0xA5
    prog[2] = ADDI(3, 0,       -1);  // x3 = 0xFFFFFFFF
    prog[3] = XORI(4, 3,       -1);  // x4 = 0
    load_program(); do_reset(); run(20);
    check_reg(2, 32'h000000A5, "XORI 0x5A ^ 0xFF");
    check_reg(4, 32'h00000000, "XORI -1 ^ -1"    );
endtask

task automatic test_slti();
    $display("\n[SLTI]");
    init_prog();
    prog[0] = ADDI(1, 0,  -5);       // x1 = -5
    prog[1] = SLTI(2, 1,   0);       // x2 = 1  (-5 < 0)
    prog[2] = ADDI(3, 0,   5);       // x3 = 5
    prog[3] = SLTI(4, 3,   0);       // x4 = 0  (5 >= 0)
    prog[4] = SLTI(5, 3,  10);       // x5 = 1  (5 < 10)
    load_program(); do_reset(); run(20);
    check_reg(2, 32'd1, "SLTI -5 < 0" );
    check_reg(4, 32'd0, "SLTI 5 >= 0" );
    check_reg(5, 32'd1, "SLTI 5 < 10" );
endtask

task automatic test_sltiu();
    $display("\n[SLTIU]");
    init_prog();
    prog[0] = ADDI(1,  0,  0);       // x1 = 0
    prog[1] = SLTIU(2, 1,  1);       // x2 = 1  (0 <u 1)
    prog[2] = ADDI(3,  0, -1);       // x3 = 0xFFFFFFFF
    prog[3] = SLTIU(4, 3,  1);       // x4 = 0  (0xFFFFFFFF >=u 1)
    prog[4] = SLTIU(5, 1, -1);       // x5 = 1  (0 <u 0xFFFFFFFF)
    load_program(); do_reset(); run(20);
    check_reg(2, 32'd1, "SLTIU 0 <u 1"           );
    check_reg(4, 32'd0, "SLTIU 0xFFFFFFFF >=u 1"  );
    check_reg(5, 32'd1, "SLTIU 0 <u 0xFFFFFFFF"   );
endtask

task automatic test_slli();
    $display("\n[SLLI]");
    init_prog();
    prog[0] = ADDI(1, 0,    1);      // x1 = 1
    prog[1] = SLLI(2, 1,    4);      // x2 = 16
    prog[2] = SLLI(3, 1,   31);      // x3 = 0x80000000
    prog[3] = ADDI(4, 0, 12'h0FF);  // x4 = 0xFF
    prog[4] = SLLI(5, 4,    8);      // x5 = 0xFF00
    load_program(); do_reset(); run(20);
    check_reg(2, 32'd16,       "SLLI 1 << 4"    );
    check_reg(3, 32'h80000000, "SLLI 1 << 31"   );
    check_reg(5, 32'h0000FF00, "SLLI 0xFF << 8" );
endtask

task automatic test_srli();
    $display("\n[SRLI]");
    init_prog();
    prog[0] = ADDI(1, 0,  -8);       // x1 = 0xFFFFFFF8
    prog[1] = SRLI(2, 1,   4);       // x2 = 0x0FFFFFFF
    prog[2] = ADDI(3, 0,  16);       // x3 = 16
    prog[3] = SRLI(4, 3,   2);       // x4 = 4
    load_program(); do_reset(); run(20);
    check_reg(2, 32'h0FFFFFFF, "SRLI 0xFFFFFFF8 >> 4");
    check_reg(4, 32'd4,        "SRLI 16 >> 2"         );
endtask

task automatic test_srai();
    $display("\n[SRAI]");
    init_prog();
    prog[0] = ADDI(1, 0,  -8);       // x1 = 0xFFFFFFF8
    prog[1] = SRAI(2, 1,   2);       // x2 = -2 = 0xFFFFFFFE
    prog[2] = ADDI(3, 0,  16);       // x3 = 16
    prog[3] = SRAI(4, 3,   2);       // x4 = 4
    load_program(); do_reset(); run(20);
    check_reg(2, 32'hFFFFFFFE, "SRAI -8 >>> 2"  );
    check_reg(4, 32'd4,        "SRAI 16 >>> 2"  );
endtask

task automatic test_sign_extension();
    $display("\n[Sign extension / negative immediates]");
    init_prog();
    prog[0] = ADDI(1, 0,  -1);      // x1 = 0xFFFFFFFF
    prog[1] = ADDI(2, 0,  -1);
    prog[2] = AND_R(3, 1, 2);        // x3 = 0xFFFFFFFF
    prog[3] = ADDI(4, 0,  -1);
    prog[4] = ADD(5, 4, 4);          // x5 = -2 = 0xFFFFFFFE
    load_program(); do_reset(); run(25);
    check_reg(1, 32'hFFFFFFFF, "sign-ext: ADDI -1"   );
    check_reg(3, 32'hFFFFFFFF, "sign-ext: AND -1&-1"  );
    check_reg(5, 32'hFFFFFFFE, "sign-ext: ADD -1+-1"  );
endtask
