`ifndef IF_SEQ_ITEM_SV
`define IF_SEQ_ITEM_SV
import dut_parameters_pkg::*;
class if_trans extends uvm_sequence_item; 

  `uvm_object_utils(if_trans)

  rand bit[FETCH_WIDTH-1:0] data;
  // Just for debug, remove this later
  static int trans_counter_dbg;
  int trans_id_dbg;

  function new(string name = "");
    super.new(name);
    trans_counter_dbg++;
    trans_id_dbg = trans_counter_dbg-1;
  endfunction : new

endclass : if_trans 


`endif
