# Random Instruction Generator (RIG) TB 
The goal of any random instruction generator used for verification purposes is to provide instruction sequences that can effectively hit all the architectural features of the processor, including rarely encountered corner cases. Toward this goal, the employed instruction generator can
provide both instruction-level randomization (e.g., for each instruction, cover all possible operands and immediate values), and sequence-level randomization (instruction ordering and dependencies).


## Configuration of RIG
To provide extensive flexibility to the instruction sequence generation process, the generator is governed by a rich set of parameters, which are listed below:

### Type of instructions
- Shifts: Probability of an instruction being a logical or an arithmetic shift.
- Compares: Probability of an instruction being a comparison instruction.
- Arithmetic & Logical: Probability of an instruction being an arithmetic (add, subtract etc.) or a logical operation.
- Loads: Probability of an instruction being a load.
- Stores: Probability of an instruction being a store.

### Dependencies
- Read-After-Write (RAW) hazard rate: Probability that the generated instruction is involved in a RAW hazard.
- Write-After-Read (WAR) hazard rate: Probability that the generated instruction is involved in a WAR hazard.
- Write-After-Write (WAW) hazard rate: Probability that the generated instruction is involved in a WAW hazard.

### Loops and Branches
- For loop rate: Probability to generate a for-loop code structure that involves a random number of iterations.
- Nested loop rate: Probability to generate a nested loop inside a loop.
- Forward branch rate: Probability to generate a forward branch.

## How to run 
You can configure the parameters (mentioned above) for your simulation here:
```
rig_tb/sim/simulation_parameters_pkg.sv
```

In order to compile the TB and run a simulation:
```
cd rig_tb/sim
do compile_questa.do
```

The Random Instruction Generated generates 2 files. The <b>instructions.txt</b> which demonstrates the generated random instructions that will be executed, and also the <b>memory.txt</b> which depicts the actual contents of the memory in hex format.

Waves will be dumped inside the sim folder.