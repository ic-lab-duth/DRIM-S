assert property (@(posedge clk) disable iff(!rst_n) (valid_o && is_branch) |-> !(branch_if==MAX_BRANCH_IF)) else $error("Dispatched Branch while maximum branch in flight");
assert property (@(posedge clk) disable iff(!rst_n) (valid_o && two_branches) |-> !(branch_if>MAX_BRANCH_IF-2)) else $error("Dispatched two Branches while maximum branch in flight");

//-----------------------------------------------------------------------------
//BENCHMARKING COUNTER SECTION
//-----------------------------------------------------------------------------
logic [63:0] branch_stalls;
always_ff @(posedge clk or negedge rst_n) begin : BStalls
    if(~rst_n) begin
        branch_stalls <= 0;
    end else begin
        if(valid_i && branch_stall) begin
            branch_stalls <= branch_stalls+1;
        end
    end
end