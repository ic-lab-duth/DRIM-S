// You can insert code here by setting file_header_inc in file common.tpl

//=============================================================================
// Project  : generated_tb
//
// File Name: top_seq_lib.sv
//
//
// Version:   1.0
//
// Code created by Easier UVM Code Generator version 2016-08-11 on Mon Nov  5 13:07:21 2018
//=============================================================================
// Description: Sequence for top
//=============================================================================

`ifndef TOP_SEQ_LIB_SV
`define TOP_SEQ_LIB_SV
import tb_util_pkg::*;
class top_default_seq extends uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(top_default_seq)

  IF_agent     m_IF_agent;   

  // Number of times to repeat child sequences
  int m_seq_count = 1;

  extern function new(string name = "");
  extern task body();
  extern task pre_start();
  extern task post_start();
  extern task end_of_test();

`ifndef UVM_POST_VERSION_1_1
  // Functions to support UVM 1.2 objection API in UVM 1.1
  extern function uvm_phase get_starting_phase();
  extern function void set_starting_phase(uvm_phase phase);
`endif

endclass : top_default_seq


function top_default_seq::new(string name = "");
  super.new(name);
endfunction : new


task top_default_seq::body();
  `uvm_info(get_type_name(), "Default sequence starting", UVM_HIGH)

  // if(!ENABLE_ASSERTIONS) $assertkill;
  repeat (m_seq_count)
  begin
    fork
      if (m_IF_agent.m_config.is_active == UVM_ACTIVE)
      begin
        IF_default_seq seq;
        seq = IF_default_seq::type_id::create("seq");
        seq.set_item_context(this, m_IF_agent.m_sequencer);
        if ( !seq.randomize() )
          `uvm_error(get_type_name(), "Failed to randomize sequence")
        seq.set_starting_phase( get_starting_phase() );
        seq.start(m_IF_agent.m_sequencer, this);
      end
      begin 
        end_of_test();
      end
    join
  end

  `uvm_info(get_type_name(), "Default sequence completed", UVM_HIGH)
endtask : body

logic[31:0] last_pc;
int stall_cycles,counter;
task top_default_seq::end_of_test();
  last_pc = 0;
  while(counter<10000) begin 
    if((m_IF_agent.m_monitor.vif.current_PC==last_pc) && m_IF_agent.m_monitor.vif.Hit_cache) begin 
      counter++;
    end else begin 
      counter = 0;
    end
    last_pc = m_IF_agent.m_monitor.vif.current_PC;
    @(posedge m_IF_agent.m_config.vif.clk);
  end
endtask 


task top_default_seq::pre_start();
  uvm_phase phase = get_starting_phase();
  if (phase != null)
    phase.raise_objection(this);
endtask: pre_start


task top_default_seq::post_start();
  uvm_phase phase = get_starting_phase();
  if (phase != null) 
    phase.drop_objection(this);
endtask: post_start


`ifndef UVM_POST_VERSION_1_1
function uvm_phase top_default_seq::get_starting_phase();
  return starting_phase;
endfunction: get_starting_phase


function void top_default_seq::set_starting_phase(uvm_phase phase);
  starting_phase = phase;
endfunction: set_starting_phase
`endif


// You can insert code here by setting top_seq_inc in file common.tpl

`endif // TOP_SEQ_LIB_SV

