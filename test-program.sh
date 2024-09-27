#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Usage: $0 <program_file>"
    exit 1
fi

# if any error happens exit
set -e

cd assembler

rm -f *.out

gcc RV32IMAssembler.c -o RV32IMAssembler.out

./RV32IMAssembler.out ../$1

cd ../peripheral

# # remove old instr_mem.mem and create new one to store instruction memory content
rm -f ram.vmem
touch ram.vmem

# # generate instruction memory content to be loaded into instr_mem array in Verilog (inside cpu.v)
while read line
do

    #echo $line
    byte3=$(echo $line | cut -c1-8)
    byte2=$(echo $line | cut -c9-16)
    byte1=$(echo $line | cut -c17-24)
    byte0=$(echo $line | cut -c25-32)
    echo $byte3" "$byte2" "$byte1" "$byte0 >> ram.vmem

done < "../program.machine"

echo "Instruction memory content generated!"
echo ""

cd ../scripts

./test-ibex-DMS.sh

cd ..

gtkwave wavedata_sample.gtkw