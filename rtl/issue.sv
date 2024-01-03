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
    parameter SCOREBOARD_SIZE 	= 128,
    parameter FU_NUMBER       	= 4 ,
    parameter ROB_INDEX_BITS  	= 3 ,
    parameter DATA_WIDTH      	= 32,
    parameter C_NUM           	= 4 ,
    parameter DUAL_ISSUE      	= 1 ,
    parameter VECTOR_ENABLED  	= 0 ,
	parameter STATIONS 			= 4
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
    input  logic        [SCOREBOARD_SIZE-1:0]                     	  flush_vector_inv,
    //Busy Signals from Functional Units
    input  logic        [                    3:0]                     busy_fu         ,
    //Outputs from Functional Units
    input  ex_update    [          FU_NUMBER-1:0]                     fu_update       ,
    input  ex_update    [          FU_NUMBER-1:0]                     fu_update_frw   ,
    //Forward Port from ROB
    output logic        [                    5:0][ROB_INDEX_BITS-1:0] read_addr_rob   ,
    input  logic        [                    5:0][    DATA_WIDTH-1:0] data_out_rob    ,
    //Signals towards the EX stage
    output to_execution [         STATIONS - 2:0]                     t_execution     ,
    output to_vector                                                  t_vector,

	input logic [6 : 0] rob_regfile_address,
    output logic [DATA_WIDTH - 1 : 0] rob_regfile_data,
	input logic [6 : 0] rob_regfile_address_to_store,
    output logic [DATA_WIDTH - 1 : 0] rob_regfile_data_to_store,

	input logic vector_mem_op_done,
	input logic scalar_load_done,
	input logic scalar_store_done
);
    logic wr_en_1;
    logic wr_en_2;
    logic [SCOREBOARD_SIZE - 1 : 0] register_pending;

	//*----------------------------------------------------------------*//
    //*----------------------- REGISTER STATUS ------------------------*//
    //*----------------------------------------------------------------*//
	logic [SCOREBOARD_SIZE-1:0] instr_1_dest_oh;
	logic [SCOREBOARD_SIZE-1:0] instr_2_dest_oh;
    assign instr_1_dest_oh = 1 << Instruction1.destination;
    assign instr_2_dest_oh = 1 << Instruction2.destination;

	logic [FU_NUMBER - 1 : 0][SCOREBOARD_SIZE - 1 : 0] fu_dest_oh;
	always_comb for (int i = 0; i < FU_NUMBER; ++i) fu_dest_oh[i] = 1 << fu_update[i].destination;


	// Update the Scoreboard.pending Field
	always_ff @(posedge clk or negedge rst_n) begin : SCpending
		if(!rst_n) begin
			for (int i = 0; i < SCOREBOARD_SIZE; i++) begin
				register_pending[i] <= 0;
			end
		end else begin
			//x0 is unwrittable -> never pending -> no commit will ever arrive for x0
			register_pending[0] <= 'b0;
			for (int i = 1; i < SCOREBOARD_SIZE; i++) begin
				if (flush_valid && flush_vector_inv[i]) begin
					//Flush the Entry
					register_pending[i] <= 0;
				end else if(wr_en_2 && instr_2_dest_oh[i]) begin
					// Issued 2
					register_pending[i] <= |Instruction2.destination;
				end else if(wr_en_1 && instr_1_dest_oh[i]) begin
					// Issued 1
					register_pending[i] <= |Instruction1.destination;
				end else for (int j = 0; j < FU_NUMBER; ++j) if (fu_update[j].valid && fu_dest_oh[j][i]) register_pending[i] <= 0;
			end
		end
	end



	//*----------------------------------------------------------------*//
    //*------------------------ REGISTER FILE -------------------------*//
    //*----------------------------------------------------------------*//
	localparam READ_PORTS = 11;
	logic [READ_PORTS-1:0][6 : 0]            read_Addr_RF;
    logic [READ_PORTS-1:0][DATA_WIDTH-1 : 0] data_Out_RF;

    logic [FU_NUMBER - 1 : 0] 					write_En;
    logic [FU_NUMBER - 1 : 0][6 : 0] 			write_Addr_RF;
    logic [FU_NUMBER - 1 : 0][DATA_WIDTH-1:0] 	write_Data;
	// Initialize the Register File & Signals
	always_comb for (int i = 0; i < FU_NUMBER; ++i) begin
		write_En[i] 		= fu_update[i].valid;
		write_Addr_RF[i] 	= fu_update[i].destination;
		write_Data[i] 		= fu_update[i].data;
	end

	register_file #(
		.DATA_WIDTH	(DATA_WIDTH     ),
		.ADDR_WIDTH	(7              ),
		.SIZE      	(SCOREBOARD_SIZE),
		.READ_PORTS	(READ_PORTS     ),
		.WRITE_PORTS(FU_NUMBER		)
	) regfile (
		.clk         (clk            ),
		.rst_n       (rst_n          ),

		.write_En    (write_En       ),
		.write_Addr  (write_Addr_RF  ),
		.write_Data  (write_Data     ),


		.read_Addr   (read_Addr_RF   ),
		.data_Out    (data_Out_RF    )
	);


    //*----------------------------------------------------------------*//
    //*--------------------- BRANCHES IN FLIGHT -----------------------*//
    //*----------------------------------------------------------------*//
    logic [C_NUM:0] branch_if;
    logic [C_NUM-1:0] branch_if_a;
    logic [C_NUM-1:0] branch_if_b;
    assign branch_if_a = branch_if[C_NUM:1];
	assign branch_if_b = branch_if[C_NUM:1] << Instruction1.is_branch;
    logic single_branch;
    logic dual_branch;
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


	//*----------------------------------------------------------------*//
    //*----------------------- MEMORY FENCING -------------------------*//
    //*----------------------------------------------------------------*//
	logic [4 : 0] mem_counter, next_mem_counter;
	logic mem_owner; // 1 : scalar | 0 : vector
	always_ff @(posedge clk) begin
		if (~rst_n) begin
			mem_counter <= 0;
			mem_owner <= 1'b1;
		end else begin
			mem_counter <= next_mem_counter;

			if (mem_owner && mem_counter == 0 && Instruction1.functional_unit == 0 && Instruction1.is_vector && valid_1 & Instruction1.is_valid) mem_owner <= 1'b0;
			else if (!mem_owner && mem_counter == 0 && Instruction1.functional_unit == 0 && !Instruction1.is_vector && valid_1 & Instruction1.is_valid) mem_owner <= 1'b1;
		end
	end

	always_comb begin
		next_mem_counter = mem_counter;
		if (mem_owner) begin // scalar is owner
			if (Instruction1.functional_unit == 0 && !Instruction1.is_vector && wr_en_1) next_mem_counter += 1;
			if (Instruction2.functional_unit == 0 && !Instruction2.is_vector && wr_en_2) next_mem_counter += 1;
			if (scalar_load_done) next_mem_counter -= 1;
			if (scalar_store_done) next_mem_counter -= 1;
		end else begin // vector is owner
			if (Instruction1.functional_unit == 0 && Instruction1.is_vector && wr_en_1) next_mem_counter += 1;
			if (Instruction2.functional_unit == 0 && Instruction2.is_vector && wr_en_2) next_mem_counter += 1;
			if (vector_mem_op_done) next_mem_counter -= 1;
		end
	end

	logic block_mem_1, block_mem_2;
	assign block_mem_1 = Instruction1.functional_unit == 0 && ((!Instruction1.is_vector && !mem_owner) || (Instruction1.is_vector && mem_owner));
	assign block_mem_2 = Instruction2.functional_unit == 0 && ((!Instruction2.is_vector && !mem_owner) || (Instruction2.is_vector && mem_owner));


	//*----------------------------------------------------------------*//
    //*------------------------- ISSUE LOGIC --------------------------*//
    //*----------------------------------------------------------------*//
    logic Ib_dependent_Ia_rs1;
    logic Ib_dependent_Ia_rs2;
    logic Ib_dependent_Ia_rs3;
    assign Ib_dependent_Ia_rs1 = (Instruction2.source1==Instruction1.destination) & |Instruction1.destination;
    assign Ib_dependent_Ia_rs2 = (Instruction2.source2==Instruction1.destination) & |Instruction1.destination;
    assign Ib_dependent_Ia_rs3 = (Instruction2.source3==Instruction1.destination) & |Instruction1.destination;



    logic [STATIONS - 1:0][1:0] valid_signals;
	assign valid_signals[0] = {Instruction2.functional_unit == 0 && !Instruction2.is_vector && !block_mem_2 && !block_mem_1, Instruction1.functional_unit == 0 && !Instruction1.is_vector && !block_mem_1}; // to memory station
	assign valid_signals[1] = {	(Instruction2.functional_unit == 2 || Instruction2.functional_unit == 3)  && !Instruction2.is_vector,
								(Instruction1.functional_unit == 2 || Instruction1.functional_unit == 3) && !Instruction1.is_vector}; // to integer station
	assign valid_signals[2] = {Instruction2.functional_unit == 1 && !Instruction2.is_vector, Instruction1.functional_unit == 1 && !Instruction1.is_vector}; // to floating station
	assign valid_signals[3] = {Instruction2.is_vector && branch_if[0] && !Instruction1.is_branch && !block_mem_2 && !block_mem_1, Instruction1.is_vector && branch_if[0] && !block_mem_1}; // to vector station


	logic rs1_1_found;
	logic rs2_1_found;
	logic rs3_1_found;
	logic rs1_2_found;
	logic rs2_2_found;
	logic rs3_2_found;
	always_comb begin
		rs1_1_found = 0;
		rs2_1_found = 0;
		rs3_1_found = 0;
		rs1_2_found = 0;
		rs2_2_found = 0;
		rs3_2_found = 0;
		for (int i = 0; i < FU_NUMBER; ++i) begin
			if (fu_update[i].destination == Instruction1.source1)  rs1_1_found = 1'b1;
			if (fu_update[i].destination == Instruction1.source2)  rs2_1_found = 1'b1;
			if (fu_update[i].destination == Instruction1.source3)  rs3_1_found = 1'b1;
			if (fu_update[i].destination == Instruction2.source1)  rs1_2_found = 1'b1;
			if (fu_update[i].destination == Instruction2.source2)  rs2_2_found = 1'b1;
			if (fu_update[i].destination == Instruction2.source3)  rs3_2_found = 1'b1;
		end
	end

    renamed_instr [STATIONS - 1:0][1:0] sfc_inst_out;
	logic [1:0][$bits(Instruction1) + C_NUM + 2:0] sfc_all_in;
	logic [STATIONS - 1:0][1:0][$bits(Instruction1) + C_NUM + 2:0] sfc_all_out;
	assign sfc_all_in[0] = {Instruction1,   register_pending[Instruction1.source1] & ~Instruction1.source1_pc & ~rs1_1_found,
                                            register_pending[Instruction1.source2] & ~Instruction1.source2_immediate & ~rs2_1_found,
                                            register_pending[Instruction1.source3] & Instruction1.source3_valid & ~rs3_1_found, branch_if_a};
	assign sfc_all_in[1] = {Instruction2,   (register_pending[Instruction2.source1] | Ib_dependent_Ia_rs1) & ~Instruction2.source1_pc & ~rs1_2_found,
                                            (register_pending[Instruction2.source2] | Ib_dependent_Ia_rs2) & ~Instruction2.source2_immediate & ~rs2_2_found,
                                            (register_pending[Instruction2.source3] | Ib_dependent_Ia_rs3) & Instruction2.source3_valid & ~rs3_2_found, branch_if_b};

	logic [STATIONS - 1:0][1:0] sfc_push;
	logic [STATIONS - 1:0][1:0] sfc_ready_in;

    smart_flow_control 	#(
							.INPUT_PORTS	(2),
							.OUTPUT_PORTS	(2),
							.DATA_WIDTH		($bits(Instruction1) + C_NUM + 3),
							.FIFOS			(STATIONS))
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

    logic [STATIONS - 1:0][1:0][C_NUM - 1 : 0] branches_in_flight;
	logic [STATIONS - 1:0][1:0] pending1, pending2, pending3, inst_is_vector;
	always_comb for (int i = 0; i < STATIONS; ++i) for (int j = 0; j < 2; ++j)
		{sfc_inst_out[i][j], pending1[i][j], pending2[i][j], pending3[i][j], branches_in_flight[i][j]} = sfc_all_out[i][j];

    reservation_entry2_t [STATIONS - 1:0][1:0] res_data_in;
	reservation_entry2_t [STATIONS - 1:0] res_data_out;

	localparam int EXTRA_WIDTH = 	$bits(sfc_inst_out[0][0].is_valid) +
									$bits(sfc_inst_out[0][0].pc) +
									$bits(sfc_inst_out[0][0].destination) +
									$bits(sfc_inst_out[0][0].immediate) +
									$bits(sfc_inst_out[0][0].functional_unit) +
									$bits(sfc_inst_out[0][0].microoperation) +
									$bits(sfc_inst_out[0][0].rm) +
									$bits(sfc_inst_out[0][0].rat_id) +
									$bits(sfc_inst_out[0][0].ticket) +
									$bits(sfc_inst_out[0][0].source1_pc) +
									$bits(sfc_inst_out[0][0].source2_immediate) +
									$bits(sfc_inst_out[0][0].source3_valid);

	logic [STATIONS - 1:0][1:0][EXTRA_WIDTH - 1 : 0] res_extra_in;
	logic [STATIONS - 1:0][EXTRA_WIDTH - 1 : 0] res_extra_out;
	logic [STATIONS - 1:0] res_valid_out;
	always_comb for (int i = 0; i < STATIONS; ++i) for (int j = 0; j < 2; ++j) begin
		res_data_in[i][j].rs1 		= sfc_inst_out[i][j].source1;
		res_data_in[i][j].rs2 		= sfc_inst_out[i][j].source2;
		res_data_in[i][j].rs3 		= sfc_inst_out[i][j].source3;
		res_data_in[i][j].pending1 	= pending1[i][j];
		res_data_in[i][j].pending2 	= pending2[i][j];
		res_data_in[i][j].pending3 	= pending3[i][j];
		res_data_in[i][j].branch_if	= branches_in_flight[i][j];

		res_extra_in[i][j] =
			{sfc_inst_out[i][j].is_valid, sfc_inst_out[i][j].pc, sfc_inst_out[i][j].destination, sfc_inst_out[i][j].immediate,
			sfc_inst_out[i][j].functional_unit, sfc_inst_out[i][j].microoperation,
			sfc_inst_out[i][j].rm, sfc_inst_out[i][j].rat_id, sfc_inst_out[i][j].ticket, sfc_inst_out[i][j].source1_pc, sfc_inst_out[i][j].source2_immediate, sfc_inst_out[i][j].source3_valid};
	end

	logic branch_resolved;
	always_ff @(posedge clk) begin
		branch_resolved <= pr_update.valid_jump;
	end

	genvar gv;
	generate
		for (gv = 0; gv < STATIONS - 1; ++gv) begin : create_stations
			reservation_station #(
									.INPUT_PORTS		(2),
									.OUTPUT_PORTS		(1),
									.SEARCH_PORTS		(FU_NUMBER),
									.REGISTERS			(SCOREBOARD_SIZE),
									.DEPTH				(4),
									.EXTRA_DATA_WIDTH	(EXTRA_WIDTH))
			station			(
								.clk			(clk),
								.rst			(~rst_n),
								.branch_resolved(branch_resolved),
								.flush			(flush_valid),
								.ready_out		(sfc_ready_in[gv]),
								.valid_in		(sfc_push[gv]),
								.data_in		(res_data_in[gv]),
								.extra_in		(res_extra_in[gv]),
								.valid_out		(res_valid_out[gv]),
								.ready_in		(t_execution[gv].valid),
								.data_out		(res_data_out[gv]),
								.extra_out		(res_extra_out[gv]),
								.search_valid	({fu_update[3].valid, fu_update[2].valid, fu_update[1].valid, fu_update[0].valid}),
								.search_tags	({fu_update[3].destination, fu_update[2].destination, fu_update[1].destination, fu_update[0].destination})
							);
		end
	endgenerate

	reservation_station #(
							.INPUT_PORTS		(2),
							.OUTPUT_PORTS		(1),
							.SEARCH_PORTS		(FU_NUMBER),
							.REGISTERS			(SCOREBOARD_SIZE),
							.DEPTH				(4),
							.EXTRA_DATA_WIDTH	(EXTRA_WIDTH))
	vector_station	(
						.clk			(clk),
						.rst			(~rst_n),
						.branch_resolved(branch_resolved),
						.flush			(flush_valid),
						.ready_out		(sfc_ready_in[STATIONS - 1]),
						.valid_in		(sfc_push[STATIONS - 1]),
						.data_in		(res_data_in[STATIONS - 1]),
						.extra_in		(res_extra_in[STATIONS - 1]),
						.valid_out		(res_valid_out[STATIONS - 1]),
						.ready_in		(t_vector.valid),
						.data_out		(res_data_out[STATIONS - 1]),
						.extra_out		(res_extra_out[STATIONS - 1]),
						.search_valid	({fu_update[3].valid, fu_update[2].valid, fu_update[1].valid, fu_update[0].valid}),
						.search_tags	({fu_update[3].destination, fu_update[2].destination, fu_update[1].destination, fu_update[0].destination})
					);
	logic [STATIONS - 1 : 0] rs1_pc;
	logic [STATIONS - 1 : 0] rs2_imm;
	logic [STATIONS - 1 : 0] rs3_valid;
	logic [STATIONS - 1 : 0][6 : 0] rs1_address;
	logic [STATIONS - 1 : 0][6 : 0] rs2_address;
	logic [STATIONS - 1 : 0][6 : 0] rs3_address;
	logic [STATIONS - 1 : 0][31 : 0] rs1_data;
	logic [STATIONS - 1 : 0][31 : 0] rs2_data;
	logic [STATIONS - 1 : 0][31 : 0] rs3_data;
	always_comb for (int i = 0; i < STATIONS - 1; ++i) begin
		{t_execution[i].valid,
		t_execution[i].pc,
		t_execution[i].destination,
		t_execution[i].immediate,
		t_execution[i].functional_unit,
		t_execution[i].microoperation,
		t_execution[i].rm,
		t_execution[i].rat_id,
		t_execution[i].ticket,
		rs1_pc[i], rs2_imm[i], rs3_valid[i]} = res_extra_out[i];

		t_execution[i].valid &= ~(res_data_out[i].pending1 | res_data_out[i].pending2 | res_data_out[i].pending3);
		t_execution[i].valid &= res_valid_out[i] & ~flush_valid;
		t_execution[i].valid &= ~busy_fu[t_execution[i].functional_unit];

		t_execution[i].data1 = rs1_pc[i] 	? t_execution[i].pc 		: rs1_data[i];
		t_execution[i].data2 = rs2_imm[i] 	? t_execution[i].immediate 	: rs2_data[i];
		t_execution[i].data3 = rs3_data[i];
	end
	to_execution ex_dummy;
	logic rs1_pc_v;
	logic rs2_imm_v;
	logic rs3_valid_v;
	always_comb begin
		{t_vector.valid,
		ex_dummy.pc,
		ex_dummy.destination,
		t_vector.instruction,
		ex_dummy.functional_unit,
		ex_dummy.microoperation,
		ex_dummy.rm,
		ex_dummy.rat_id,
		ex_dummy.ticket,
		rs1_pc_v, rs2_imm_v, rs3_valid_v} = res_extra_out[STATIONS - 1];

		t_vector.valid &= ~(res_data_out[STATIONS - 1].pending1 | res_data_out[STATIONS - 1].pending2);
		t_vector.valid &= res_valid_out[STATIONS - 1] & ~flush_valid;
		t_vector.valid &= vector_q_ready;
		// t_vector.valid &= branch_if[0];

		t_vector.data1 = rs1_data[STATIONS - 1];
		t_vector.data2 = rs2_data[STATIONS - 1];
	end
	always_comb for (int i = 0; i < STATIONS; ++i) begin
		rs1_address[i] = res_data_out[i].rs1;
		rs2_address[i] = res_data_out[i].rs2;
		rs3_address[i] = res_data_out[i].rs3;
	end

	assign read_Addr_RF[0] = rs1_address[0];
	assign read_Addr_RF[1] = rs1_address[1];
	assign read_Addr_RF[2] = rs1_address[2];
	assign read_Addr_RF[3] = rs1_address[3];
	assign read_Addr_RF[4] = rs2_address[0];
	assign read_Addr_RF[5] = rs2_address[1];
	assign read_Addr_RF[6] = rs2_address[2];
	assign read_Addr_RF[7] = rs2_address[3];
	assign read_Addr_RF[8] = rs3_address[2];

	assign read_Addr_RF[9] = rob_regfile_address;
	assign read_Addr_RF[10] = rob_regfile_address_to_store;

	assign rs1_data[0] = data_Out_RF[0];
	assign rs1_data[1] = data_Out_RF[1];
	assign rs1_data[2] = data_Out_RF[2];
	assign rs1_data[3] = data_Out_RF[3];
	assign rs2_data[0] = data_Out_RF[4];
	assign rs2_data[1] = data_Out_RF[5];
	assign rs2_data[2] = data_Out_RF[6];
	assign rs2_data[3] = data_Out_RF[7];
	assign rs3_data[0] = 0;
	assign rs3_data[1] = 0;
	assign rs3_data[2] = data_Out_RF[8];
	assign rs3_data[3] = 0;

	assign rob_regfile_data_to_store = data_Out_RF[10];

endmodule