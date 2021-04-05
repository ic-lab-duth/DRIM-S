assert property (@(posedge clk) disable iff(!rst_n) CALC_CYCLES>1) else $error("division: CALC_CYCLES must be >1 ");
