rm -rf top_inst.vcd sim_top
iverilog -DLTB_ENV -I../rtl -o sim_top ../rtl/cpu.v tb_top.v
vvp sim_top
gtkwave top_inst.vcd