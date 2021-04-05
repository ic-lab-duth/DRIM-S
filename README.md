# Overview
A 6-stage core, 2-Wide Superscalar, implementing the RiscV ISA (RV32IM).
Features:
- Dual Fetch & Dual Issue
- Dynamic Branch Prediction
- Register Renaming Scheme
- OoO Execution
- Non-blocking data cache

 ![overview](/images/riscv_core_ss.png)


### Directory Hierarchy

The folder hierarchy is organised as follows:
- `images`: schematics
- `rtl` : contains all the synthesisable RTL files
- `sva` : contains related x-checks and assertions for the design
- `rig_tb` : contains the Random Instruction Generator and associated TB environment
- `sim` : contains scripts for running in Questasim

## Repo State

### Current State & Limitations

- Support for "RV32I" Base Integer Instruction Set
- Support for “M” Standard Extension for Integer Multiplication and Division
- Verification status: Unit verification & Top level verification has taken place
- Partially implemented: Decode for additional instructions that are not yet supported (System, floating point, CSR) and exception detection
- The svas present have only been using in simulation and not in any formal verification process

### Future Optimisations
- Replace MUL/DIV units with optimised hardware, to reduce execution latency and decompress a lot of the paths

### Future Work
- Floating Point & Fixed point arithmetic
- CSR, SYSTEM instructions and Priviledged ISA
- Exception detection and Interrupt handling
- Virtual Memory
- 64bit support
- Align to future versions of the RISC-V ISA. Current document version supported is *20191213* of the Unpriviledged ISA manual


## How to Compile

The `/sim` directory is used for the simulation flow and it contains detailed instructions for both the flow and compiling C code. That way you can generate your own executable file and convert it to a memory file suitable for the CPU. Examples (code and precompiled files) are included in the `/sim/examples` directory.

_**To compile:**_
- include a compiled `memory.txt` file inside the `/sim` directory
- run the `compile.do` in questa with: "`do compile.do`"


The testbench hierarchy can be seen below:

_**TB Level Hierarchy:**_
->`tb` -> `module_top` -> `Processor_Top`

|  Hierarchy Name  | Details                                                                                             |
|:----------------:|-----------------------------------------------------------------------------------------------------|
| tb            | top level of the TB, instantiating the datapath |
| module_top    | The top level of the cpu datapath, connecting the memories and the surrounding logic with the core |
| processor_top       | The top level of the core datapath |

## Run the RIG TB

A second testbench environment is provided inside `/rig_tb`, featuring a Random Instruction Generator (RIG). For more information on how to setup, configure and run the testbench consult the README inside its directory.

# License
This project is licensed under the [MIT License](./LICENSE).