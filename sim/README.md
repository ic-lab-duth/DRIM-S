# Overview

This directory contains the testing framework for the Risc-V core.
- The top testbench file `tb.sv` instantiates the core and creates log files
- `module_top.sv` imports a memory file with a pre-compiled program to the main memory. An example `memory.txt` is located in this directory

To run the simulation on Modelsim/Questasim 2 script files are provided.
- Open Questasim and navigate to the `sim` directory
- Execute `do compile.do` to build the RTL and enter the simulation
- A wave window will appear with pre-loaded signals, stated in the `wave.do` file
- Run the simulation, 2 log files with be created and updated with information on the commited and flushed instructions `commits.txt` and `flushes.txt`
- The `tb.sv` tries to detect when the programs finishes or crashes, by detecting consecutive jumps to the same PC address. While this detection generally works, it might fail depending on the PC alignment and branch predictor training

We use 2 flags on the RTL
- _MODEL_TECH_ to include the `structs.sv`,  this is defined by default on Questasim
- _INCLUDE_SVAS_ to include the related sva, this is defined optionally on `compile.do`


# Compile C code and generate Memory File

This directory contains various examples. We provide precompiled files (*.elf) and the equivalent memory files (memory.txt). Bellow we also provide instructions on how to generate your own files.

### Before compiling you need
- the RISC-V GNU Compiler Toolchain ([link](https://github.com/riscv/riscv-gnu-toolchain)). Clone the repo and install by running
```
./configure --prefix=/opt/riscv --enable-multilib
make
```
- a utility named elf2hex ([link](https://github.com/sifive/elf2hex)) provided by sifive to convert the elf file to a supported memory file. Clone the repo and follow the instructions
```
git clone git://github.com/sifive/elf2hex.git
cd elf2hex
autoreconf -i
./configure --target=riscv64-unknown-elf
make
make install
```
- a linker script, lscript
- a bootloader assembly code that calls the main()
- the C code

### Compile
```
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -T lscript  bootstrap.s notmain.c -o hello.elf  -nostdlib
```
- Replace `notmain.c` with your own C files and modify the `lscript` and `bootstrap.s`
- include flags, for example optimization (-O)
- Tested with version `riscv64-unknown-elf-gcc (GCC) 8.2.0`

### Convert elf to memory

```
riscv64-unknown-elf-elf2hex --bit-width 512 --input hello.elf --output memory.txt
```

### Recover the assembly

```
riscv64-unknown-elf-objdump -D hello.elf >FINAL.objdump -f
```


### Compile step by step

This is a more detailed version of the riscv64-unknown-elf-gcc command. We can compile each file and then link them all together.

Assembly code
```
riscv64-unknown-elf-as -march=rv32im -mabi=ilp32  bootstrap.s -o bootstrap.o
```
C code
```
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32  -c notmain.c -O2 -o notmain.o
```
Link
```
riscv64-unknown-elf-ld -T lscript -m elf32lriscv bootstrap.o notmain.o -o hello.elf
```

### Notes

Median example operates on a matlab generated image stored after the 3d line of the memory. The image is also included separately at `image.txt`.