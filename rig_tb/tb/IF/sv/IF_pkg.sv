// You can insert code here by setting file_header_inc in file common.tpl

//=============================================================================
// Project  : generated_tb
//
// File Name: IF_pkg.sv
//
//
// Version:   1.0
//
// Code created by Easier UVM Code Generator version 2016-08-11 on Mon Nov  5 13:07:21 2018
//=============================================================================
// Description: Package for agent IF
//=============================================================================

package IF_pkg;

  `include "uvm_macros.svh"

  import uvm_pkg::*;


  `include "IF_if_trans.sv"
  `include "IF_config.sv"
  `include "IF_driver.sv"
  `include "IF_monitor.sv"
  `include "IF_sequencer.sv"
  `include "IF_coverage.sv"
  `include "IF_Checker_utils.sv"
  `include "IF_Checker.sv"
  `include "IF_agent.sv"
  `include "IF_seq_lib.sv"

endpackage : IF_pkg
