#!/bin/bash
echo "ibex-DMS test bench run start!"
echo ""

# Navigate to reg-file module directory
cd ../peripheral

# if any error happens exit
set -e

# clean
rm -rf ibex_DMS.vvp
rm -rf ibex_DMS_wavedata.vcd

# compiling
iverilog -g2012 -o ibex_DMS_tb.vvp ibex_DMS_tb.sv

# run
vvp ibex_DMS_tb.vvp

echo ""
echo "ibex-DMS test bench run stopped!"