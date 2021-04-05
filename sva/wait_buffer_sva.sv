assert property (@(posedge clk) disable iff(!rst_n) write_enable |-> ready) else $error("ERROR:WT Buffer: Push on Full");
