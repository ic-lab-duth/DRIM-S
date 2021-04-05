# Overview
This directory contains all the synthesisable RTL files.

All the parameters regarding the design can be found inside the `module_top.sv` file as local paraemters. Note that only a subset of them are tunable, as mentioned in the comments inside the file.

Any structs used in the datapath can be found inside the `structs.sv` file.

## Additional notes

Included to generate an FPGA demo.:
- Frame buffer peripheral (address 0xffff0000)
- VGA control logic

Design has been tested on the following tools:
- Questa & Modelsim
- Quartus (RTL needs slight modifications on `main_memory.sv` to load a memory.mif)

### Super Scalar Datapath

The following table lists the major units in the vector datapath and their operation

|  Unit Name  | Details                                                                                                  |
|:----------------:|-----------------------------------------------------------------------------------------------------|
| ifetch             | The instruction fetch stage, containing the branch predictors and the instruction cache                     |
| idedoce              | The instruction decode stage, containing the two full decoders and the pipeline flush controller|
| rr              | The register renaming stage, containing the register alias table and free list |
| issue              |The instruction issuing stage, containing the scoreboard and register file, as well as the hazarding logic for the multi-issuing functionality                     |
| execution         | The execution portion of the pipeline, containing the various functional units |
| rob              | The reorder buffer, used to enforce in-order retirement |


### ISA instructions

The list of the currently supported operations (ISA Version 20191213):

|  RV32I Base Instruction Set  | Multiplication and Division  |
|:-------------------:|:-------------------:|
| LUI   | MUL		|
| AUIPC | MULH		|
| JAL   | MULHSU	|
| JALR	| MULHU 	|
| BEQ	| DIV 		|
| BNE	| DIVU		|
| BLT	| REM		|
| BGE	| REMU		|
| BLTU	|			|
| BGETU |			|
| LB 	|			|
| LH	|			|
| LW	|			|
| LBU	|			|
| LHU	|			|
| SB	|			|
| SH	|			|
| SW	|			|
| ADDI	|			|
| SLTI	|			|
| SLTU	|			|
| XORI	|			|
| ORI	|			|
| ANDI	|			|
| SLLI	|			|
| SRLI |
| SRAI |
| ADD |
| SUB |
| SLL |
| SLT |
| SLTU |
| XOR |
| SRL |
| SRA |
| OR |
| AND |






















