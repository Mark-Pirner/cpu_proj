// I-type ALU tests: ADDI, sign extension
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
