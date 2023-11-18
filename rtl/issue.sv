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
    parameter SCOREBOARD_SIZE 	= 64,
    parameter FU_NUMBER       	= 4 ,
    parameter ROB_INDEX_BITS  	= 3 ,
    parameter DATA_WIDTH      	= 32,
    parameter C_NUM           	= 4 ,
    parameter DUAL_ISSUE      	= 1 ,
    parameter VECTOR_ENABLED  	= 0 ,
	parameter STATIONS 			= 3
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
    output to_execution [         STATIONS - 2:0]                     t_execution     ,
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
    logic [C_NUM:0] branch_if   ;
    logic [C_NUM-1:0] branch_if_a   ;
    logic [C_NUM-1:0] branch_if_b   ;
    logic             vector_wr_en;
	//* new signals
	logic Ib_dependent_Ia_rs1;
	logic Ib_dependent_Ia_rs2;
	to_execution [1:0] sfc_data_in;
	to_execution [2:0][1:0] sfc_data_out;

	assign branch_if_a = branch_if[C_NUM:1];
	assign branch_if_b = branch_if[C_NUM:1] << Instruction1.is_branch;

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

    assign issue_vector = 0;

    assign valid_dest1  = |Instruction1.destination;
    assign valid_dest2  = |Instruction2.destination;

	// forward data from ROB -> Create Addresses
	assign read_addr_rob[0] = scoreboard[Instruction1.source1].ticket;
	assign read_addr_rob[1] = scoreboard[Instruction1.source2].ticket;
	assign read_addr_rob[2] = scoreboard[Instruction2.source1].ticket;
	assign read_addr_rob[3] = scoreboard[Instruction2.source2].ticket;

	// Data just passing through to the next stage for the 2 Instructions
	assign sfc_data_in[0].destination     = Instruction1.destination;
	assign sfc_data_in[0].ticket          = Instruction1.ticket;
	assign sfc_data_in[0].functional_unit = Instruction1.functional_unit;
	assign sfc_data_in[0].microoperation  = Instruction1.microoperation;
	assign sfc_data_in[0].rm              = Instruction1.rm;
	assign sfc_data_in[0].pc              = Instruction1.pc;
	assign sfc_data_in[0].immediate       = Instruction1.immediate;
	assign sfc_data_in[0].rat_id 		  = Instruction1.rat_id;

	assign sfc_data_in[1].destination     = Instruction2.destination;
	assign sfc_data_in[1].ticket          = Instruction2.ticket;
	assign sfc_data_in[1].functional_unit = Instruction2.functional_unit;
	assign sfc_data_in[1].microoperation  = Instruction2.microoperation;
	assign sfc_data_in[1].rm              = Instruction2.rm;
	assign sfc_data_in[1].pc              = Instruction2.pc;
	assign sfc_data_in[1].immediate       = Instruction2.immediate;
	assign sfc_data_in[1].rat_id 		  = Instruction2.rat_id;
	// assign t_execution[0].destination     = Instruction1.destination;
	// assign t_execution[0].ticket          = Instruction1.ticket;
	// assign t_execution[0].functional_unit = Instruction1.functional_unit;
	// assign t_execution[0].microoperation  = Instruction1.microoperation;
	// assign t_execution[0].rm              = Instruction1.rm;
	// assign t_execution[0].pc              = Instruction1.pc;
	// assign t_execution[0].immediate       = Instruction1.immediate;
	// assign t_execution[0].rat_id 		  = Instruction1.rat_id;

	// assign t_execution[1].destination     = Instruction2.destination;
	// assign t_execution[1].ticket          = Instruction2.ticket;
	// assign t_execution[1].functional_unit = Instruction2.functional_unit;
	// assign t_execution[1].microoperation  = Instruction2.microoperation;
	// assign t_execution[1].rm              = Instruction2.rm;
	// assign t_execution[1].pc              = Instruction2.pc;
	// assign t_execution[1].immediate       = Instruction2.immediate;
	// assign t_execution[1].rat_id 		  = Instruction2.rat_id;

	//Vector Assignments (Only the first instruction can be issued as vector instruction)
    // generate
    //     if (VECTOR_ENABLED) begin
    //         assign vector_wr_en             = Instruction1.is_valid & valid_1 & Instruction1.is_vector & src1_ok_Ia & src2_ok_Ia & branch_if[0] & vector_q_ready;
    //         assign t_vector.valid           = vector_wr_en;
    //         assign t_vector.data1           = t_execution[0].data1;
    //         assign t_vector.data2           = t_execution[0].data2;
    //         assign t_vector.instruction 	= Instruction1.immediate;
    //     end else begin
    //         assign vector_wr_en            = 1'b0;
    //         assign t_vector.valid          = 1'b0;
    //     end
    // endgenerate

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
	assign sfc_data_in[0].valid = Instruction1.is_valid;
	assign sfc_data_in[1].valid = Instruction2.is_valid;
	// assign t_execution[0].valid = wr_en_1;
	// assign t_execution[1].valid = wr_en_2;
	// In-order Issue: Oldest Instr must issue before issuing #2
	// assign wr_en_1 = Instruction1.is_valid & valid_1;
    // generate
    //     if(DUAL_ISSUE) begin
    //         assign wr_en_2 = Instruction2.is_valid & valid_2;
    //     end else begin
    //         assign wr_en_2 = 0;
    //     end
    // endgenerate

	// Conflict Checking Signals
	// assign wr_en_1_dummy = rd_ok_Ia & src1_ok_Ia & src2_ok_Ia & fu_ok_Ia;
	// assign wr_en_2_dummy = rd_ok_Ib & src1_ok_Ib & src2_ok_Ib & fu_ok_Ib;

    // //Check if congestion for the same FU
    // assign common_fu = (Instruction1.functional_unit == Instruction2.functional_unit);
    // //Check whether Ib is dependent on Ia
    //     //Depedency occurs when one of the sources is the output of Ia
    // assign Ib_dependent_Ia = ((Instruction2.source1==Instruction1.destination) | (Instruction2.source2==Instruction1.destination))
    //                                                             & valid_dest1;


    assign Ib_dependent_Ia_rs1 = (Instruction2.source1==Instruction1.destination) & valid_dest1;
    assign Ib_dependent_Ia_rs2 = (Instruction2.source2==Instruction1.destination) & valid_dest1;
	// #Issue Logic_1#

	logic [2:0] tag_Ia_src1,tag_Ia_src2;
	// create dummy signals for Instruction 1
	assign pending_Ia_src1 = scoreboard[Instruction1.source1].pending;
	assign in_rob_Ia_src1  = scoreboard[Instruction1.source1].in_rob;
	assign tag_Ia_src1  = scoreboard[Instruction1.source1].ticket;
	assign fu_Ia_src1      = scoreboard[Instruction1.source1].fu;

	assign pending_Ia_src2 = scoreboard[Instruction1.source2].pending;
	assign in_rob_Ia_src2  = scoreboard[Instruction1.source2].in_rob;
	assign tag_Ia_src2  = scoreboard[Instruction1.source2].ticket;
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
			sfc_data_in[0].data1 = Instruction1.pc;
		end else begin
			//Check if Pending
			if(pending_Ia_src1) begin
				if(in_rob_Ia_src1 == 1) begin
					//grab Data from ROB
					src1_ok_Ia           = 1;
					sfc_data_in[0].data1 = data_out_rob[0];
				end else if(fu_update_frw[fu_Ia_src1].valid && fu_update_frw[fu_Ia_src1].destination==Instruction1.source1) begin
					//grab Data from end of FU
					src1_ok_Ia           = 1;
					sfc_data_in[0].data1 = fu_update_frw[fu_Ia_src1].data;
				end else if(fu_update[fu_Ia_src1].valid && fu_update[fu_Ia_src1].destination==Instruction1.source1) begin
					//grab Data from end of FU
					src1_ok_Ia           = 1;
					sfc_data_in[0].data1 = fu_update[fu_Ia_src1].data;
				end else begin
					//Stall
					src1_ok_Ia           = 0;
					sfc_data_in[0].data1 = data_Out_RF[0];
				end
			end else begin
				//grab Data from Register File
				src1_ok_Ia           = 1;
				sfc_data_in[0].data1 = data_Out_RF[0];
			end
		end
		//Check rs2_1
		if(Instruction1.source2_immediate) begin
			src2_ok_Ia           = 1;
			sfc_data_in[0].data2 = Instruction1.immediate;
		end else begin
			if(pending_Ia_src2) begin
				if(in_rob_Ia_src2 == 1) begin
					//stall
					src2_ok_Ia           = 1;
					sfc_data_in[0].data2 = data_out_rob[1];
				end else if(fu_update_frw[fu_Ia_src2].valid && fu_update_frw[fu_Ia_src2].destination==Instruction1.source2) begin
					//grab Data from end of FU
					src2_ok_Ia           = 1;
					sfc_data_in[0].data2 = fu_update_frw[fu_Ia_src2].data;
				end else if(fu_update[fu_Ia_src2].valid && fu_update[fu_Ia_src2].destination==Instruction1.source2) begin
					//grab Data from end of FU
					src2_ok_Ia           = 1;
					sfc_data_in[0].data2 = fu_update[fu_Ia_src2].data;
				end else begin
					//Stall
					src2_ok_Ia           = 0;
					sfc_data_in[0].data2 = data_Out_RF[1];
				end
			end else begin
				//grab Data from Register File
				src2_ok_Ia           = 1;
				sfc_data_in[0].data2 = data_Out_RF[1];
			end
		end
	end

	//#Issue Logic_2#
	logic [2:0] tag_Ib_src1,tag_Ib_src2;
	//create dummy signals
	assign pending_Ib_src1 	= scoreboard[Instruction2.source1].pending;
	assign in_rob_Ib_src1  	= scoreboard[Instruction2.source1].in_rob;
	assign tag_Ib_src1  	= Ib_dependent_Ia_rs1 ? Instruction1.ticket : scoreboard[Instruction2.source1].ticket;
	assign fu_Ib_src1      	= scoreboard[Instruction2.source1].fu;

	assign pending_Ib_src2 	= scoreboard[Instruction2.source2].pending;
	assign in_rob_Ib_src2  	= scoreboard[Instruction2.source2].in_rob;
	assign tag_Ib_src2  	= Ib_dependent_Ia_rs2 ? Instruction1.ticket : scoreboard[Instruction2.source2].ticket;
	assign fu_Ib_src2      	= scoreboard[Instruction2.source2].fu;

	// Check FU_2
	assign fu_ok_Ib = ~busy_fu[Instruction2.functional_unit];

	// Check rd_2
	assign rd_ok_Ib = ~scoreboard[Instruction2.destination].pending;

	//Issue Instruction 2
	always_comb begin : Issue2
		// Check rs1_2
		if(Instruction2.source1_pc) begin
			src1_ok_Ib           = 1;
			sfc_data_in[1].data1 = Instruction2.pc;
		end else begin
			if(pending_Ib_src1) begin
				if(in_rob_Ib_src1==1) begin
					//grab Data from ROB
					src1_ok_Ib           = 1;
					sfc_data_in[1].data1 = data_out_rob[2];
				end else if(fu_update_frw[fu_Ib_src1].valid && fu_update_frw[fu_Ib_src1].destination==Instruction2.source1) begin
					//grab Data from end of FU
					src1_ok_Ib           = 1;
					sfc_data_in[1].data1 = fu_update_frw[fu_Ib_src1].data;
				end else if(fu_update[fu_Ib_src1].valid && fu_update[fu_Ib_src1].destination==Instruction2.source1) begin
					//grab Data from end of FU
					src1_ok_Ib           = 1;
					sfc_data_in[1].data1 = fu_update[fu_Ib_src1].data;
				end else begin
					//Stall
					src1_ok_Ib           = 0;
					sfc_data_in[1].data1 = data_Out_RF[2];
				end
			end else begin
				//grab Data from Register File
				src1_ok_Ib           = 1;
				sfc_data_in[1].data1 = data_Out_RF[2];
			end
		end
		// Check rs2_2
		if(Instruction2.source2_immediate) begin
			src2_ok_Ib           = 1;
			sfc_data_in[1].data2 = Instruction2.immediate;
		end else begin
			if(pending_Ib_src2) begin
				if(in_rob_Ib_src2 == 1) begin
					//grab Data from ROB
					src2_ok_Ib           = 1;
					sfc_data_in[1].data2 = data_out_rob[3];
				end else if(fu_update_frw[fu_Ib_src2].valid && fu_update_frw[fu_Ib_src2].destination==Instruction2.source2) begin
					//grab Data from end of FU
					src2_ok_Ib           = 1;
					sfc_data_in[1].data2 = fu_update_frw[fu_Ib_src2].data;
				end else if(fu_update[fu_Ib_src2].valid && fu_update[fu_Ib_src2].destination==Instruction2.source2) begin
					//grab Data from end of FU
					src2_ok_Ib           = 1;
					sfc_data_in[1].data2 = fu_update[fu_Ib_src2].data;
				end else begin
					//Stall
					src2_ok_Ib           = 0;
					sfc_data_in[1].data2 = data_Out_RF[3];
				end
			end else begin
				//grab Data from Register File
				src2_ok_Ib           = 1;
				sfc_data_in[1].data2 = data_Out_RF[3];
			end
		end
	end

	logic [2:0][1:0] valid_signals;
	assign valid_signals[0] = {Instruction2.functional_unit == 0 && !Instruction2.is_vector, Instruction1.functional_unit == 0 && !Instruction1.is_vector}; // to memory station
	assign valid_signals[1] = {Instruction2.functional_unit != 0 && !Instruction2.is_vector, Instruction1.functional_unit != 0 && !Instruction1.is_vector}; // to integer station
	assign valid_signals[2] = {Instruction2.is_vector & branch_if[0] & !Instruction1.is_branch, Instruction1.is_vector & branch_if[0]}; // to vector station

	logic [1:0][$bits(sfc_data_in[0]) + C_NUM + 8:0] sfc_all_in;
	logic [2:0][1:0][$bits(sfc_data_in[0]) + C_NUM + 8:0] sfc_all_out;
	assign sfc_all_in[0] = {sfc_data_in[0], tag_Ia_src1, tag_Ia_src2, ~src1_ok_Ia, ~src2_ok_Ia, Instruction1.is_vector, branch_if_a};
	assign sfc_all_in[1] = {sfc_data_in[1], tag_Ib_src1, tag_Ib_src2, ~src1_ok_Ib | Ib_dependent_Ia_rs1, ~src2_ok_Ib | Ib_dependent_Ia_rs2, Instruction2.is_vector, branch_if_b};

	logic [2:0][1:0] sfc_push;
	logic [2:0][1:0] sfc_ready_in;
	smart_flow_control 	#(
							.INPUT_PORTS	(2),
							.OUTPUT_PORTS	(2),
							.DATA_WIDTH		($bits(sfc_data_in[0]) + C_NUM + 9),
							.FIFOS			(3))
	smart_flow_control 	(
							.clk			(clk),
							.rst			(~rst_n),
							.flush			(flush_valid),
							.pop			({issue_2, issue_1}),
							.valid_in		({valid_2 & Instruction2.is_valid, valid_1 & Instruction1.is_valid}),
							.valid_signals	(valid_signals),
							.data_in		(sfc_all_in),
							.push			(sfc_push),
							.ready_in		(sfc_ready_in),
							.data_out		(sfc_all_out),
							.smart_push_ready({wr_en_2, wr_en_1})
						);
	logic [2:0][1:0][C_NUM - 1 : 0] branches_in_flight;
	logic [2:0][1:0][2:0] tag1, tag2;
	logic [2:0][1:0] pending1, pending2, inst_is_vector;
	always_comb for (int i = 0; i < 3; ++i) for (int j = 0; j < 2; ++j)
		{sfc_data_out[i][j], tag1[i][j], tag2[i][j], pending1[i][j], pending2[i][j], inst_is_vector[i][j], branches_in_flight[i][j]} = sfc_all_out[i][j];

	reservation_entry_t [2:0][1:0] res_data_in;
	reservation_entry_t [2:0] res_data_out;
	logic [2:0][1:0][85:0] res_extra_in;
	logic [2:0][85:0] res_extra_out;
	logic [2:0] res_valid_out;
	always_comb for (int i = 0; i < 3; ++i) for (int j = 0; j < 2; ++j) begin
		res_data_in[i][j].opA 		= sfc_data_out[i][j].data1;
		res_data_in[i][j].opB 		= sfc_data_out[i][j].data2;
		res_data_in[i][j].tagA 		= tag1[i][j];
		res_data_in[i][j].tagB 		= tag2[i][j];
		res_data_in[i][j].pendingA 	= pending1[i][j];
		res_data_in[i][j].pendingB 	= pending2[i][j];
		res_data_in[i][j].branch_if	= branches_in_flight[i][j];

		res_extra_in[i][j] =
			{sfc_data_out[i][j].valid, sfc_data_out[i][j].pc, sfc_data_out[i][j].destination, sfc_data_out[i][j].immediate,
			sfc_data_out[i][j].functional_unit, sfc_data_out[i][j].microoperation, sfc_data_out[i][j].rm, sfc_data_out[i][j].rat_id, sfc_data_out[i][j].ticket};
	end


	reservation_station #(
							.INPUT_PORTS		(2),
							.OUTPUT_PORTS		(1),
							.SEARCH_PORTS		(FU_NUMBER),
							.ROB_DEPTH			(2**ROB_INDEX_BITS),
							.OPERAND_WIDTH		(DATA_WIDTH),
							.DEPTH				(4),
							.EXTRA_DATA_WIDTH	(86))
	memory_station	(
						.clk			(clk),
						.rst			(~rst_n),
						.branch_resolved(pr_update.valid_jump),
						.flush			(flush_valid),
						.ready_out		(sfc_ready_in[0]),
						.valid_in		(sfc_push[0]),
						.data_in		(res_data_in[0]),
						.extra_in		(res_extra_in[0]),
						.valid_out		(res_valid_out[0]),
						.ready_in		(t_execution[0].valid),
						.data_out		(res_data_out[0]),
						.extra_out		(res_extra_out[0]),
						.search_valid	({fu_update[3].valid, fu_update[2].valid, fu_update[1].valid, fu_update[0].valid}),
						.search_tags	({fu_update[3].ticket, fu_update[2].ticket, fu_update[1].ticket, fu_update[0].ticket}),
						.search_data	({fu_update[3].data, fu_update[2].data, fu_update[1].data, fu_update[0].data})
					);
	reservation_station #(
							.INPUT_PORTS		(2),
							.OUTPUT_PORTS		(1),
							.SEARCH_PORTS		(FU_NUMBER),
							.ROB_DEPTH			(2**ROB_INDEX_BITS),
							.OPERAND_WIDTH		(DATA_WIDTH),
							.DEPTH				(4),
							.EXTRA_DATA_WIDTH	(86))
	integer_station	(
						.clk			(clk),
						.rst			(~rst_n),
						.branch_resolved(pr_update.valid_jump),
						.flush			(flush_valid),
						.ready_out		(sfc_ready_in[1]),
						.valid_in		(sfc_push[1]),
						.data_in		(res_data_in[1]),
						.extra_in		(res_extra_in[1]),
						.valid_out		(res_valid_out[1]),
						.ready_in		(t_execution[1].valid),
						.data_out		(res_data_out[1]),
						.extra_out		(res_extra_out[1]),
						.search_valid	({fu_update[3].valid, fu_update[2].valid, fu_update[1].valid, fu_update[0].valid}),
						.search_tags	({fu_update[3].ticket, fu_update[2].ticket, fu_update[1].ticket, fu_update[0].ticket}),
						.search_data	({fu_update[3].data, fu_update[2].data, fu_update[1].data, fu_update[0].data})
					);
	reservation_station #(
							.INPUT_PORTS		(2),
							.OUTPUT_PORTS		(1),
							.SEARCH_PORTS		(FU_NUMBER),
							.ROB_DEPTH			(2**ROB_INDEX_BITS),
							.OPERAND_WIDTH		(DATA_WIDTH),
							.DEPTH				(4),
							.EXTRA_DATA_WIDTH	(86))
	vector_station	(
						.clk			(clk),
						.rst			(~rst_n),
						.branch_resolved(pr_update.valid_jump),
						.flush			(flush_valid),
						.ready_out		(sfc_ready_in[2]),
						.valid_in		(sfc_push[2]),
						.data_in		(res_data_in[2]),
						.extra_in		(res_extra_in[2]),
						.valid_out		(res_valid_out[2]),
						.ready_in		(t_vector.valid),
						.data_out		(res_data_out[2]),
						.extra_out		(res_extra_out[2]),
						.search_valid	({fu_update[3].valid, fu_update[2].valid, fu_update[1].valid, fu_update[0].valid}),
						.search_tags	({fu_update[3].ticket, fu_update[2].ticket, fu_update[1].ticket, fu_update[0].ticket}),
						.search_data	({fu_update[3].data, fu_update[2].data, fu_update[1].data, fu_update[0].data})
					);

	always_comb for (int i = 0; i < 2; ++i) begin
		{t_execution[i].valid,
		t_execution[i].pc,
		t_execution[i].destination,
		t_execution[i].immediate,
		t_execution[i].functional_unit,
		t_execution[i].microoperation,
		t_execution[i].rm,
		t_execution[i].rat_id,
		t_execution[i].ticket} = res_extra_out[i];

		t_execution[i].valid &= ~(res_data_out[i].pendingA | res_data_out[i].pendingB);
		t_execution[i].valid &= res_valid_out[i];
		t_execution[i].valid &= ~busy_fu[t_execution[i].functional_unit];

		t_execution[i].data1 = res_data_out[i].opA;
		t_execution[i].data2 = res_data_out[i].opB;
	end
	to_execution ex_dummy;
	always_comb begin
		{t_vector.valid,
		ex_dummy.pc,
		ex_dummy.destination,
		t_vector.instruction,
		ex_dummy.functional_unit,
		ex_dummy.microoperation,
		ex_dummy.rm,
		ex_dummy.rat_id,
		ex_dummy.ticket} = res_extra_out[2];

		t_vector.valid &= ~(res_data_out[2].pendingA | res_data_out[2].pendingB);
		t_vector.valid &= res_valid_out[2];
		t_vector.valid &= vector_q_ready;
		// t_vector.valid &= branch_if[0];

		t_vector.data1 = res_data_out[2].opA;
		t_vector.data2 = res_data_out[2].opB;
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
                    branch_if <= 1;
                end else begin
                    if(flush_valid) begin
                        branch_if <= 1;
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