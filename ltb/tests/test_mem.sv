// Memory tests: SW, LW
task automatic test_sw_lw();
    $display("\n[SW / LW]");
    init_prog();
    prog[0] = ADDI(1, 0, 42);
    prog[1] = SW(1, 0, 8);          // DMEM[word 2] = 42   (byte addr 8)
    prog[2] = LW(2, 0, 8);          // x2 = DMEM[word 2]   (load-use stall)
    prog[3] = ADDI(3, 0, 99);
    prog[4] = SW(3, 0, 12);         // DMEM[word 3] = 99
    prog[5] = LW(4, 0, 12);         // x4 = DMEM[word 3]
    load_program(); do_reset(); run(40);
    check_reg(2,  32'd42,  "LW  byte=8"   );
    check_reg(4,  32'd99,  "LW  byte=12"  );
    check_dmem(2, 32'd42,  "DMEM word[2]" );
    check_dmem(3, 32'd99,  "DMEM word[3]" );
endtask
