// You can insert code here by setting file_header_inc in file common.tpl

//=============================================================================
// Project  : generated_tb
//
// File Name: IF_driver.sv
//
//
// Version:   1.0
//
// Code created by Easier UVM Code Generator version 2016-08-11 on Mon Nov  5 13:07:21 2018
//=============================================================================
// Description: Driver for IF
//=============================================================================

`ifndef IF_DRIVER_SV
`define IF_DRIVER_SV

// You can insert code here by setting driver_inc_before_class in file if.tpl

class IF_driver extends uvm_driver #(if_trans);

  `uvm_component_utils(IF_driver)

  virtual IF_if vif;

  extern function new(string name, uvm_component parent);

  // You can insert code here by setting driver_inc_inside_class in file if.tpl

endclass : IF_driver 


function IF_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


// You can insert code here by setting driver_inc_after_class in file if.tpl

`endif // IF_DRIVER_SV

