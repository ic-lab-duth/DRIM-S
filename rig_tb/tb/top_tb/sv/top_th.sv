module top_th;

  timeunit      1ns;
  timeprecision 1ps;



  logic clock = 0;
  logic reset;

  IF_if     IF_if_0();   

  always #10 clock = ~clock;
  assign reset = IF_if_0.rst_n;
  assign IF_if_0.clk = clock;  


  module_top uut (
    .clk(clock),
    .rst_n(reset)
  );
      


  // ifetch agent
  assign IF_if_0.data_out            = uut.top_processor.ifetch.data_out;
  assign IF_if_0.valid_o             = uut.top_processor.ifetch.valid_o;
  assign IF_if_0.ready_in            = uut.top_processor.ifetch.ready_in;
  assign IF_if_0.is_branch           = uut.top_processor.ifetch.is_branch;
  assign IF_if_0.pr_update           = uut.top_processor.ifetch.pr_update;
  assign IF_if_0.invalid_instruction = uut.top_processor.ifetch.invalid_instruction;
  assign IF_if_0.invalid_prediction  = uut.top_processor.ifetch.invalid_prediction;
  assign IF_if_0.is_return_in        = uut.top_processor.ifetch.is_return_in;
  assign IF_if_0.is_jumpl            = uut.top_processor.ifetch.is_jumpl;
  assign IF_if_0.old_PC              = uut.top_processor.ifetch.old_pc;
  assign IF_if_0.must_flush          = uut.top_processor.ifetch.must_flush;
  assign IF_if_0.correct_address     = uut.top_processor.ifetch.correct_address;
  assign IF_if_0.current_PC          = uut.top_processor.ifetch.current_pc;
  assign IF_if_0.Hit_cache           = uut.top_processor.ifetch.hit_cache;
  assign IF_if_0.Miss                = uut.top_processor.ifetch.miss;
  assign IF_if_0.partial_access      = uut.top_processor.ifetch.partial_access;
  assign IF_if_0.partial_type        = uut.top_processor.ifetch.partial_type;
  assign IF_if_0.fetched_data        = uut.top_processor.ifetch.fetched_data;



endmodule

