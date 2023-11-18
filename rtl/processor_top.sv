
/*
* @info Processor Top Level
* @info Sub-Modules: IF.sv, ID.sv, Issue.sv, execution.sv, ROB.sv
* @info Sub-Modules: eb_buff_generic.sv, fifo_dual_ported.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief Initializes the Processor Stages, the pipeline registers
*        and creates their interconnects
*
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module processor_top #(
    parameter int ADDR_BITS        = 32 ,
    parameter int INSTR_BITS       = 32 ,
    parameter int FETCH_WIDTH      = 64 ,
    parameter int DATA_WIDTH       = 32 ,
    parameter int MICROOP_WIDTH    = 5  ,
    parameter int PR_WIDTH         = 6  ,
    parameter int ROB_ENTRIES      = 8  ,
    parameter int RAS_DEPTH        = 8  ,
    parameter int GSH_HISTORY_BITS = 2  ,
    parameter int GSH_SIZE         = 256,
    parameter int BTB_SIZE         = 256,
    parameter int DUAL_ISSUE       = 1  ,
    parameter int MAX_BRANCH_IF    = 2  ,
    parameter int CSR_DEPTH        = 64 ,
    parameter int VECTOR_ENABLED   = 0  ,
    parameter int VECTOR_ELEM      = 4  ,
    parameter int VECTOR_ACTIVE_EL = 4  ,
    // VECTOR
    parameter int VECTOR_DATA_FROM_SCALAR,
    parameter int VECTOR_INSTRUCTION_BITS,
    parameter int VECTOR_NUMBER_VECTOR_LANES,
    parameter int VECTOR_LANES_DATA_WIDTH,
    parameter int VECTOR_MICROOP_BIT,
    parameter int VECTOR_NUMBER_OF_REGISTERS,
    parameter int VECTOR_LENGTH_RANGE,
    parameter int VECTOR_BUS_WIDTH,
    parameter int VECTOR_MEMORY_BITS,
    parameter int VECTOR_ADDR_RANGE,
    parameter int VECTOR_MULTICYCLE_OPERATION_CYCLES,
    parameter int VECTOR_VREG_BITS
) (
    input  logic                           clk               ,
    input  logic                           rst_n             ,
    //Input from ICache
    output logic [          ADDR_BITS-1:0] current_pc        ,
    input  logic                           hit_icache        ,
    input  logic                           miss_icache       ,
    input  logic                           partial_access    ,
    input  logic [                    1:0] partial_type      ,
    input  logic [        FETCH_WIDTH-1:0] fetched_data      ,
    // Writeback into DCache (stores)
    output logic                           cache_wb_valid_o   ,
    output logic [          ADDR_BITS-1:0] cache_wb_addr_o    ,
    output logic [         DATA_WIDTH-1:0] cache_wb_data_o    ,
    output logic [      MICROOP_WIDTH-1:0] cache_wb_microop_o ,
    // Load for DCache
    output logic                           cache_load_valid   ,
    output logic [          ADDR_BITS-1:0] cache_load_addr    ,
    output logic [           PR_WIDTH-1:0] cache_load_dest    ,
    output logic [      MICROOP_WIDTH-1:0] cache_load_microop ,
    output logic [$clog2(ROB_ENTRIES)-1:0] cache_load_ticket  ,
    //Misc
    input  ex_update                       cache_fu_update    ,
    input  logic                           cache_store_blocked,
    input  logic                           cache_load_blocked ,
    input  logic                           cache_will_block   ,
    output logic                           ld_st_output_used
);
	localparam ROB_INDEX_BITS = $clog2(ROB_ENTRIES);
	localparam C_NUM          = MAX_BRANCH_IF      ;
	//////////////////////////////////////////////////
	//                  IF-Stage                    //
    //////////////////////////////////////////////////
    fetched_packet dummy_fetched_packet                              ;
    localparam     PACKET_SIZE          = $bits(dummy_fetched_packet);

    logic            [    ADDR_BITS-1 : 0] old_pc             ;
    logic            [    ADDR_BITS-1 : 0] flush_address      ;
    logic                                  if_taken_branch    ;
    logic                                  if_valid_o         ;
    logic                                  if_ready_in        ;
    logic                                  flush_valid        ;
    logic                                  delayed_flush      ;
    logic                                  is_branch          ;
    logic                                  invalid_instruction;
    logic                                  invalid_prediction ;
    logic                                  is_return          ;
    logic                                  is_jumpl           ;
    predictor_update                       pr_update_o        ;
    logic            [2*PACKET_SIZE-1 : 0] if_data_out        ;


    ifetch #(
        .PC_BITS         (ADDR_BITS       ),
        .INSTR_BITS      (INSTR_BITS      ),
        .FETCH_WIDTH     (FETCH_WIDTH     ),
        .PACKET_SIZE     (PACKET_SIZE     ),
        .RAS_DEPTH       (RAS_DEPTH       ),
        .GSH_HISTORY_BITS(GSH_HISTORY_BITS),
        .GSH_SIZE        (GSH_SIZE        ),
        .BTB_SIZE        (BTB_SIZE        )
    ) ifetch (
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        //Output Interface
        .data_out           (if_data_out        ),
        .valid_o            (if_valid_o         ),
        .ready_in           (if_ready_in        ),
        //Predictor Update Interface
        .is_branch          (is_branch          ),
        // .is_branch              (1'b0),
        .pr_update          (pr_update_o        ),
        //Restart Interface
        .invalid_instruction(invalid_instruction),
        .invalid_prediction (invalid_prediction ),
        .is_return_in       (is_return          ),
        .is_jumpl           (is_jumpl           ),
        .old_pc             (old_pc             ),
        //Flush Interface
        .must_flush         (flush_valid        ),
        .correct_address    (flush_address      ),
        //ICache Interface
        .current_pc         (current_pc         ),
        .hit_cache          (hit_icache         ),
        .miss               (miss_icache        ),
        .partial_access     (partial_access     ),
        .partial_type       (partial_type       ),
        .fetched_data       (fetched_data       )
    );
	//////////////////////////////////////////////////
	//           IF/ID PIPELINE REGISTER            //
	//////////////////////////////////////////////////
    logic [2*PACKET_SIZE-1:0] data_if_id_o;
    logic                     id_valid_i  ;
    logic                     id_ready_o  ;

    eb_buff_generic #(
        .DW         (2*PACKET_SIZE),
        .BUFF_TYPE  (1),
        .DEPTH      ())             //NC
    IF_ID(
        .clk        (clk),
        .rst        (~rst_n),

        .data_i     (if_data_out),
        .valid_i    (if_valid_o),
        .ready_o    (if_ready_in),

		.data_o     (data_if_id_o),
		.valid_o    (id_valid_i),
		.ready_i    (id_ready_o)
		);
	//////////////////////////////////////////////////
	//                  ID-Stage                    //
	//////////////////////////////////////////////////
    logic          [         ROB_INDEX_BITS-1 : 0] flush_rob_ticket;
    fetched_packet                                 packet_a, packet_b;

    assign packet_a = data_if_id_o[PACKET_SIZE-1:0];
    assign packet_b = data_if_id_o[2*PACKET_SIZE-1:PACKET_SIZE];

	decoded_instr                     id_decoded_1 ;
	decoded_instr                     id_decoded_2 ;
	logic                             iq_ready_1   ;
	logic                             iq_ready_2   ;
	logic                             id_valid_1   ;
	logic                             id_valid_2   ;
	logic         [$clog2(C_NUM)-1:0] flush_rat_id ;
	logic                             id_rr_ready  ;
	logic                             id_ir_valid_o;
	logic                             id_valid_2_o ;
	logic                             ir_valid_o_2 ;

    // ID STAGE
    idecode #(
        .PC_BITS       (ADDR_BITS     ),
        .INSTR_BITS    (INSTR_BITS    ),
        .FETCH_WIDTH   (FETCH_WIDTH   ),
        .ROB_INDEX_BITS(ROB_INDEX_BITS),
        .MAX_BRANCH_IF (MAX_BRANCH_IF )
    ) idecode (
        .clk                (clk                  ),
        .rst_n              (rst_n                ),
        //Port towards IF
        .valid_i            (id_valid_i           ),
        .ready_o            (id_ready_o           ),
        .instruction_in_1   (packet_a.data        ),
        .pc_in_1            (packet_a.pc          ),
        .taken_branch_1     (packet_a.taken_branch),
        .valid_i_2          (id_valid_i           ),
        .instruction_in_2   (packet_b.data        ),
        .pc_in_2            (packet_b.pc          ),
        .taken_branch_2     (packet_b.taken_branch),
        .is_branch          (is_branch            ),
        //Output Port towards IF (Redirection Ports)
        .invalid_instruction(invalid_instruction  ),
        .invalid_prediction (invalid_prediction   ),
        .is_return          (is_return            ),
        .is_jumpl           (is_jumpl             ),
        .old_pc             (old_pc               ),
        //Port towards RR (instruction queue)
        .ready_i            (id_rr_ready          ),
        .valid_o            (id_valid_1           ),
        .output1            (id_decoded_1         ),
        .valid_o_2          (id_valid_2           ),
        .output2            (id_decoded_2         ),
        // Predictor Update Port
        .pr_update          (pr_update_o          ),
        //Flush Port
        .must_flush         (flush_valid          ),
        .delayed_flush      (delayed_flush        ),
        .correct_address    (flush_address        ),
        .rob_ticket         (flush_rob_ticket     ),
        .flush_rat_id       (flush_rat_id         ),
        //Benchmarking Ports
        .second_port_free   (~ir_valid_o_2        )
    );
    //////////////////////////////////////////////////
    //            ID/RR PIPELINE REGISTER           //
    //////////////////////////////////////////////////
    localparam DECODED_SIZE       = $bits(id_decoded_1)      ;
    localparam DECODE_OUTPUT_SIZE = 2*$bits(id_decoded_1) + 2;

	logic         [DECODE_OUTPUT_SIZE-1:0] id_ir_data;
	logic         [DECODE_OUTPUT_SIZE-1:0] id_ir_data_o  ;
	logic                                  rr_ready;
	logic                                  id_valid_1_o  ;
	decoded_instr                          id_decoded_1_o;
	decoded_instr                          id_decoded_2_o;

    assign id_ir_data = {id_valid_1,id_valid_2,id_decoded_2,id_decoded_1};
    eb_buff_generic #(
        .DW         (DECODE_OUTPUT_SIZE),
        .BUFF_TYPE  (1),
        .DEPTH      ())             //NC
    ID_RR(
        .clk        (clk),
        .rst        (~rst_n),

        .data_i     (id_ir_data),
        .valid_i    (id_valid_1),
        .ready_o    (id_rr_ready),

        .data_o     (id_ir_data_o),
        .valid_o    (id_ir_valid_o),
        .ready_i    (rr_ready)
        );
    assign id_decoded_1_o = id_ir_data_o[0 +: DECODED_SIZE];
    assign id_decoded_2_o = id_ir_data_o[DECODED_SIZE +: DECODED_SIZE];
    assign id_valid_2_o   = id_ir_data_o[DECODE_OUTPUT_SIZE-2];
    assign id_valid_1_o   = id_ir_data_o[DECODE_OUTPUT_SIZE-1];
    //////////////////////////////////////////////////
    //              Register Renaming               //
    //////////////////////////////////////////////////
	writeback_toARF retired_instruction_o, retired_instruction_o_2;
	renamed_instr   renamed_1;
	renamed_instr   renamed_2            ;
	to_issue        rob_status           ;
	new_entries     new_rob_requests     ;
	logic           ir_valid_o_1         ;

    rr #(
        .P_REGISTERS   (64            ),
        .L_REGISTERS   (2**(PR_WIDTH) ),
        .ROB_INDEX_BITS(ROB_INDEX_BITS),
        .C_NUM         (C_NUM         ),
        .VECTOR_ENABLED(VECTOR_ENABLED)
    ) rr (
        .clk            (clk                         ),
        .rst_n          (rst_n                       ),
        //Port towards ID
        .ready_o        (rr_ready                    ),
        .valid_i_1      (id_ir_valid_o & id_valid_1_o),
        .instruction_1  (id_decoded_1_o              ),
        .valid_i_2      (id_ir_valid_o & id_valid_2_o),
        .instruction_2  (id_decoded_2_o              ),
        //Port towards IS
        .ready_i        (iq_ready_1 & iq_ready_2     ),
        .valid_o_1      (ir_valid_o_1                ),
        .instruction_o_1(renamed_1                   ),
        .valid_o_2      (ir_valid_o_2                ),
        .instruction_o_2(renamed_2                   ),
        //Port towards ROB
        .rob_status     (rob_status                  ),
        .rob_requests   (new_rob_requests            ),
        //Commit Port
        .commit_1       (retired_instruction_o       ),
        .commit_2       (retired_instruction_o_2     ),
        //Flush Port
        .flush_valid    (flush_valid                 ),
        .pr_update      (pr_update_o                 ),
        .flush_rat_id   (flush_rat_id                )
    );
    //////////////////////////////////////////////////
    //              Instruction Queue               //
    //////////////////////////////////////////////////
	localparam    DECODED_INSTR_DW = $bits(renamed_1);
	renamed_instr renamed_o_1;
	renamed_instr renamed_o_2     ;
	logic         iq_valid_1;
	logic         iq_valid_2      ;
	logic         iq_pop_1        ;
	logic         iq_pop_2        ;

    // RR/IS INSTRUCTION QUEUE
    fifo_dual_ported #(
        .DW   (DECODED_INSTR_DW),
        .DEPTH(4               )
    ) instruction_queue (
        .clk        (clk         ),
        .rst        (~rst_n      ),

        .valid_flush(flush_valid ),

        .push_1     (ir_valid_o_1),
        .ready_1    (iq_ready_1  ),
        .push_data_1(renamed_1   ),

        .push_2     (ir_valid_o_2),
        .ready_2    (iq_ready_2  ),
        .push_data_2(renamed_2   ),

        .pop_data_1 (renamed_o_1 ),
        .valid_1    (iq_valid_1  ),
        .pop_1      (iq_pop_1    ),

        .pop_data_2 (renamed_o_2 ),
        .valid_2    (iq_valid_2  ),
        .pop_2      (iq_pop_2    )
    );
    //////////////////////////////////////////////////
    //                  IS-Stage                    //
    //////////////////////////////////////////////////
    logic [3:0][ROB_INDEX_BITS-1:0]   read_addr_rob;
    logic [3:0][DATA_WIDTH-1:0]       data_out_rob;
    to_execution [          1 : 0] t_execution       ;
    to_vector                      t_vector          ;
    ex_update    [          3 : 0] fu_update_o       ;
    ex_update    [          3 : 0] fu_update         ;
    logic        [          3 : 0] busy_fu           ;
    new_entries                    new_rob_requests_o;
    logic                          flush_ready       ;
    logic                          vector_ready      ;
    logic                          issue_1           ;
    logic                          issue_2           ;
    logic                          issue_vector      ;
    logic        [ROB_ENTRIES-1:0] flush_vector      ;
    logic        [ROB_ENTRIES-1:0] flush_vector_o    ;

    //Create the IQ Pop Signals
    assign iq_pop_1 = issue_1 | issue_vector;
    assign iq_pop_2 = issue_2;
    issue #(
        .SCOREBOARD_SIZE(64            ),
        .FU_NUMBER      (4             ),
        .ROB_INDEX_BITS (ROB_INDEX_BITS),
        .DATA_WIDTH     (DATA_WIDTH    ),
        .C_NUM          (C_NUM         ),
        .DUAL_ISSUE     (DUAL_ISSUE    ),
        .VECTOR_ENABLED (VECTOR_ENABLED)
    ) issue (
        .clk             (clk                      ),
        .rst_n           (rst_n                    ),
        //Input of Renamed Instructions
        .valid_1         (iq_valid_1 & ~flush_valid),
        .Instruction1    (renamed_o_1              ),
        .valid_2         (iq_valid_2 & ~flush_valid),
        .Instruction2    (renamed_o_2              ),
        .vector_q_ready  (vector_ready             ),
        //Issue Indicators (pop enablers)
        .issue_1         (issue_1                  ),
        .issue_2         (issue_2                  ),
        .issue_vector    (issue_vector             ),
        //Commited Instruction
        .writeback_1     (retired_instruction_o    ),
        .writeback_2     (retired_instruction_o_2  ),
        //Flush Interface
        .pr_update       (pr_update_o              ),
        .flush_valid     (flush_ready              ),
        .flush_vector_inv(flush_vector_o           ),
        //Busy Signals from Functional Units
        .busy_fu         (busy_fu                  ),
        //Outputs from Functional Units
        .fu_update_frw   (fu_update                ),
        .fu_update       (fu_update_o              ),
        //Signals towards the EX stage
        .t_execution     (t_execution              ),
        .t_vector        (t_vector                 ),
        //Forward Port from ROB
        .read_addr_rob   (read_addr_rob            ),
        .data_out_rob    (data_out_rob             )
    );

	//////////////////////////////////////////////////
	//           IS/EX PIPELINE REGISTER            //
	//////////////////////////////////////////////////
	localparam TO_EX_DW  = $bits(t_execution[0])               ;
	localparam ISSUED_DW = 2*TO_EX_DW + $bits(new_rob_requests);

	logic [ISSUED_DW-1:0] issued_data_merged  ;
	logic [ISSUED_DW-1:0] issued_data_merged_o;
	to_execution[1 : 0]   t_execution_o;
	//Merge the Data to a single vector
	assign issued_data_merged = {new_rob_requests, t_execution[1] , t_execution[0]};

    eb_buff_generic #(
        .DW         (ISSUED_DW),
        .BUFF_TYPE  (1),
        .DEPTH      ())             //NC
    IS_EX(
        .clk        (clk),
        .rst        (~rst_n),

        .data_i     (issued_data_merged),
        .valid_i    (1'b1),
        .ready_o    (),             //NC

        .data_o     (issued_data_merged_o),
        .valid_o    (),             //NC
        .ready_i    (1'b1)
        );

    //////////////////////////////////////////////////
    //                  EX-Stage                    //
    //////////////////////////////////////////////////
    //Split the Data from the merged Vector
    assign t_execution_o[0]   = issued_data_merged_o[0+:TO_EX_DW];
    assign t_execution_o[1]   = issued_data_merged_o[TO_EX_DW+:TO_EX_DW];
    assign new_rob_requests_o = issued_data_merged_o[2*TO_EX_DW+:$bits(new_rob_requests)];

	logic            [     ADDR_BITS-1:0] cache_frw_address;
	logic            [     ADDR_BITS-1:0] cache_store_address;
	logic            [    DATA_WIDTH-1:0] cache_frw_data;
	logic            [    DATA_WIDTH-1:0] cache_store_data   ;
	logic            [ROB_INDEX_BITS-1:0] cache_store_ticket ;
	logic            [ MICROOP_WIDTH-1:0] cache_frw_microop  ;
	logic                                 cache_frw_valid;
	logic                                 cache_frw_stall    ;
	logic                                 cache_store_valid  ;
	predictor_update                      pr_update          ;
    execution #(
        .INSTR_BITS    (INSTR_BITS    ),
        .ADDR_BITS     (ADDR_BITS     ),
        .DATA_WIDTH    (DATA_WIDTH    ),
        .FU_NUMBER     (4             ),
        .R_ADDR        (PR_WIDTH      ),
        .MICROOP_WIDTH (MICROOP_WIDTH ),
        .ROB_INDEX_BITS(ROB_INDEX_BITS),
        .CSR_DEPTH     (CSR_DEPTH     )
    ) execution (
        .clk                  (clk                    ),
        .rst_n                (rst_n                  ),
        .t_execution          (t_execution_o          ),
        .cache_fu_update      (cache_fu_update        ),
        .cache_load_blocked   (cache_load_blocked     ),

        .frw_address          (cache_frw_address      ),
        .frw_microop          (cache_frw_microop      ),
        .frw_data             (cache_frw_data         ),
        .frw_valid            (cache_frw_valid        ),
        .frw_stall            (cache_frw_stall        ),

        .cache_writeback_valid(cache_wb_valid_o       ),

        .store_valid          (cache_store_valid      ),
        .store_address        (cache_store_address    ),
        .store_data           (cache_store_data       ),
        .store_microop        (                       ), //NC
        .store_ticket         (cache_store_ticket     ),

        .cache_load_valid     (cache_load_valid       ),
        .cache_load_addr      (cache_load_addr        ),
        .cache_load_dest      (cache_load_dest        ),
        .cache_load_microop   (cache_load_microop     ),
        .cache_load_ticket    (cache_load_ticket      ),

        .output_used          (ld_st_output_used      ),
        .busy_fu              (busy_fu                ),
        .fu_update            (fu_update              ),
        .pr_update            (pr_update              ),

        .commit_1             (retired_instruction_o  ),
        .commit_2             (retired_instruction_o_2)
    );

    //////////////////////////////////////////////////
    //           EX/WB PIPELINE REGISTER            //
    //////////////////////////////////////////////////
	localparam FU_UPDATE_DW = $bits(fu_update[0])              ;
	localparam EX_MERGED_DW = 4*FU_UPDATE_DW + $bits(pr_update);

    logic           [ EX_MERGED_DW-1:0] data_ex_merged_i   ;
    logic           [ EX_MERGED_DW-1:0] data_ex_merged_o   ;
    logic           [    ADDR_BITS-1:0] cache_wb_addr      ;
    logic           [   DATA_WIDTH-1:0] cache_wb_data      ;
    logic           [MICROOP_WIDTH-1:0] cache_wb_microop   ;
    logic                               cache_wb_valid     ;
    writeback_toARF                     retired_instruction, retired_instruction_2;

    assign data_ex_merged_i = {pr_update,fu_update[3],fu_update[2],fu_update[1],fu_update[0]};
    eb_buff_generic #(
        .DW         (EX_MERGED_DW),
        .BUFF_TYPE  (1),
        .DEPTH      ())             //NC
    EX_WB(
        .clk        (clk),
        .rst        (~rst_n),

        .data_i     (data_ex_merged_i),
        .valid_i    (1'b1),
        .ready_o    (),             //NC

        .data_o     (data_ex_merged_o),
        .valid_o    (),             //NC
        .ready_i    (1'b1)
        );
    //////////////////////////////////////////////////
    //                  WB-Stage                    //
    //////////////////////////////////////////////////
    logic store_ready;

	assign fu_update_o[0] = data_ex_merged_o[0+:FU_UPDATE_DW];
	assign fu_update_o[1] = data_ex_merged_o[FU_UPDATE_DW+:FU_UPDATE_DW];
	assign fu_update_o[2] = data_ex_merged_o[2*FU_UPDATE_DW+:FU_UPDATE_DW];
	assign fu_update_o[3] = data_ex_merged_o[3*FU_UPDATE_DW+:FU_UPDATE_DW];
	assign pr_update_o    = data_ex_merged_o[4*FU_UPDATE_DW+:$bits(pr_update)];

    rob #(
        .ADDR_BITS     (ADDR_BITS     ),
        .ROB_ENTRIES   (ROB_ENTRIES   ),
        .FU_NUMBER     (4             ),
        .ROB_INDEX_BITS(ROB_INDEX_BITS),
        .DATA_WIDTH    (DATA_WIDTH    )
    ) rob (
        .clk                    (clk                   ),
        .rst_n                  (rst_n                 ),
        //Flush Port
        .flush_valid            (flush_valid          ),
        .flush_ticket           (flush_rob_ticket     ),
        .flush_vector_inv       (flush_vector         ),
        //Forwarding Port
        .read_address           (read_addr_rob        ),
        .data_out               (data_out_rob         ),
        //Data Cache Interface (Search Interface)
        .cache_addr             (cache_frw_address    ),
        .cache_microop          (cache_frw_microop    ),
        .cache_data             (cache_frw_data       ),
        .cache_valid            (cache_frw_valid      ),
        .cache_stall            (cache_frw_stall      ),
        //STORE update from Data Cache (Input Interface)
        .store_valid            (cache_store_valid    ),
        .store_data             (cache_store_data     ),
        .store_ticket           (cache_store_ticket   ),
        .store_address          (cache_store_address  ),
        //Writeback into Cache (Output Interface)
        .cache_blocked          (~store_ready         ),
        .cache_writeback_valid  (cache_wb_valid       ),
        .cache_writeback_addr   (cache_wb_addr        ),
        .cache_writeback_data   (cache_wb_data        ),
        .cache_writeback_microop(cache_wb_microop     ),
        //Update from EX (Input Interface)
        .update                 (fu_update_o          ),
        //Interface with IS
        .new_requests           (new_rob_requests_o   ),
        .t_issue                (rob_status           ),
        .writeback_1            (retired_instruction  ),
        .writeback_2            (retired_instruction_2)
    );
    //////////////////////////////////////////////////
    //           WB/RT PIPELINE REGISTER            //
    //////////////////////////////////////////////////
    localparam RETIRED_IS = $bits(retired_instruction);
    localparam RETIRED_ST = $bits(cache_wb_addr)+$bits(cache_wb_data)+$bits(cache_wb_microop)+1;

    logic [2*RETIRED_IS-1:0] retired_merged        ;
    logic [2*RETIRED_IS-1:0] retired_merged_o      ;
    logic [  RETIRED_ST-1:0] retired_merged_store  ;
    logic [  RETIRED_ST-1:0] retired_merged_store_o;

    assign retired_merged       = {cache_wb_valid,cache_wb_microop,cache_wb_data,cache_wb_addr,retired_instruction_2,retired_instruction};
    assign retired_merged_store = {cache_wb_valid,cache_wb_microop,cache_wb_data,cache_wb_addr};
    // retired instruction flop
    eb_buff_generic #(
        .DW         (2*RETIRED_IS),
        .BUFF_TYPE  (1),
        .DEPTH      ())             //NC
    RT(
        .clk        (clk),
        .rst        (~rst_n),

        .data_i     (retired_merged),
        .valid_i    (1'b1),
        .ready_o    (),             //NC

        .data_o     (retired_merged_o),
        .valid_o    (),             //NC
        .ready_i    (1'b1)
        );
    eb_buff_generic #(
        .DW         (RETIRED_ST),
        .BUFF_TYPE  (1),
        .DEPTH      ())             //NC
    // retired store flop
    RT_ST(
        .clk        (clk),
        .rst        (~rst_n),

        .data_i     (retired_merged_store),
        .valid_i    (cache_wb_valid),
        .ready_o    (store_ready),

        .data_o     (retired_merged_store_o),
        .valid_o    (cache_wb_valid_o),
        .ready_i    (~cache_store_blocked)
        );
    // pipeline flush flop
    eb_buff_generic #(
        .DW         (ROB_ENTRIES),
        .BUFF_TYPE  (1),
        .DEPTH      ())             //NC
    FLUSH(
        .clk        (clk),
        .rst        (~rst_n),

        .data_i     (flush_vector),
        .valid_i    (flush_valid),
        .ready_o    (),             //NC

        .data_o     (flush_vector_o),
        .valid_o    (flush_ready),
        .ready_i    (1'b1)
        );

    assign retired_instruction_o   = retired_merged_o[RETIRED_IS-1 : 0];
    assign retired_instruction_o_2 = retired_merged_o[2*RETIRED_IS-1 : RETIRED_IS];
    assign cache_wb_addr_o         = retired_merged_store_o[ADDR_BITS-1 : 0];
    assign cache_wb_data_o         = retired_merged_store_o[ADDR_BITS+DATA_WIDTH-1 : ADDR_BITS];
    assign cache_wb_microop_o      = retired_merged_store_o[ADDR_BITS+DATA_WIDTH+MICROOP_WIDTH-1 : ADDR_BITS+DATA_WIDTH];

    //----------------------------------------------------
    // ------------------VECTOR PIPELINE------------------
    //----------------------------------------------------
    localparam int VECTOR_INSTR_DW = $bits(t_vector);
    generate
        if(VECTOR_ENABLED) begin
            // VECTOR INSTRUCTION QUEUE
            logic     valid_vector, vector_pop;
            to_vector t_vector_o;
            // fifo_dual_ported #(
            //     .DW   (97),
            //     .DEPTH(4              )
            // ) vector_instruction_queue (
            //     .clk        (clk         ),
            //     .rst        (~rst_n      ),

            //     .valid_flush(1'b0        ),

            //     .push_1     (issue_vector),
            //     .ready_1    (vector_ready),
            //     .push_data_1(t_vector    ),

            //     .push_2     (1'b0        ),
            //     .ready_2    (            ),
            //     .push_data_2(            ),

            //     .pop_data_1 (t_vector_o  ),
            //     .valid_1    (valid_vector),
            //     .pop_1      (vector_pop  ),

            //     .pop_data_2 (            ),
            //     .valid_2    (            ),
            //     .pop_2      (1'b0        )
            // );
            logic vector_ready_o;
            logic vector_push;
            assign vector_push = t_vector.valid;
            assign vector_pop = vector_ready_o & valid_vector;

            fifo_duth #(
                .DW   (97),
                .DEPTH(4              )
            ) vector_instruction_queue (
                .clk        (clk         ),
                .rst        (~rst_n      ),

                .push     (vector_push),
                .ready    (vector_ready),
                .push_data(t_vector    ),


                .pop_data (t_vector_o  ),
                .valid    (valid_vector),
                .pop      (vector_pop  )

            );

            logic [95:0] data_from_proc;
            assign data_from_proc = {t_vector_o.instruction, t_vector_o.data2, t_vector_o.data1};
            //VECTOR PIPELINE
            vector_top #(
                .LANES_DATA_WIDTH               (VECTOR_LANES_DATA_WIDTH),
                .MICROOP_BIT                    (VECTOR_MICROOP_BIT),
                .INSTRUCTION_BITS               (VECTOR_INSTRUCTION_BITS),
                .NUMBER_VECTOR_LANES            (VECTOR_NUMBER_VECTOR_LANES),
                .VREG_BITS                      (VECTOR_VREG_BITS),
                .SCALAR_DATA_WIDTH              (DATA_WIDTH),
                .ADDR_RANGE                     (VECTOR_ADDR_RANGE),
                .LENGTH_RANGE                   (VECTOR_LENGTH_RANGE),
                .BUS_WIDTH                      (VECTOR_BUS_WIDTH),
                .MEMORY_BITS                    (VECTOR_MEMORY_BITS),
                .REGISTER_NUMBERS               (VECTOR_NUMBER_OF_REGISTERS),
                .DATA_FROM_SCALAR               (VECTOR_DATA_FROM_SCALAR),
                .MULTICYCLE_OPERATION_CYCLES    (VECTOR_MULTICYCLE_OPERATION_CYCLES)
            )vector_top (
                .clk     (clk         ),
                .rst     (~rst_n      ),
                //Instruction In
                .valid_fifo(valid_vector),
                .instruction(data_from_proc),
                .ready     (vector_ready_o  )
                //Memory Interface
            );
        end
    endgenerate

`ifdef INCLUDE_SVAS
    `include "processor_top_sva.sv"
`endif

endmodule