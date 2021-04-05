assert property (@(posedge clk) disable iff(rst) push |-> ready) else $fatal(1, "Pushing on full!");
assert property (@(posedge clk) disable iff(rst) pop_1 |-> valid_1) else $fatal(1, "Popping on empty!");

//-----------------------------------------------------------------------------
//DEBUGGING COUNTER SECTION
//-----------------------------------------------------------------------------
logic [63:0] total_pushes, total_pops;
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        total_pushes <= 0;
        total_pops   <= 0;
    end else begin
        if (single_push) begin
            total_pushes <= total_pushes +1;
            if (double_push) total_pushes <= total_pushes +2;
        end
        if (single_pop) begin
            total_pops <= total_pops +1;
        end
        if (double_pop) begin
            total_pops <= total_pops +2;
        end
    end
end