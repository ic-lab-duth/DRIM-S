/*
* @info Issue Stage
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @note Functional Units:
* 00 : Load/Store Unit
* 01 : Floating Point Unit
* 10 : Integer Unit
* 11 : Branches
*
* @note Internal Structures: Scoreboard: [p|fu|ticket|in_rob]
* @note Check structs_issue.sv for the structs used.
*
* @param INSTR_BITS     : # of Instruction Bits (default 32 bits)
* @param SCOREBOARD_SIZE: # of Scoreboard Entries : Same as PR
* @param FU_NUMBER      : # of Functional Units
* @param ROB_INDEX_BITS : # of ROB Ticket Bits
* @param DATA_WIDTH     : # of Data Bits
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif

module issue #(
    parameter SCOREBOARD_SIZE = 64,
    parameter FU_NUMBER       = 4 ,
    parameter ROB_INDEX_BITS  = 3 ,
    parameter DATA_WIDTH      = 32,
    parameter C_NUM           = 4 ,
    parameter DUAL_ISSUE      = 1 ,
    parameter VECTOR_ENABLED  = 0
) (
    input  logic                                                      clk             ,
    input  logic                                                      rst_n           ,
    //Input of Decoded Instructions
    input  logic                                                      valid_1         ,
    input  renamed_instr                                              Instruction1    ,
    input  logic                                                      valid_2         ,
    input  renamed_instr                                              Instruction2    ,
    input  logic                                                      vector_q_ready  ,
    //Issue Indicators (pop enablers)
    output logic                                                      issue_1         ,
    output logic                                                      issue_2         ,
    output logic                                                      issue_vector    ,
    //Retired Instruction
    input  writeback_toARF                                            writeback_1     ,
    input  writeback_toARF                                            writeback_2     ,
    //Flush Command
    input  predictor_update                                           pr_update       ,
    input  logic                                                      flush_valid     ,
    input  logic        [(2**ROB_INDEX_BITS)-1:0]                     flush_vector_inv,
    //Busy Signals from Functional Units
    input  logic        [                    3:0]                     busy_fu         ,
    //Outputs from Functional Units
    input  ex_update    [          FU_NUMBER-1:0]                     fu_update       ,
    input  ex_update    [          FU_NUMBER-1:0]                     fu_update_frw   ,
    //Forward Port from ROB
    output logic        [                    3:0][ROB_INDEX_BITS-1:0] read_addr_rob   ,
    input  logic        [                    3:0][    DATA_WIDTH-1:0] data_out_rob    ,
    //Signals towards the EX stage
    output to_execution [                    1:0]                     t_execution     ,
    output to_vector                                                  t_vector
);

	// #Internal Signals#
	scoreboard_entry [SCOREBOARD_SIZE-1 : 0] scoreboard  ;
	logic            [SCOREBOARD_SIZE-1 : 0] flush_vector;
	localparam int SC_SIZE = $bits(scoreboard);
	//Intermediate signals
    logic wr_en_1, wr_en_1_dummy, wr_en_2_dummy, wr_en_2;
    logic rd_ok_Ia, rd_ok_Ib;     //Rdst checking signals
    logic src1_ok_Ia, src1_ok_Ib; //Rsrc1 checking signals
    logic src2_ok_Ia, src2_ok_Ib; //Rsrc2 checking signals
    logic fu_ok_Ia, fu_ok_Ib;     //Functional Unit checking signals
    logic Ib_dependent_Ia, common_fu;
    logic valid_dest1, valid_dest2;
    //Dummy Signals for indexing
    logic         pending_Ia_src1, pending_Ia_src2, pending_Ib_src1, pending_Ib_src2, pendinga_rd, pendingb_rd;
    logic         in_rob_Ia_src1, in_rob_Ia_src2, in_rob_Ib_src1, in_rob_Ib_src2;
    logic [1 : 0] fu_Ia_src1, fu_Ia_src2, fu_Ib_src1, fu_Ib_src2;
    //for register file
    logic [3:0][5 : 0]            read_Addr_RF;
    logic [3:0][DATA_WIDTH-1 : 0] data_Out_RF;
    logic                  write_En, write_En_2;
    logic [         5 : 0] write_Addr_RF, write_Addr_RF_2;
    logic [DATA_WIDTH-1:0] write_Data, write_Data_2;
    //For Vector pipeline
    logic [C_NUM-1:0] branch_if   ;
    logic             vector_wr_en;

	// Initialize the Register File & Signals
	assign read_Addr_RF[0] = Instruction1.source1;
	assign read_Addr_RF[1] = Instruction1.source2;
	assign read_Addr_RF[2] = Instruction2.source1;
	assign read_Addr_RF[3] = Instruction2.source2;
	assign write_En        = writeback_1.valid_commit & writeback_1.valid_write & ~writeback_1.flushed;
	assign write_Addr_RF   = writeback_1.pdst;
	assign write_Data      = writeback_1.data;
	assign write_En_2      = writeback_2.valid_commit & writeback_2.valid_write & ~writeback_2.flushed;
	assign write_Addr_RF_2 = writeback_2.pdst;
	assign write_Data_2    = writeback_2.data;

	register_file #(
		.DATA_WIDTH(DATA_WIDTH     ),
		.ADDR_WIDTH(6              ),
		.SIZE      (SCOREBOARD_SIZE),
		.READ_PORTS(4              )
	) regfile (
		.clk         (clk            ),
		.rst_n       (rst_n          ),

		.write_En    (write_En       ),
		.write_Addr  (write_Addr_RF  ),
		.write_Data  (write_Data     ),

		.write_En_2  (write_En_2     ),
		.write_Addr_2(write_Addr_RF_2),
		.write_Data_2(write_Data_2   ),


		.read_Addr   (read_Addr_RF   ),
		.data_Out    (data_Out_RF    )
	);

    assign issue_1      = wr_en_1;
    assign issue_2      = wr_en_2;
    assign issue_vector = vector_wr_en;

    assign valid_dest1  = |Instruction1.destination;
    assign valid_dest2  = |Instruction2.destination;

	// forward data from ROB -> Create Addresses
	assign read_addr_rob[0] = scoreboard[Instruction1.source1].ticket;
	assign read_addr_rob[1] = scoreboard[Instruction1.source2].ticket;
	assign read_addr_rob[2] = scoreboard[Instruction2.source1].ticket;
	assign read_addr_rob[3] = scoreboard[Instruction2.source2].ticket;

	// Data just passing through to the next stage for the 2 Instructions
	assign t_execution[0].destination     = Instruction1.destination;
	assign t_execution[0].ticket          = Instruction1.ticket;
	assign t_execution[0].functional_unit = Instruction1.functional_unit;
	assign t_execution[0].microoperation  = Instruction1.microoperation;
	assign t_execution[0].rm              = Instruction1.rm;
	assign t_execution[0].pc              = Instruction1.pc;
	assign t_execution[0].immediate       = Instruction1.immediate;
	assign t_execution[0].rat_id 		  = Instruction1.rat_id;

	assign t_execution[1].destination     = Instruction2.destination;
	assign t_execution[1].ticket          = Instruction2.ticket;
	assign t_execution[1].functional_unit = Instruction2.functional_unit;
	assign t_execution[1].microoperation  = Instruction2.microoperation;
	assign t_execution[1].rm              = Instruction2.rm;
	assign t_execution[1].pc              = Instruction2.pc;
	assign t_execution[1].immediate       = Instruction2.immediate;
	assign t_execution[1].rat_id 		  = Instruction2.rat_id;

	//Vector Assignments (Only the first instruction can be issued as vector instruction)
    generate
        if (VECTOR_ENABLED) begin
            assign vector_wr_en             = Instruction1.is_valid & valid_1 & Instruction1.is_vector & src1_ok_Ia & branch_if[0] & vector_q_ready;
            assign t_vector.valid           = vector_wr_en;
            assign t_vector.pc              = Instruction1.pc;
            assign t_vector.destination     = Instruction1.destination;
            assign t_vector.source1         = Instruction1.source1;
            assign t_vector.source2         = Instruction1.source2;
            assign t_vector.data            = t_execution[0].data1;
            assign t_vector.immediate       = Instruction1.immediate;
            assign t_vector.functional_unit = Instruction1.functional_unit;
            assign t_vector.microoperation  = Instruction1.microoperation;
        end else begin
            assign vector_wr_en            = 1'b0;
            assign t_vector.valid          = 1'b0;
        end
    endgenerate

	// Create Flush Signals
	always_comb begin : FlushMechanism
		flush_vector = 'b0;
		for (int i = 1; i < SCOREBOARD_SIZE; i++) begin
			for (int k = 0; k < 2**ROB_INDEX_BITS; k++) begin
				if(scoreboard[i].ticket == k && !flush_vector_inv[k]) begin
					flush_vector[i] = 1;
				end
			end
		end
	end
	// Create Final Issue-Enable signals
	assign t_execution[0].valid = wr_en_1;
	assign t_execution[1].valid = wr_en_2;
	// In-order Issue: Oldest Instr must issue before issuing #2
	assign wr_en_1 = wr_en_1_dummy & Instruction1.is_valid & valid_1 & ~Instruction1.is_vector;
    generate
        if(DUAL_ISSUE) begin
            assign wr_en_2 = wr_en_2_dummy &  (wr_en_1 | vector_wr_en) & Instruction2.is_valid & valid_2 &
                                ~Instruction2.is_vector & ~Ib_dependent_Ia & ~common_fu;
        end else begin
            assign wr_en_2 = 0;
        end
    endgenerate

	// Conflict Checking Signals
	assign wr_en_1_dummy = rd_ok_Ia & src1_ok_Ia & src2_ok_Ia & fu_ok_Ia;
	assign wr_en_2_dummy = rd_ok_Ib & src1_ok_Ib & src2_ok_Ib & fu_ok_Ib;

    //Check if congestion for the same FU
    assign common_fu = (Instruction1.functional_unit == Instruction2.functional_unit);
    //Check whether Ib is dependent on Ia
        //Depedency occurs when one of the sources is the output of Ia
    assign Ib_dependent_Ia = ((Instruction2.source1==Instruction1.destination) | (Instruction2.source2==Instruction1.destination))
                                                                & valid_dest1;
	// #Issue Logic_1#

	// create dummy signals for Instruction 1
	assign pending_Ia_src1 = scoreboard[Instruction1.source1].pending;
	assign in_rob_Ia_src1  = scoreboard[Instruction1.source1].in_rob;
	assign fu_Ia_src1      = scoreboard[Instruction1.source1].fu;

	assign pending_Ia_src2 = scoreboard[Instruction1.source2].pending;
	assign in_rob_Ia_src2  = scoreboard[Instruction1.source2].in_rob;
	assign fu_Ia_src2      = scoreboard[Instruction1.source2].fu;

	// Check FU_1
	assign fu_ok_Ia = ~busy_fu[Instruction1.functional_unit];

	// Check rd_ok_Ia
	assign rd_ok_Ia = ~scoreboard[Instruction1.destination].pending;

	//Issue Instruction 1
	always_comb begin : Issue1
		//Check rs1_1
		if(Instruction1.source1_pc) begin
			src1_ok_Ia           = 1;
			t_execution[0].data1 = Instruction1.pc;
		end else begin
			//Check if Pending
			if(pending_Ia_src1) begin
				if(in_rob_Ia_src1 == 1) begin
					//grab Data from ROB
					src1_ok_Ia           = 1;
					t_execution[0].data1 = data_out_rob[0];
				end else if(fu_update_frw[fu_Ia_src1].valid && fu_update_frw[fu_Ia_src1].destination==Instruction1.source1) begin
					//grab Data from end of FU
					src1_ok_Ia           = 1;
					t_execution[0].data1 = fu_update_frw[fu_Ia_src1].data;
				end else if(fu_update[fu_Ia_src1].valid && fu_update[fu_Ia_src1].destination==Instruction1.source1) begin
					//grab Data from end of FU
					src1_ok_Ia           = 1;
					t_execution[0].data1 = fu_update[fu_Ia_src1].data;
				end else begin
					//Stall
					src1_ok_Ia           = 0;
					t_execution[0].data1 = data_Out_RF[0];
				end
			end else begin
				//grab Data from Register File
				src1_ok_Ia           = 1;
				t_execution[0].data1 = data_Out_RF[0];
			end
		end
		//Check rs2_1
		if(Instruction1.source2_immediate) begin
			src2_ok_Ia           = 1;
			t_execution[0].data2 = Instruction1.immediate;
		end else begin
			if(pending_Ia_src2) begin
				if(in_rob_Ia_src2 == 1) begin
					//stall
					src2_ok_Ia           = 1;
					t_execution[0].data2 = data_out_rob[1];
				end else if(fu_update_frw[fu_Ia_src2].valid && fu_update_frw[fu_Ia_src2].destination==Instruction1.source2) begin
					//grab Data from end of FU
					src2_ok_Ia           = 1;
					t_execution[0].data2 = fu_update_frw[fu_Ia_src2].data;
				end else if(fu_update[fu_Ia_src2].valid && fu_update[fu_Ia_src2].destination==Instruction1.source2) begin
					//grab Data from end of FU
					src2_ok_Ia           = 1;
					t_execution[0].data2 = fu_update[fu_Ia_src2].data;
				end else begin
					//Stall
					src2_ok_Ia           = 0;
					t_execution[0].data2 = data_Out_RF[1];
				end
			end else begin
				//grab Data from Register File
				src2_ok_Ia           = 1;
				t_execution[0].data2 = data_Out_RF[1];
			end
		end
	end

	//#Issue Logic_2#

	//create dummy signals
	assign pending_Ib_src1 = scoreboard[Instruction2.source1].pending;
	assign in_rob_Ib_src1  = scoreboard[Instruction2.source1].in_rob;
	assign fu_Ib_src1      = scoreboard[Instruction2.source1].fu;

	assign pending_Ib_src2 = scoreboard[Instruction2.source2].pending;
	assign in_rob_Ib_src2  = scoreboard[Instruction2.source2].in_rob;
	assign fu_Ib_src2      = scoreboard[Instruction2.source2].fu;

	// Check FU_2
	assign fu_ok_Ib = ~busy_fu[Instruction2.functional_unit];

	// Check rd_2
	assign rd_ok_Ib = ~scoreboard[Instruction2.destination].pending;

	//Issue Instruction 2
	always_comb begin : Issue2
		// Check rs1_2
		if(Instruction2.source1_pc) begin
			src1_ok_Ib           = 1;
			t_execution[1].data1 = Instruction2.pc;
		end else begin
			if(pending_Ib_src1) begin
				if(in_rob_Ib_src1==1) begin
					//grab Data from ROB
					src1_ok_Ib           = 1;
					t_execution[1].data1 = data_out_rob[2];
				end else if(fu_update_frw[fu_Ib_src1].valid && fu_update_frw[fu_Ib_src1].destination==Instruction2.source1) begin
					//grab Data from end of FU
					src1_ok_Ib           = 1;
					t_execution[1].data1 = fu_update_frw[fu_Ib_src1].data;
				end else if(fu_update[fu_Ib_src1].valid && fu_update[fu_Ib_src1].destination==Instruction2.source1) begin
					//grab Data from end of FU
					src1_ok_Ib           = 1;
					t_execution[1].data1 = fu_update[fu_Ib_src1].data;
				end else begin
					//Stall
					src1_ok_Ib           = 0;
					t_execution[1].data1 = data_Out_RF[2];
				end
			end else begin
				//grab Data from Register File
				src1_ok_Ib           = 1;
				t_execution[1].data1 = data_Out_RF[2];
			end
		end
		// Check rs2_2
		if(Instruction2.source2_immediate) begin
			src2_ok_Ib           = 1;
			t_execution[1].data2 = Instruction2.immediate;
		end else begin
			if(pending_Ib_src2) begin
				if(in_rob_Ib_src2 == 1) begin
					//grab Data from ROB
					src2_ok_Ib           = 1;
					t_execution[1].data2 = data_out_rob[3];
				end else if(fu_update_frw[fu_Ib_src2].valid && fu_update_frw[fu_Ib_src2].destination==Instruction2.source2) begin
					//grab Data from end of FU
					src2_ok_Ib           = 1;
					t_execution[1].data2 = fu_update_frw[fu_Ib_src2].data;
				end else if(fu_update[fu_Ib_src2].valid && fu_update[fu_Ib_src2].destination==Instruction2.source2) begin
					//grab Data from end of FU
					src2_ok_Ib           = 1;
					t_execution[1].data2 = fu_update[fu_Ib_src2].data;
				end else begin
					//Stall
					src2_ok_Ib           = 0;
					t_execution[1].data2 = data_Out_RF[3];
				end
			end else begin
				//grab Data from Register File
				src2_ok_Ib           = 1;
				t_execution[1].data2 = data_Out_RF[3];
			end
		end
	end

	//#Update Scoreboard#
	//-----------------------------------------------------------------------------
    logic [SCOREBOARD_SIZE-1:0] instr_1_dest_oh, instr_2_dest_oh, writeback_dst_oh, writeback_dst_oh_2;
    logic [      FU_NUMBER-1:0] masked_write_en;
    logic                       writeback_en, writeback_en_2;

    assign instr_1_dest_oh = (1 << Instruction1.destination);
    assign instr_2_dest_oh = (1 << Instruction2.destination);

    //Mask the Write Bits for the FU Updates with the New Issues
    always_comb begin : MaskBits
        for (int i = 0; i < FU_NUMBER; i++) begin
            if(fu_update[i].destination == Instruction2.destination && wr_en_2) begin
                masked_write_en[i] = 0;
            end else if(fu_update[i].destination == Instruction1.destination && wr_en_1) begin
                masked_write_en[i] = 0;
            end else begin
                masked_write_en[i] = fu_update[i].valid & (fu_update[i].ticket==scoreboard[fu_update[i].destination].ticket);
            end
        end
    end
	// Update the Scoreboard.inrob Field
	always_ff @(posedge clk) begin : SCinRob
		for (int i = 0; i < SCOREBOARD_SIZE; i++) begin
			if(wr_en_2 && instr_2_dest_oh[i]) begin
				// Issued 2
				scoreboard[i].in_rob  <= 0;
			end else if(wr_en_1 && instr_1_dest_oh[i]) begin
				// Issued 1
				scoreboard[i].in_rob  <= 0;
			end else begin
				// Register new FU updates
				for (int j = 0; j < FU_NUMBER; j++) begin
					if(masked_write_en[j] && fu_update[j].destination==i) begin
	 					scoreboard[i].in_rob <= 1;
					end
				end
			end
		end
	end
	// Update the Scoreboard.ticket & Scoreboard.fu Fields
	always_ff @(posedge clk) begin : SC_Ticket_Fu
		for (int i = 0; i < SCOREBOARD_SIZE; i++) begin
			if(wr_en_2 && instr_2_dest_oh[i]) begin
				// Issued 2
				scoreboard[i].fu     <= Instruction2.functional_unit;
				scoreboard[i].ticket <= Instruction2.ticket;
			end else if (wr_en_1 && instr_1_dest_oh[i]) begin
				// Issued 1
				scoreboard[i].fu     <= Instruction1.functional_unit;
				scoreboard[i].ticket <= Instruction1.ticket;
			end
		end
	end

	assign writeback_en     = writeback_1.valid_commit & writeback_1.valid_write & (writeback_1.ticket == scoreboard[writeback_1.pdst].ticket);
	assign writeback_dst_oh = (1 << writeback_1.pdst);

	assign writeback_en_2     = writeback_2.valid_commit & writeback_2.valid_write & (writeback_2.ticket == scoreboard[writeback_2.pdst].ticket);
	assign writeback_dst_oh_2 = (1 << writeback_2.pdst);
	// Update the Scoreboard.pending Field
	always_ff @(posedge clk or negedge rst_n) begin : SCpending
		if(!rst_n) begin
			for (int i = 0; i < SCOREBOARD_SIZE; i++) begin
				scoreboard[i].pending <= 0;
			end
		end else begin
			//x0 is unwrittable -> never pending -> no commit will ever arrive for x0
			scoreboard[0].pending <= 'b0;
			for (int i = 1; i < SCOREBOARD_SIZE; i++) begin
				if (flush_valid && flush_vector[i]) begin
					//Flush the Entry
					scoreboard[i].pending <= 0;
				end else if(wr_en_2 && instr_2_dest_oh[i]) begin
					// Issued 2
					scoreboard[i].pending <= valid_dest2;
				end else if(wr_en_1 && instr_1_dest_oh[i]) begin
					// Issued 1
					scoreboard[i].pending <= valid_dest1;
				end else if(writeback_en && writeback_dst_oh[i]) begin
					// New writeback_1
					scoreboard[i].pending <= 0;
				end else if(writeback_en_2 && writeback_dst_oh_2[i]) begin
					// New writeback_1
					scoreboard[i].pending <= 0;
				end
			end
		end
	end

    // Track Branches in Flight (used when Vector Support enabled)
    generate if(VECTOR_ENABLED) begin
        logic single_branch, dual_branch;

            assign dual_branch   = Instruction1.is_branch & Instruction2.is_branch & issue_2;
            assign single_branch = (Instruction1.is_branch & issue_1) | (Instruction2.is_branch & issue_2);

            always_ff @(posedge clk or negedge rst_n) begin : BranchInFlight
                if(!rst_n) begin
                    branch_if <= 0;
                end else begin
                    if(flush_valid) begin
                        branch_if <= 0;
                    end else if(dual_branch) begin      // Dual Branch Issued
                        if(!pr_update.valid_jump) begin
                            branch_if <= branch_if << 2;
                        end else begin
                            branch_if <= branch_if << 1;
                        end
                    end else if(single_branch) begin    // Single Branch Issued
                        if(!pr_update.valid_jump) begin
                            branch_if <= branch_if << 1;
                        end
                    end else if (pr_update.valid_jump && |branch_if) begin // No Branch Issued
                        branch_if <= branch_if >> 1;
                    end
                end
            end
	end endgenerate

`ifdef INCLUDE_SVAS
    `include "issue_sva.sv"
`endif

endmodule