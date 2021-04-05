assert property (@(posedge clk) disable iff(!rst_n) must_restart_32a |-> !invalid_instruction_a) else $warning("Decoder: weird scenario : check old_PC priority");
assert property (@(posedge clk) disable iff(!rst_n) must_restart_32a |-> !is_jumpl_out) else $warning("Decoder: weird scenario : check old_PC priority");
assert property (@(posedge clk) disable iff(!rst_n) invalid_instruction_a |-> !must_restart_32a) else $warning("Decoder: weird scenario : check old_PC priority");
assert property (@(posedge clk) disable iff(!rst_n) invalid_instruction_a |-> !is_jumpl_out) else $warning("Decoder: weird scenario : check old_PC priority");
assert property (@(posedge clk) disable iff(!rst_n) is_jumpl_out |-> !must_restart_32a) else $warning("Decoder: weird scenario : check old_PC priority");
assert property (@(posedge clk) disable iff(!rst_n) is_jumpl_out |-> !invalid_instruction_a) else $warning("Decoder: weird scenario : check old_PC priority");