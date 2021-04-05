assert property (@(posedge clk) disable iff(!rst_n) fifo_pop |-> fifo_valid) else $error("FlushController: Pop'ed on Empty FIFO");
assert property (@(posedge clk) disable iff(!rst_n) capture_1 |-> fifo_ready) else $error("FlushController: Push'ed on Full FIFO");
assert property (@(posedge clk) disable iff(!rst_n) (capture_1 & capture_2) |-> fifo_ready_2) else $error("FlushController: Push'ed on Full FIFO 2");
assert property (@(posedge clk) disable iff(!rst_n) delayed_capture |-> !pr_update.valid_jump) else $fatal("FC: Scenario not implemented");

assert property (@(posedge clk) disable iff(!rst_n) pr_update.valid_jump |-> !pr_update.is_comp) else $fatal("FC: Scenario cannot happen with non-compressed instrs");