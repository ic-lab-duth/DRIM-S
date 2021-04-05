    assert property (@(posedge clk) disable iff(!rst_n) valid_i_2 |-> valid_i_1) else $fatal("RR: Illegal Scenario");
    assert property (@(posedge clk) disable iff(!rst_n) fl_push |-> fl_ready) else $fatal("RR: Push on full FL");

    //-----------------------------------------------------------------------------
    //BENCHMARKING COUNTER SECTION
    //-----------------------------------------------------------------------------

    logic [63:0] total_allocations, total_reclaims, reclaim_stalls, stalls_rob;
    always_ff @(posedge clk or negedge rst_n) begin : ReclaimStalls
        if(~rst_n) begin
            reclaim_stalls <= 0;
        end else begin
            if(reclaim_stall) begin
                reclaim_stalls <= reclaim_stalls +1;
            end
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin : Alloc
        if(~rst_n) begin
            total_allocations <= 0;
        end else begin
            if(do_alloc_1 && do_alloc_2) begin
                total_allocations <= total_allocations +2;
            end else if(do_alloc_1 || do_alloc_2) begin
                total_allocations <= total_allocations +1;
            end
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin : RECL
        if(~rst_n) begin
            total_reclaims <= 0;
        end else begin
            if(fl_push) begin
                total_reclaims <= total_reclaims +1;
            end
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin : RobStalls
        if(~rst_n) begin
            stalls_rob <= 0;
        end else begin
            if(rob_stall) begin
                stalls_rob <= stalls_rob+1;
            end
        end
    end
    //-----------------------------------------------------------------------------
    //DEBUGGING COUNTER SECTION
    //-----------------------------------------------------------------------------
    logic [$clog2(C_NUM)-1:0] branch_if;
    always_ff @(posedge clk or negedge rst_n) begin : BranchInFlight
        if(!rst_n) begin
            branch_if <= 0;
        end else begin
            if(flush_valid) begin
                branch_if <= 0;
            end else if(dual_branch && valid_o_2) begin
                if(!pr_update.valid_jump) begin
                    branch_if <= branch_if + 2;
                end else begin
                    branch_if <= branch_if + 1;
                end
            end else if(take_checkpoint) begin
                if(!pr_update.valid_jump) begin
                    branch_if <= branch_if + 1;
                end             
            end else if (pr_update.valid_jump && |branch_if) begin
                branch_if <= branch_if - 1;
            end
        end
    end

    assert property (@(posedge clk) disable iff(!rst_n) clk |-> !(branch_if>C_NUM)) else $fatal("RR: More branch in flight than max");
    assert property (@(posedge clk) disable iff(!rst_n) take_checkpoint |-> branch_if<C_NUM) else $fatal("RR: Max branch in flight reached");
    assert property (@(posedge clk) disable iff(!rst_n) (dual_branch && valid_o_2) |-> !(branch_if>C_NUM-2)) else $fatal("RR: Max branch in flight reached - 2");

    //Vector Assertions
    assert property (@(posedge clk) disable iff(!rst_n) (!VECTOR_ENABLED & valid_i_1) |-> !instruction_1.is_vector) else $fatal("RR: Invalid Vector Instruction 1");
    assert property (@(posedge clk) disable iff(!rst_n) (!VECTOR_ENABLED & valid_i_2) |-> !instruction_2.is_vector) else $fatal("RR: Invalid Vector Instruction 2");