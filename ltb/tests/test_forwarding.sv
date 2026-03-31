// Forwarding and hazard tests
task automatic test_fwd_ex_ex();
    $display("\n[Forwarding: EX -> EX]");
    init_prog();
    prog[0] = ADDI(1, 0,  5);
    prog[1] = ADDI(2, 1,  3);       // x2 = x1+3 = 8   (x1 fwd EX/MEM->EX)
    prog[2] = ADD(3, 2, 1);         // x3 = 8+5  = 13  (x2 fwd EX/MEM->EX)
    load_program(); do_reset(); run(20);
    check_reg(2, 32'd8,  "EX-EX fwd: ADDI->ADDI" );
    check_reg(3, 32'd13, "EX-EX fwd: ADDI->ADD"  );
endtask

task automatic test_fwd_mem_ex();
    $display("\n[Forwarding: MEM -> EX]");
    init_prog();
    prog[0] = ADDI(1, 0, 10);
    prog[1] = ADDI(2, 0, 20);       // unrelated instruction in between
    prog[2] = ADD(3, 1, 2);         // x3 = 30  (x1 fwd MEM/WB->EX)
    load_program(); do_reset(); run(20);
    check_reg(3, 32'd30, "MEM-EX fwd");
endtask

task automatic test_fwd_both_operands();
    $display("\n[Forwarding: both operands]");
    init_prog();
    prog[0] = ADDI(1, 0,  3);
    prog[1] = ADDI(2, 0,  4);
    prog[2] = ADD(3, 1, 2);         // x3 = 7   (x1 and x2 both fwd)
    prog[3] = ADD(4, 3, 3);         // x4 = 14  (x3 fwd twice)
    load_program(); do_reset(); run(20);
    check_reg(3, 32'd7,  "both-fwd: ADD"   );
    check_reg(4, 32'd14, "both-fwd: chain" );
endtask

task automatic test_load_use_stall();
    $display("\n[Load-Use Stall]");
    init_prog();
    prog[0] = ADDI(1, 0, 7);
    prog[1] = SW(1, 0, 4);          // DMEM[word 1] = 7
    prog[2] = NOP;
    prog[3] = NOP;                  // let store retire cleanly
    prog[4] = LW(2, 0, 4);         // x2 = 7
    prog[5] = ADD(3, 2, 2);         // x3 = 14  (stall inserted for x2)
    load_program(); do_reset(); run(40);
    check_reg(2, 32'd7,  "LU stall: LW result"   );
    check_reg(3, 32'd14, "LU stall: ADD after LW" );
endtask
