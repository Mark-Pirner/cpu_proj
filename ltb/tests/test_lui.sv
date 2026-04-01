// U-type tests: LUI and AUIPC
//
// PC pipeline note: IMEM and IF/ID are both synchronous registers, so the PC
// that flows with prog[i] through the pipeline is (i+1)*4, not i*4.
// e.g. prog[0] → ifid_pc = 4,  prog[1] → ifid_pc = 8,  prog[i] → ifid_pc = (i+1)*4
task automatic test_lui_basic();
    $display("\n[LUI basic]");
    init_prog();
    prog[0] = LUI(1, 20'h00001);   // x1 = 0x00001000
    prog[1] = LUI(2, 20'hFFFFF);   // x2 = 0xFFFFF000
    prog[2] = LUI(3, 20'h12345);   // x3 = 0x12345000
    prog[3] = LUI(4, 20'h00000);   // x4 = 0x00000000 (zero imm)
    load_program(); do_reset(); run(20);
    check_reg(1, 32'h00001000, "LUI 0x1"        );
    check_reg(2, 32'hFFFFF000, "LUI 0xFFFFF"    );
    check_reg(3, 32'h12345000, "LUI 0x12345"    );
    check_reg(4, 32'h00000000, "LUI 0 (zero)"   );
endtask

// LUI + ADDI = standard li (load immediate) pattern
task automatic test_lui_addi();
    $display("\n[LUI + ADDI]");
    init_prog();
    // x1 = 0x12345678: LUI loads upper, ADDI adds lower
    prog[0] = LUI (1, 20'h12345);  // x1 = 0x12345000
    prog[1] = ADDI(1, 1, 12'h678);// x1 = 0x12345678  (EX→EX forward)
    // x2 = 0xDEADBEEF: upper=0xDEADB, lower=0xEEF
    // Note: ADDI sign-extends lower 12. 0xEEF = -273 signed, so
    // upper must be 0xDEADC to compensate: 0xDEADC000 + (-273) = 0xDEADBEEF? No...
    // Simpler approach: 0x000010FF = LUI(0x00001) + ADDI(0xFF)
    prog[2] = LUI (2, 20'h00001);  // x2 = 0x00001000
    prog[3] = ADDI(2, 2, 12'h0FF);// x2 = 0x000010FF  (EX→EX forward)
    // negative lower half: 0x0000FFFF = LUI(0x00001) + ADDI(-1)
    prog[4] = LUI (3, 20'h00001);  // x3 = 0x00001000
    prog[5] = ADDI(3, 3, -1);      // x3 = 0x00000FFF  (EX→EX forward, -1 sign-ext)
    load_program(); do_reset(); run(25);
    check_reg(1, 32'h12345678, "LUI+ADDI 0x12345678" );
    check_reg(2, 32'h000010FF, "LUI+ADDI 0x000010FF" );
    check_reg(3, 32'h00000FFF, "LUI+ADDI neg lower"  );
endtask

// LUI result used as ALU input (forwarding)
task automatic test_lui_forwarding();
    $display("\n[LUI forwarding]");
    init_prog();
    prog[0] = LUI (1, 20'h00002);  // x1 = 0x00002000
    prog[1] = LUI (2, 20'h00001);  // x2 = 0x00001000
    prog[2] = ADD (3, 1, 2);       // x3 = 0x00003000  (MEM→EX fwd on x1, EX→EX fwd on x2)
    prog[3] = ADD (4, 3, 3);       // x4 = 0x00006000  (EX→EX fwd)
    load_program(); do_reset(); run(20);
    check_reg(3, 32'h00003000, "LUI fwd: ADD two LUI results" );
    check_reg(4, 32'h00006000, "LUI fwd: ADD x3+x3"          );
endtask

// Back-to-back LUI writes to same register
task automatic test_lui_overwrite();
    $display("\n[LUI overwrite]");
    init_prog();
    prog[0] = LUI(1, 20'hAAAAA);   // x1 = 0xAAAAA000  (overwritten)
    prog[1] = LUI(1, 20'h55555);   // x1 = 0x55555000  (winner)
    prog[2] = NOP;
    prog[3] = NOP;
    load_program(); do_reset(); run(20);
    check_reg(1, 32'h55555000, "LUI overwrite same reg" );
endtask

// ── AUIPC tests ────────────────────────────────────────────────────────────

// prog[i] has ifid_pc = (i+1)*4, so AUIPC at prog[i] gives rd = (i+1)*4 + (imm<<12)
task automatic test_auipc_basic();
    $display("\n[AUIPC basic]");
    init_prog();
    prog[0] = AUIPC(1, 20'h00000);   // x1 = 4  + 0          = 4
    prog[1] = AUIPC(2, 20'h00001);   // x2 = 8  + 0x1000     = 0x1008
    prog[2] = AUIPC(3, 20'hFFFFF);   // x3 = 12 + 0xFFFFF000 = 0xFFFFF00C
    load_program(); do_reset(); run(20);
    check_reg(1, 32'h00000004, "AUIPC imm=0   @ prog[0]"     );
    check_reg(2, 32'h00001008, "AUIPC imm=1   @ prog[1]"     );
    check_reg(3, 32'hFFFFF00C, "AUIPC imm=max @ prog[2]"     );
endtask

// Classic li pattern using AUIPC+ADDI — tests EX→EX forwarding from AUIPC to ADDI
task automatic test_auipc_addi();
    $display("\n[AUIPC + ADDI]");
    init_prog();
    // prog[0]: PC=4, imm=0x1 → x1 = 0x1004
    // prog[1]: ADDI adds 0x678 → x1 = 0x167C  (EX→EX fwd)
    prog[0] = AUIPC(1, 20'h00001);    // x1 = 4 + 0x1000 = 0x1004
    prog[1] = ADDI(1, 1, 12'h678);    // x1 = 0x1004 + 0x678 = 0x167C
    // prog[2]: PC=12, imm=0, ADDI adds 0  → x2 = 12 (pure PC capture)
    prog[2] = AUIPC(2, 20'h00000);    // x2 = 12
    prog[3] = ADDI(2, 2,        0);    // x2 = 12 (no change)
    load_program(); do_reset(); run(25);
    check_reg(1, 32'h0000167C, "AUIPC+ADDI 0x1678+4"  );
    check_reg(2, 32'h0000000C, "AUIPC+ADDI pure PC"   );
endtask

// AUIPC results forwarded into ALU
task automatic test_auipc_forwarding();
    $display("\n[AUIPC forwarding]");
    init_prog();
    prog[0] = AUIPC(1, 20'h00002);   // x1 = 4  + 0x2000 = 0x2004
    prog[1] = AUIPC(2, 20'h00001);   // x2 = 8  + 0x1000 = 0x1008
    prog[2] = ADD(3, 1, 2);           // x3 = 0x2004 + 0x1008 = 0x300C (MEM→EX + EX→EX fwd)
    prog[3] = ADD(4, 3, 3);           // x4 = 0x600C * 2... wait: 0x300C+0x300C=0x6018
    load_program(); do_reset(); run(20);
    check_reg(1, 32'h00002004, "AUIPC fwd: x1"       );
    check_reg(2, 32'h00001008, "AUIPC fwd: x2"       );
    check_reg(3, 32'h0000300C, "AUIPC fwd: ADD x1+x2");
    check_reg(4, 32'h00006018, "AUIPC fwd: ADD x3+x3");
endtask
