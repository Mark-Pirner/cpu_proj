// Multi-instruction sequence tests
task automatic test_running_sum();
    $display("\n[Sequence: running sum 1+2+3+4+5]");
    init_prog();
    prog[0] = ADDI(1, 0, 1);
    prog[1] = ADDI(2, 0, 2);
    prog[2] = ADDI(3, 0, 3);
    prog[3] = ADDI(4, 0, 4);
    prog[4] = ADDI(5, 0, 5);
    prog[5] = ADD(6, 1, 2);         // 3
    prog[6] = ADD(6, 6, 3);         // 6
    prog[7] = ADD(6, 6, 4);         // 10
    prog[8] = ADD(6, 6, 5);         // 15
    load_program(); do_reset(); run(30);
    check_reg(6, 32'd15, "Sum 1+2+3+4+5 = 15");
endtask

task automatic test_store_load_chain();
    $display("\n[Sequence: SW x3 then LW x3]");
    init_prog();
    prog[0]  = ADDI(1, 0, 10);
    prog[1]  = ADDI(2, 0, 20);
    prog[2]  = ADDI(3, 0, 30);
    prog[3]  = SW(1, 0,  0);        // DMEM[word 0] = 10
    prog[4]  = SW(2, 0,  4);        // DMEM[word 1] = 20
    prog[5]  = SW(3, 0,  8);        // DMEM[word 2] = 30
    prog[6]  = NOP;
    prog[7]  = NOP;
    prog[8]  = LW(4, 0,  0);        // x4 = 10
    prog[9]  = LW(5, 0,  4);        // x5 = 20
    prog[10] = LW(6, 0,  8);        // x6 = 30
    load_program(); do_reset(); run(50);
    check_reg(4, 32'd10, "SL-chain: MEM[0]" );
    check_reg(5, 32'd20, "SL-chain: MEM[4]" );
    check_reg(6, 32'd30, "SL-chain: MEM[8]" );
endtask

task automatic test_alu_after_load();
    $display("\n[Sequence: LW then ALU]");
    init_prog();
    prog[0]  = ADDI(1, 0, 25);
    prog[1]  = ADDI(2, 0, 10);
    prog[2]  = SW(1, 0, 16);        // DMEM[word 4] = 25
    prog[3]  = SW(2, 0, 20);        // DMEM[word 5] = 10
    prog[4]  = NOP;
    prog[5]  = NOP;
    prog[6]  = LW(3, 0, 16);        // x3 = 25
    prog[7]  = LW(4, 0, 20);        // x4 = 10
    prog[8]  = ADD(5, 3, 4);         // x5 = 35
    prog[9] = SUB(6, 3, 4);         // x6 = 15
    load_program(); do_reset(); run(55);
    check_reg(5, 32'd35, "ALU-after-load: ADD" );
    check_reg(6, 32'd15, "ALU-after-load: SUB" );
endtask
