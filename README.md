# VHDL MIPS Processor
This little project is an implementation of a MIPS-like processor in VHDL using Altera's FPGA technology

This project implements the following instructions :
  - ADD $DestReg, $Reg1, $Reg2
  - ADDI $DestReg, $Reg1, Constant
  - NOR $DestReg, $Reg1, $Reg2
  - AND $DestReg, $Reg1, $Reg2
  - BEQ $Reg1, $Reg2, Jump_to_line
  - JUMP Jump_to_line
  - LOAD $DestReg, $RAM_ADDR
  - STORE $SourceReg, $RAM_ADDR
  - SLT $RSet, $R1, $R2
  - IN $DestReg
  - OUT $SourceReg
  - MOVE $DestReg, $SourceReg
  - BGT $Reg1, $Reg2, Jump_to_line

The chosen architecture is depicted in the following figure (Check MIPSProcessorDoc.pdf ti have all information about this project)

![alt text](https://github.com/gabriel-f-o/VHDL_MIPS_Processor/blob/master/LaTeX%20Source%20Code/MIPSProcessor.png)

In this project you will find all source codes ready to be compiled and simulated, as well as a project for testing and debuging
