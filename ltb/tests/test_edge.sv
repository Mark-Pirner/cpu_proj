// Edge case tests
task automatic test_x0_immutable();
    $display("\n[x0 always zero]");
    init_prog();
    prog[0] = ADDI(0, 0, 99);       // attempt write to x0
    prog[1] = ADD(0, 0, 0);         // attempt write to x0
    load_program(); do_reset(); run(20);
    check_reg(0, 32'd0, "x0 immutable");
endtask
