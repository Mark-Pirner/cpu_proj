#!/usr/bin/env bash
# Usage:
#   ./run_tb.bash          — compile, simulate, print results
#   ./run_tb.bash -w       — also open gtkwave after simulation
set -e

WAVE=0
for arg in "$@"; do
    case $arg in
        -w|--wave) WAVE=1 ;;
    esac
done

rm -f sim_tb_cpu

iverilog -g2012 -DLTB_EN -I../rtl -o sim_tb_cpu \
    ../rtl/cpu.v \
    tb_cpu.sv

vvp sim_tb_cpu

if [ $WAVE -eq 1 ]; then
    gtkwave tb_cpu.vcd &
fi
