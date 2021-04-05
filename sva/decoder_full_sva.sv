//-----------------------------------------------------------------------------
//BENCHMARKING COUNTER SECTION
//-----------------------------------------------------------------------------
logic [63:0] bypass_cntr;
logic        bypass, could_bypass;
logic        rd_ok, rs1_ok, rs2_ok;

assign bypass       = could_bypass & valid_map & valid & second_port_free;
assign could_bypass = rd_ok & rs1_ok & rs2_ok;
assign rd_ok        = (outputs.destination < 8) | (outputs.destination > 15);
assign rs1_ok       = (outputs.source1 < 8) | (outputs.source1 > 15);
assign rs2_ok       = (outputs.source2 < 8) | (outputs.source2 > 15);

always_ff @(posedge clk or negedge rst_n) begin : BStalls
    if(!rst_n) begin
        bypass_cntr <= 0;
    end else begin
        if(bypass) begin
            bypass_cntr <= bypass_cntr+1;
        end
    end
end
