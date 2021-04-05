assert property (@(posedge clk) disable iff(!rst_n) partial_access |-> 1'b1) else $warning("Half Access Detected, two cycle fetch needed");
assert property (@(posedge clk) disable iff(!rst_n) must_flush |-> !valid_o) else $error("IFetch - Error, wrong instruction injected in the pipeline");
assert property (@(posedge clk) disable iff(!rst_n) partial_access |-> (partial_type==2'b10)) else $error("IFetch - Dummy, wrong partial access type");


//=================================================================================
//BENCHMARKING COUNTER SECTION
logic [63:0] redir_realign, redir_prediction, redir_return, redirections, flushes, missed_branch;
logic        redirect, alignment_redirect, fnct_return_redirect, flush_redirect;

assign fnct_return_redirect = hit & ~valid_o & invalid_instruction;
assign alignment_redirect   = hit & ~valid_o & invalid_instruction;
assign redirect             = hit & ~valid_o;
assign flush_redirect       = hit & ~valid_o & must_flush;

always_ff @(posedge clk or negedge rst_n) begin : ReDir
    if(!rst_n) begin
        redir_realign    <= 0;
        redir_prediction <= 0;
        redir_return     <= 0;
        flushes          <= 0;
        redirections     <= 0;
        missed_branch    <= 0;
    end else begin
        if(alignment_redirect) begin
            redir_realign <= redir_realign +1;
        end
        if(invalid_prediction) begin
            redir_prediction <= redir_prediction +1;
        end
        if(fnct_return_redirect) begin
            redir_return <= redir_return +1;
        end
        if(flush_redirect) begin
            flushes <= flushes +1;
        end
        if(redirect) begin
            redirections <= redirections +1;
        end
        if(taken_branch_2 && valid_o && ready_in && !half_access) begin
            missed_branch <= missed_branch +1;
        end
    end
end