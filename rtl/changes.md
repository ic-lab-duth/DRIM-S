# Changes

## Superscalar

### decoder_full.sv

Added opcodes for vector and floating point instructions

### rr.sv

Added seperate free list for floating point registers (added parameters to rat.sv and free_list.sv to support floating point registers)

### issue.sv

Completely changed. Moved from scoreboard to reservation stations. Also added support for memory coherency between vector and supoerscalar. New modules are
smart_flow_control.sv that routes the data drom one multiported fifo (instruction queue) to many (reservation stations) and reservation_station.sv for Tomasulo's
algorithm

### execution.sv

Added support for floating point arithmetic (all files are in fpu folder)

### rob.sv

Removed data from rob. Now they are saved imediately at the register file after finishing execution

### data_cache.sv

Data cache is now write through instead of write back to support memory coherency with vector processor. Also added invalidate signal coming
from the vector processor

### main_mempry.sv

Added vector port and support for the different widths of vector stores

## Vector

All files are in vector folder

### alu.sv

New improved simd units (multiplier, adder, shifter and helpers). Added floating point unit and changed the decoding to support the new instructions

### requestor.sv

Now can load and store unitstride instructions with a single memory access (memory alignment is assumed). Added connections to the main_mempry.

### completer.sv

Not used anymore. Can be removed

## New files

all files in fpu and general folders


in root (rtl):
reservation_station.sv


in vector/vector_lane folder:
+ simd_adder.sv
+ simd_helpers.sv
+ simd_multiplier.sv
+ simd_shifter.sv
