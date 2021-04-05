//Can not Pop from an empty RAS
assert property (@(posedge clk) disable iff(!rst_n) pop |-> !is_empty) else $error("Pop from Empty RAS!!");