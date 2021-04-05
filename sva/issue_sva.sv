assert property (@(posedge clk) disable iff(!rst_n) valid_2 |-> valid_1) else $warning("Issue: Illegal Scenario");
assert property (@(posedge clk) disable iff(!rst_n) flush_valid |-> !(valid_1 | valid_2)) else $warning("Issue: Illegal Scenario on flush");

//-----------------------------------------------------------------------------
//BENCHMARKING COUNTER SECTION
//-----------------------------------------------------------------------------
logic [63:0] total_issues, dual_issues, hazards, stalls;
logic [63:0] vector_issues;
logic        hazard_1, stall;

always_ff @(posedge clk or negedge rst_n) begin : TotalIssues
    if(!rst_n) begin
        total_issues <= 0;
    end else begin
        if(wr_en_1) begin
            total_issues <= total_issues +1;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin : DualIssues
    if(!rst_n) begin
        dual_issues <= 0;
    end else begin
        if(wr_en_2) begin
            dual_issues <= dual_issues +1;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin : VectorInstr
    if(!rst_n) begin
        vector_issues <= 0;
    end else begin
        if(vector_wr_en) begin
            vector_issues <= vector_issues +1;
        end
    end
end

assign hazard_1 = Instruction1.is_valid & valid_1 & ~rd_ok_Ia & src1_ok_Ia & src2_ok_Ia & fu_ok_Ia;
always_ff @(posedge clk or negedge rst_n) begin : Hazards
	if(!rst_n) begin
		hazards <= 0;
	end else begin
		if(hazard_1) begin
			hazards <= hazards +1;
		end
	end
end
assign stall = ~valid_1;
always_ff @(posedge clk or negedge rst_n) begin : Stalls
	if(!rst_n) begin
		stalls <= 0;
	end else begin
		if(stall) begin
			stalls <= stalls +1;
		end
	end
end