assert property (@(posedge clk) disable iff(!rst_n) (hit) |-> !(partial_type == 1 | partial_type == 3)) else $warning("ICache: can not be aligned to 16 bit boundaries");
