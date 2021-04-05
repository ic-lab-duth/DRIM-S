package top_pkg;

  `include "uvm_macros.svh"

  import uvm_pkg::*;

  import IF_pkg::*;

  typedef bit [31:0] rf_array[32];
  
  
  // Instruction driver
  `include "../../INSTRUCTION_GENERATOR/sv/instruction_generator/instruction.sv"
  `include "../../INSTRUCTION_GENERATOR/sv/instruction_generator/instruction_generator.sv"
  `include "../../INSTRUCTION_GENERATOR/sv/driver.sv"
  
  `include "top_config.sv"
  `include "top_seq_lib.sv"
  `include "top_env.sv"

endpackage : top_pkg

