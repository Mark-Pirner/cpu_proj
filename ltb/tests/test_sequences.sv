// ─────────────────────────────────────────────────────────────────────────────
// AUIPC / SW combo test  (nl AUIPCs, ns stores, no NOPs)
//
// imm=0 so each AUIPC simply captures its PC.
// prog[i] has ifid_pc=(i+1)*4, so x(21+i) = (i+1)*4.
//
// Register map:  x21..x25 – AUIPC destinations
// Memory map:    DMEM[10..14] – output words from SW
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_auipc_sw(int nl, ns);
    int        auipc_val[5];
    int        sw_val  [5];
    int        pc;
    string     desc;

    $sformat(desc, "AUIPC%0d_SW%0d", nl, ns);
    $display("\n[Combo: %s]", desc);

    for (int i = 0; i < 5; i++)
        auipc_val[i] = (i + 1) * 4;   // ifid_pc for prog[i] = (i+1)*4, imm=0

    for (int k = 0; k < ns; k++)
        sw_val[k] = auipc_val[k % nl];

    init_prog();
    pc = 0;

    for (int i = 0; i < nl; i++) begin
        prog[pc] = AUIPC(5'(21 + i), 20'h00000);
        pc++;
    end

    for (int k = 0; k < ns; k++) begin
        prog[pc] = SW(5'(21 + (k % nl)), 5'd0, 12'((10 + k) * 4));
        pc++;
    end

    load_program();
    do_reset();
    run(40 + nl + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(10 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=%0d", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// AUIPC+ADDI / SW combo test  (nl li-pairs, ns stores, no NOPs)
//
// Each pair: AUIPC x(21+i), 0  then  ADDI x(21+i), x(21+i), (i+1)*7
// AUIPC at prog[2*i] → ifid_pc = (2*i+1)*4
// result[i] = (2*i+1)*4 + (i+1)*7
//
// Register map:  x21..x25 – AUIPC+ADDI destinations
// Memory map:    DMEM[10..14] – output words from SW
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_auipc_addi_sw(int nl, ns);
    int        result[5];
    int        sw_val[5];
    int        pc;
    string     desc;

    $sformat(desc, "AUIPC_ADDI%0d_SW%0d", nl, ns);
    $display("\n[Combo: %s]", desc);

    // AUIPC at prog[2*i]: ifid_pc = (2*i+1)*4, imm=0 → val = (2*i+1)*4
    // ADDI adds (i+1)*7
    for (int i = 0; i < 5; i++)
        result[i] = (2 * i + 1) * 4 + (i + 1) * 7;

    for (int k = 0; k < ns; k++)
        sw_val[k] = result[k % nl];

    init_prog();
    pc = 0;

    for (int i = 0; i < nl; i++) begin
        prog[pc]   = AUIPC(5'(21 + i), 20'h00000);
        prog[pc+1] = ADDI(5'(21 + i), 5'(21 + i), 12'((i + 1) * 7));  // EX→EX fwd
        pc += 2;
    end

    for (int k = 0; k < ns; k++) begin
        prog[pc] = SW(5'(21 + (k % nl)), 5'd0, 12'((10 + k) * 4));
        pc++;
    end

    load_program();
    do_reset();
    run(50 + 2 * nl + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(10 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=%0d", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// LUI / SW combo test  (nl LUIs, ns stores, no NOPs)
//
// Register map:  x21..x25 – LUI destinations
// Memory map:    DMEM[10..14] – output words from SW
//
// lui_val[i] = (i+1) << 12  →  0x1000, 0x2000, 0x3000, 0x4000, 0x5000
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_lui_sw(int nl, ns);
    int        lui_val[5];
    int        sw_val [5];
    int        pc;
    string     desc;

    $sformat(desc, "LUI%0d_SW%0d", nl, ns);
    $display("\n[Combo: %s]", desc);

    for (int i = 0; i < 5; i++)
        lui_val[i] = (i + 1) << 12;          // 0x1000, 0x2000, ...

    for (int k = 0; k < ns; k++)
        sw_val[k] = lui_val[k % nl];

    init_prog();
    pc = 0;

    for (int i = 0; i < nl; i++) begin
        prog[pc] = LUI(5'(21 + i), 20'(i + 1));   // x(21+i) = (i+1)<<12
        pc++;
    end

    for (int k = 0; k < ns; k++) begin
        prog[pc] = SW(5'(21 + (k % nl)), 5'd0, 12'((10 + k) * 4));
        pc++;
    end

    load_program();
    do_reset();
    run(40 + nl + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(10 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=0x%08X", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// LUI+ADDI / SW combo test  (nl li-pairs, ns stores, no NOPs)
//
// Each pair: LUI x(21+i), upper  then  ADDI x(21+i), x(21+i), lower
// The ADDI immediately follows the LUI for the same rd → EX→EX forward.
//
// Register map:  x21..x25 – LUI+ADDI destinations
// Memory map:    DMEM[10..14] – output words from SW
//
// result[i] = ((i+1) << 12) + (i+1)*7
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_lui_addi_sw(int nl, ns);
    int        result[5];
    int        sw_val[5];
    int        pc;
    string     desc;

    $sformat(desc, "LUI_ADDI%0d_SW%0d", nl, ns);
    $display("\n[Combo: %s]", desc);

    for (int i = 0; i < 5; i++)
        result[i] = ((i + 1) << 12) + (i + 1) * 7;   // e.g. 0x1007, 0x200E, ...

    for (int k = 0; k < ns; k++)
        sw_val[k] = result[k % nl];

    init_prog();
    pc = 0;

    for (int i = 0; i < nl; i++) begin
        prog[pc]   = LUI (5'(21 + i), 20'(i + 1));              // upper
        prog[pc+1] = ADDI(5'(21 + i), 5'(21 + i), 12'((i+1)*7)); // lower, EX→EX fwd
        pc += 2;
    end

    for (int k = 0; k < ns; k++) begin
        prog[pc] = SW(5'(21 + (k % nl)), 5'd0, 12'((10 + k) * 4));
        pc++;
    end

    load_program();
    do_reset();
    run(50 + 2*nl + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(10 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=0x%08X", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// I-type helper: apply one I-type op to an integer value
// itype: 0=ADDI(+5), 1=ANDI(&0x3F), 2=ORI(|0x100), 3=XORI(^0x00F),
//        4=SLLI(<<1), 5=SRLI(>>1), 6=SRAI(>>>1)
// ─────────────────────────────────────────────────────────────────────────────
function automatic int itype_apply(input int val, input int itype);
    case (itype)
        0: return val + 5;
        1: return val & 32'h3F;
        2: return val | 32'h100;
        3: return val ^ 32'h00F;
        4: return val << 1;
        5: return val >> 1;
        6: return val >>> 1;
        default: return val;
    endcase
endfunction

function automatic logic [31:0] itype_enc(
    input int        itype,
    input logic[4:0] rd, rs1
);
    case (itype)
        0: return ADDI(rd, rs1, 12'sd5);
        1: return ANDI(rd, rs1, 12'h03F);
        2: return ORI (rd, rs1, 12'h100);
        3: return XORI(rd, rs1, 12'h00F);
        4: return SLLI(rd, rs1, 5'd1);
        5: return SRLI(rd, rs1, 5'd1);
        6: return SRAI(rd, rs1, 5'd1);
        default: return NOP;
    endcase
endfunction

// ─────────────────────────────────────────────────────────────────────────────
// LW / I-type / SW combo test  (nl loads, ni I-type ops, ns stores, no NOPs)
//
// Register map:
//   x11..x15  – LW destinations  (loaded from DMEM[0..4])
//   x21..x25  – I-type results   (chained: x21=itype(x11), x22=itype(x21),...)
// Memory map:
//   DMEM[0..4]   – input  words (10,20,30,40,50)
//   DMEM[10..14] – output words from SW
// itype: 0=ADDI, 1=ANDI, 2=ORI, 3=XORI, 4=SLLI, 5=SRLI, 6=SRAI
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_lw_itype_sw(int nl, ni, ns, int itype);
    string     iname, desc;
    int        lw_val[5];
    int        it_val[5];
    int        sw_val[5];
    int        pc;

    case (itype)
        0: iname = "ADDI"; 1: iname = "ANDI"; 2: iname = "ORI";
        3: iname = "XORI"; 4: iname = "SLLI"; 5: iname = "SRLI";
        6: iname = "SRAI"; default: iname = "???";
    endcase
    $sformat(desc, "LW%0d_%s%0d_SW%0d", nl, iname, ni, ns);
    $display("\n[Combo: %s]", desc);

    for (int i = 0; i < 5; i++) lw_val[i] = (i + 1) * 10;

    it_val[0] = itype_apply(lw_val[0], itype);
    for (int j = 1; j < ni; j++)
        it_val[j] = itype_apply(it_val[j-1], itype);

    for (int k = 0; k < ns; k++)
        sw_val[k] = it_val[k % ni];

    init_prog();
    pc = 0;

    for (int i = 0; i < nl; i++) begin
        prog[pc] = LW(5'(11 + i), 5'd0, 12'(i * 4));
        pc++;
    end

    for (int j = 0; j < ni; j++) begin
        prog[pc] = itype_enc(itype, 5'(21 + j),
                             (j == 0) ? 5'd11 : 5'(20 + j));
        pc++;
    end

    for (int k = 0; k < ns; k++) begin
        prog[pc] = SW(5'(21 + (k % ni)), 5'd0, 12'((10 + k) * 4));
        pc++;
    end

    load_program();
    for (int i = 0; i < 5; i++)
        `DMEM[i] = 32'((i + 1) * 10);

    do_reset();
    run(50 + nl + ni + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(10 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=%0d", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// All 6 block-order permutations of LW / I-type / SW  (itype selects op)
//
// Register map:
//   x1..x5    – ADDI-initialized (7,14,21,28,35)
//   x11..x15  – LW destinations  (DMEM[0..4] = 10,20,30,40,50)
//   x21..x25  – I-type results
// Memory map:
//   DMEM[0..4]   – LW input words
//   DMEM[20..24] – SW output words
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_lw_itype_sw_perm(int nl, ni, ns, int itype, int perm);
    int  lw_pos, it_pos, sw_pos;
    bit  lw_before_it, lw_before_sw, it_before_sw;

    string     iname, pname, desc;
    int        init_val[5];
    int        lw_val  [5];
    int        it_val  [5];
    int        sw_val  [5];
    int        pc;
    int        slot_type[3];
    logic[4:0] it_src, sw_src;

    case (itype)
        0: iname = "ADDI"; 1: iname = "ANDI"; 2: iname = "ORI";
        3: iname = "XORI"; 4: iname = "SLLI"; 5: iname = "SRLI";
        6: iname = "SRAI"; default: iname = "???";
    endcase

    case (perm)
        0: begin lw_pos=0; it_pos=1; sw_pos=2; pname="LW_IT_SW"; end
        1: begin lw_pos=0; it_pos=2; sw_pos=1; pname="LW_SW_IT"; end
        2: begin lw_pos=1; it_pos=0; sw_pos=2; pname="IT_LW_SW"; end
        3: begin lw_pos=2; it_pos=0; sw_pos=1; pname="IT_SW_LW"; end
        4: begin lw_pos=1; it_pos=2; sw_pos=0; pname="SW_LW_IT"; end
        5: begin lw_pos=2; it_pos=1; sw_pos=0; pname="SW_IT_LW"; end
        default: begin lw_pos=0; it_pos=1; sw_pos=2; pname="UNKNOWN"; end
    endcase

    lw_before_it  = (lw_pos < it_pos);
    lw_before_sw  = (lw_pos < sw_pos);
    it_before_sw  = (it_pos < sw_pos);

    $sformat(desc, "%s_%s_nl%0d_ni%0d_ns%0d", pname, iname, nl, ni, ns);
    $display("\n[Perm: %s]", desc);

    for (int i = 0; i < 5; i++) begin
        init_val[i] = (i + 1) * 7;
        lw_val[i]   = (i + 1) * 10;
    end

    if (lw_before_it) begin
        it_val[0] = itype_apply(lw_val[0], itype);
        for (int j = 1; j < ni; j++)
            it_val[j] = itype_apply(it_val[j-1], itype);
    end else begin
        it_val[0] = itype_apply(init_val[0], itype);
        for (int j = 1; j < ni; j++)
            it_val[j] = itype_apply(it_val[j-1], itype);
    end

    for (int k = 0; k < ns; k++) begin
        if      (it_before_sw) sw_val[k] = it_val[k % ni];
        else if (lw_before_sw) sw_val[k] = lw_val[k % nl];
        else                   sw_val[k] = init_val[k % 5];
    end

    init_prog();
    pc = 0;

    for (int i = 0; i < 5; i++) begin
        prog[pc] = ADDI(5'(1 + i), 5'd0, 12'((i + 1) * 7));
        pc++;
    end

    slot_type[lw_pos] = 0;
    slot_type[it_pos] = 1;
    slot_type[sw_pos] = 2;

    for (int slot = 0; slot < 3; slot++) begin
        case (slot_type[slot])
            0: begin
                for (int i = 0; i < nl; i++) begin
                    prog[pc] = LW(5'(11 + i), 5'd0, 12'(i * 4));
                    pc++;
                end
            end
            1: begin
                for (int j = 0; j < ni; j++) begin
                    it_src = lw_before_it ? ((j == 0) ? 5'd11 : 5'(20 + j))
                                          : ((j == 0) ? 5'd1  : 5'(20 + j));
                    prog[pc] = itype_enc(itype, 5'(21 + j), it_src);
                    pc++;
                end
            end
            2: begin
                for (int k = 0; k < ns; k++) begin
                    if      (it_before_sw) sw_src = 5'(21 + (k % ni));
                    else if (lw_before_sw) sw_src = 5'(11 + (k % nl));
                    else                   sw_src = 5'(1  + (k % 5));
                    prog[pc] = SW(sw_src, 5'd0, 12'((20 + k) * 4));
                    pc++;
                end
            end
        endcase
    end

    load_program();
    for (int i = 0; i < 5; i++)
        `DMEM[i] = 32'((i + 1) * 10);

    do_reset();
    run(60 + nl + ni + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(20 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=%0d", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// R-type helpers
// rtype: 0=SLL, 1=SRL, 2=SRA, 3=SLTU, 4=ADD, 5=SUB, 6=AND, 7=OR, 8=XOR, 9=SLT
// ─────────────────────────────────────────────────────────────────────────────
function automatic int rtype_apply(input int a, input int b, input int rtype);
    case (rtype)
        0: return a << (b & 31);
        1: return a >> (b & 31);
        2: return a >>> (b & 31);
        3: return ($unsigned(a) < $unsigned(b)) ? 1 : 0;
        4: return a + b;
        5: return a - b;
        6: return a & b;
        7: return a | b;
        8: return a ^ b;
        9: return ($signed(a) < $signed(b)) ? 1 : 0;
        default: return a;
    endcase
endfunction

function automatic logic [31:0] rtype_enc(
    input int        rtype,
    input logic[4:0] rd, rs1, rs2
);
    case (rtype)
        0: return SLL_R (rd, rs1, rs2);
        1: return SRL_R (rd, rs1, rs2);
        2: return SRA_R (rd, rs1, rs2);
        3: return SLTU_R(rd, rs1, rs2);
        4: return ADD   (rd, rs1, rs2);
        5: return SUB   (rd, rs1, rs2);
        6: return AND_R (rd, rs1, rs2);
        7: return OR_R  (rd, rs1, rs2);
        8: return XOR_R (rd, rs1, rs2);
        9: return SLT_R (rd, rs1, rs2);
        default: return NOP;
    endcase
endfunction

// ─────────────────────────────────────────────────────────────────────────────
// LW / R-type(shift|sltu) / SW combo test  (nl loads, nr ops, ns stores)
//
// Chain: x21 = rtype(x11, x(11+1%nl)),  x22 = rtype(x21, x(11+2%nl)), ...
// Memory:  DMEM[0..4] input,  DMEM[10..14] output
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_lw_rtype_sw(int nl, nr, ns, int rtype);
    string     rname, desc;
    int        lw_val [5];
    int        rt_val [5];
    int        sw_val [5];
    int        pc;
    logic[4:0] ra_reg, rb_reg;

    case (rtype)
        0: rname = "SLL";  1: rname = "SRL";  2: rname = "SRA";
        3: rname = "SLTU"; 4: rname = "ADD";  5: rname = "SUB";
        6: rname = "AND";  7: rname = "OR";   8: rname = "XOR";
        9: rname = "SLT";  default: rname = "???";
    endcase
    $sformat(desc, "LW%0d_%s%0d_SW%0d", nl, rname, nr, ns);
    $display("\n[Combo: %s]", desc);

    for (int i = 0; i < 5; i++) lw_val[i] = (i + 1) * 10;

    rt_val[0] = rtype_apply(lw_val[0], lw_val[1 % nl], rtype);
    for (int j = 1; j < nr; j++)
        rt_val[j] = rtype_apply(rt_val[j-1], lw_val[(j + 1) % nl], rtype);

    for (int k = 0; k < ns; k++)
        sw_val[k] = rt_val[k % nr];

    init_prog();
    pc = 0;

    for (int i = 0; i < nl; i++) begin
        prog[pc] = LW(5'(11 + i), 5'd0, 12'(i * 4));
        pc++;
    end

    for (int j = 0; j < nr; j++) begin
        ra_reg = (j == 0) ? 5'd11 : 5'(20 + j);
        rb_reg = 5'(11 + ((j + 1) % nl));
        prog[pc] = rtype_enc(rtype, 5'(21 + j), ra_reg, rb_reg);
        pc++;
    end

    for (int k = 0; k < ns; k++) begin
        prog[pc] = SW(5'(21 + (k % nr)), 5'd0, 12'((10 + k) * 4));
        pc++;
    end

    load_program();
    for (int i = 0; i < 5; i++)
        `DMEM[i] = 32'((i + 1) * 10);

    do_reset();
    run(50 + nl + nr + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(10 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=%0d", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// All 6 permutations of LW / R-type / SW
//
// Register map:  x1..x5 ADDI-init (7,14,21,28,35),
//                x11..x15 LW,  x21..x25 R-type results
// Memory:  DMEM[0..4] input,  DMEM[20..24] output
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_lw_rtype_sw_perm(int nl, nr, ns, int rtype, int perm);
    int  lw_pos, rt_pos, sw_pos;
    bit  lw_before_rt, lw_before_sw, rt_before_sw;

    string     rname, pname, desc;
    int        init_val[5];
    int        lw_val  [5];
    int        rt_val  [5];
    int        sw_val  [5];
    int        pc;
    int        slot_type[3];
    logic[4:0] ra_reg, rb_reg, sw_src;

    case (rtype)
        0: rname = "SLL";  1: rname = "SRL";  2: rname = "SRA";
        3: rname = "SLTU"; 4: rname = "ADD";  5: rname = "SUB";
        6: rname = "AND";  7: rname = "OR";   8: rname = "XOR";
        9: rname = "SLT";  default: rname = "???";
    endcase

    case (perm)
        0: begin lw_pos=0; rt_pos=1; sw_pos=2; pname="LW_RT_SW"; end
        1: begin lw_pos=0; rt_pos=2; sw_pos=1; pname="LW_SW_RT"; end
        2: begin lw_pos=1; rt_pos=0; sw_pos=2; pname="RT_LW_SW"; end
        3: begin lw_pos=2; rt_pos=0; sw_pos=1; pname="RT_SW_LW"; end
        4: begin lw_pos=1; rt_pos=2; sw_pos=0; pname="SW_LW_RT"; end
        5: begin lw_pos=2; rt_pos=1; sw_pos=0; pname="SW_RT_LW"; end
        default: begin lw_pos=0; rt_pos=1; sw_pos=2; pname="UNKNOWN"; end
    endcase

    lw_before_rt  = (lw_pos < rt_pos);
    lw_before_sw  = (lw_pos < sw_pos);
    rt_before_sw  = (rt_pos < sw_pos);

    $sformat(desc, "%s_%s_nl%0d_nr%0d_ns%0d", pname, rname, nl, nr, ns);
    $display("\n[Perm: %s]", desc);

    for (int i = 0; i < 5; i++) begin
        init_val[i] = (i + 1) * 7;
        lw_val[i]   = (i + 1) * 10;
    end

    if (lw_before_rt) begin
        rt_val[0] = rtype_apply(lw_val[0], lw_val[1 % nl], rtype);
        for (int j = 1; j < nr; j++)
            rt_val[j] = rtype_apply(rt_val[j-1], lw_val[(j + 1) % nl], rtype);
    end else begin
        rt_val[0] = rtype_apply(init_val[0], init_val[1 % 5], rtype);
        for (int j = 1; j < nr; j++)
            rt_val[j] = rtype_apply(rt_val[j-1], init_val[(j + 1) % 5], rtype);
    end

    for (int k = 0; k < ns; k++) begin
        if      (rt_before_sw) sw_val[k] = rt_val[k % nr];
        else if (lw_before_sw) sw_val[k] = lw_val[k % nl];
        else                   sw_val[k] = init_val[k % 5];
    end

    init_prog();
    pc = 0;

    for (int i = 0; i < 5; i++) begin
        prog[pc] = ADDI(5'(1 + i), 5'd0, 12'((i + 1) * 7));
        pc++;
    end

    slot_type[lw_pos] = 0;
    slot_type[rt_pos] = 1;
    slot_type[sw_pos] = 2;

    for (int slot = 0; slot < 3; slot++) begin
        case (slot_type[slot])
            0: begin
                for (int i = 0; i < nl; i++) begin
                    prog[pc] = LW(5'(11 + i), 5'd0, 12'(i * 4));
                    pc++;
                end
            end
            1: begin
                for (int j = 0; j < nr; j++) begin
                    ra_reg = lw_before_rt ? ((j == 0) ? 5'd11 : 5'(20 + j))
                                          : ((j == 0) ? 5'd1  : 5'(20 + j));
                    rb_reg = lw_before_rt ? 5'(11 + ((j + 1) % nl))
                                          : 5'(1  + ((j + 1) % 5));
                    prog[pc] = rtype_enc(rtype, 5'(21 + j), ra_reg, rb_reg);
                    pc++;
                end
            end
            2: begin
                for (int k = 0; k < ns; k++) begin
                    if      (rt_before_sw) sw_src = 5'(21 + (k % nr));
                    else if (lw_before_sw) sw_src = 5'(11 + (k % nl));
                    else                   sw_src = 5'(1  + (k % 5));
                    prog[pc] = SW(sw_src, 5'd0, 12'((20 + k) * 4));
                    pc++;
                end
            end
        endcase
    end

    load_program();
    for (int i = 0; i < 5; i++)
        `DMEM[i] = 32'((i + 1) * 10);

    do_reset();
    run(60 + nl + nr + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(20 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=%0d", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// Parametric LW/ADD/SW combo test (125 combos, no NOPs)
//
// Register map:
//   x11..x15  – LW destinations  (loaded from DMEM[0..4])
//   x21..x25  – ADD destinations  (chained accumulator)
// Memory map:
//   DMEM[0..4]   – input  words for LW  (values 10,20,30,40,50)
//   DMEM[10..14] – output words from SW (checked after run)
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_lw_add_sw(int nl, na, ns);
    int        lw_val [5];
    int        add_val[5];
    int        sw_val [5];
    int        pc;
    logic[4:0] ra_reg, rb_reg;
    string     desc;

    $sformat(desc, "LW%0d_ADD%0d_SW%0d", nl, na, ns);
    $display("\n[Combo: %s]", desc);

    // ── expected values ───────────────────────────────────────────────────
    for (int i = 0; i < 5; i++) lw_val[i] = (i + 1) * 10;   // 10,20,30,40,50

    // ADD chain: x21 = x11 + x(11 + 1%nl),  x22 = x21 + x(11 + 2%nl), ...
    add_val[0] = lw_val[0] + lw_val[1 % nl];
    for (int j = 1; j < na; j++)
        add_val[j] = add_val[j-1] + lw_val[(j + 1) % nl];

    // SW sources cycle through ADD results
    for (int k = 0; k < ns; k++)
        sw_val[k] = add_val[k % na];

    // ── build instruction sequence ────────────────────────────────────────
    init_prog();
    pc = 0;

    // nl LW instructions  (x11..x10+nl from DMEM[0..nl-1])
    for (int i = 0; i < nl; i++) begin
        prog[pc] = LW(5'(11 + i), 5'd0, 12'(i * 4));
        pc++;
    end

    // na ADD instructions  (chained; first uses x11 as first operand)
    for (int j = 0; j < na; j++) begin
        ra_reg = (j == 0) ? 5'd11 : 5'(20 + j);
        rb_reg = 5'(11 + ((j + 1) % nl));
        prog[pc] = ADD(5'(21 + j), ra_reg, rb_reg);
        pc++;
    end

    // ns SW instructions  (store ADD results at DMEM[10..10+ns-1])
    for (int k = 0; k < ns; k++) begin
        prog[pc] = SW(5'(21 + (k % na)), 5'd0, 12'((10 + k) * 4));
        pc++;
    end

    // ── load, run, check ─────────────────────────────────────────────────
    load_program();
    // pre-init DMEM input words (load_program clears DMEM first)
    for (int i = 0; i < 5; i++)
        `DMEM[i] = 32'((i + 1) * 10);

    do_reset();
    run(50 + nl + na + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(10 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=%0d", desc, k, sw_val[k]));
endtask

// ─────────────────────────────────────────────────────────────────────────────
// All 6 block-order permutations of LW / ADD / SW  (750 combos total)
//
// Register map:
//   x1..x5    – ADDI-initialized  (7, 14, 21, 28, 35)  – always available
//   x11..x15  – LW destinations   (DMEM[0..4] = 10,20,30,40,50)
//   x21..x25  – ADD destinations  (chained accumulator)
// Memory map:
//   DMEM[0..4]   – LW input  words
//   DMEM[20..24] – SW output words (checked after run)
//
// Source selection rules (no NOPs, so pipeline must handle all hazards):
//   ADD: uses LW results when LW precedes ADD, else ADDI values
//   SW:  uses ADD results when ADD precedes SW,
//        LW results when LW precedes SW (but ADD does not),
//        else ADDI values
// ─────────────────────────────────────────────────────────────────────────────
task automatic test_lw_add_sw_perm(int nl, na, ns, perm);
    int  lw_pos, add_pos, sw_pos;
    bit  lw_before_add, lw_before_sw, add_before_sw;

    int        init_val[5];
    int        lw_val  [5];
    int        add_val [5];
    int        sw_val  [5];
    int        pc;
    int        slot_type[3];
    logic[4:0] ra_reg, rb_reg, sw_src;
    string     pname, desc;

    // ── decode permutation (block execution order: pos 0 = first) ────────
    case (perm)
        0: begin lw_pos=0; add_pos=1; sw_pos=2; pname="LW_ADD_SW"; end
        1: begin lw_pos=0; add_pos=2; sw_pos=1; pname="LW_SW_ADD"; end
        2: begin lw_pos=1; add_pos=0; sw_pos=2; pname="ADD_LW_SW"; end
        3: begin lw_pos=2; add_pos=0; sw_pos=1; pname="ADD_SW_LW"; end
        4: begin lw_pos=1; add_pos=2; sw_pos=0; pname="SW_LW_ADD"; end
        5: begin lw_pos=2; add_pos=1; sw_pos=0; pname="SW_ADD_LW"; end
        default: begin lw_pos=0; add_pos=1; sw_pos=2; pname="UNKNOWN"; end
    endcase

    lw_before_add = (lw_pos  < add_pos);
    lw_before_sw  = (lw_pos  < sw_pos);
    add_before_sw = (add_pos < sw_pos);

    $sformat(desc, "%s_nl%0d_na%0d_ns%0d", pname, nl, na, ns);
    $display("\n[Perm: %s]", desc);

    // ── expected values ───────────────────────────────────────────────────
    for (int i = 0; i < 5; i++) begin
        init_val[i] = (i + 1) * 7;   // x1=7, x2=14, x3=21, x4=28, x5=35
        lw_val[i]   = (i + 1) * 10;  // x11=10, x12=20, ..., x15=50
    end

    // ADD chain
    if (lw_before_add) begin
        add_val[0] = lw_val[0] + lw_val[1 % nl];
        for (int j = 1; j < na; j++)
            add_val[j] = add_val[j-1] + lw_val[(j + 1) % nl];
    end else begin
        add_val[0] = init_val[0] + init_val[1 % 5];
        for (int j = 1; j < na; j++)
            add_val[j] = add_val[j-1] + init_val[(j + 1) % 5];
    end

    // SW sources
    for (int k = 0; k < ns; k++) begin
        if      (add_before_sw) sw_val[k] = add_val[k % na];
        else if (lw_before_sw)  sw_val[k] = lw_val[k % nl];
        else                    sw_val[k] = init_val[k % 5];
    end

    // ── build instruction sequence ────────────────────────────────────────
    init_prog();
    pc = 0;

    // ADDI pre-init: x1..x5 = 7,14,21,28,35
    for (int i = 0; i < 5; i++) begin
        prog[pc] = ADDI(5'(1 + i), 5'd0, 12'((i + 1) * 7));
        pc++;
    end

    // Map slot positions → block types (0=LW, 1=ADD, 2=SW)
    slot_type[lw_pos]  = 0;
    slot_type[add_pos] = 1;
    slot_type[sw_pos]  = 2;

    for (int slot = 0; slot < 3; slot++) begin
        case (slot_type[slot])
            0: begin  // ── LW block ──────────────────────────────────────
                for (int i = 0; i < nl; i++) begin
                    prog[pc] = LW(5'(11 + i), 5'd0, 12'(i * 4));
                    pc++;
                end
            end
            1: begin  // ── ADD block ─────────────────────────────────────
                for (int j = 0; j < na; j++) begin
                    if (lw_before_add) begin
                        ra_reg = (j == 0) ? 5'd11 : 5'(20 + j);
                        rb_reg = 5'(11 + ((j + 1) % nl));
                    end else begin
                        ra_reg = (j == 0) ? 5'd1 : 5'(20 + j);
                        rb_reg = 5'(1 + ((j + 1) % 5));
                    end
                    prog[pc] = ADD(5'(21 + j), ra_reg, rb_reg);
                    pc++;
                end
            end
            2: begin  // ── SW block ──────────────────────────────────────
                for (int k = 0; k < ns; k++) begin
                    if      (add_before_sw) sw_src = 5'(21 + (k % na));
                    else if (lw_before_sw)  sw_src = 5'(11 + (k % nl));
                    else                    sw_src = 5'(1  + (k % 5));
                    prog[pc] = SW(sw_src, 5'd0, 12'((20 + k) * 4));
                    pc++;
                end
            end
        endcase
    end

    // ── load, run, check ─────────────────────────────────────────────────
    load_program();
    for (int i = 0; i < 5; i++)
        `DMEM[i] = 32'((i + 1) * 10);

    do_reset();
    run(60 + nl + na + ns);

    for (int k = 0; k < ns; k++)
        check_dmem(8'(20 + k), 32'(sw_val[k]),
                   $sformatf("%s SW[%0d]=%0d", desc, k, sw_val[k]));
endtask

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
