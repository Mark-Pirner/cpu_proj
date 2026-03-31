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
