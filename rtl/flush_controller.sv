/*
* @info Flush Controller
* @info Sub-Modules: fifo_dual_ported.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief Determines if a flush is needes by comparing the next PC after a branch
*        with the result of tis execution.
*
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module flush_controller #(
    parameter PC_BITS        = 32,
    parameter ROB_INDEX_BITS = 3 ,
    parameter MAX_BRANCH_IF  = 2
) (
    input  logic                             clk                ,
    input  logic                             rst_n              ,
    //Input from IF/ID
    input  logic [              PC_BITS-1:0] pc_in_1            ,
    input  logic [              PC_BITS-1:0] pc_in_2            ,
    //Input from Decoder
    input  logic                             valid_transaction  ,
    input  logic                             valid_branch_32a   ,
    input  logic                             valid_transaction_2,
    input  logic                             valid_branch_32b   ,
    //Input Predictor Update
    input  predictor_update                  pr_update          ,
    //Output Port for Flushing
    output logic                             must_flush         ,
    output logic                             delayed_flush      ,
    output logic [              PC_BITS-1:0] correct_address    ,
    output logic [       ROB_INDEX_BITS-1:0] rob_ticket         ,
    output logic [$clog2(MAX_BRANCH_IF)-1:0] rat_id
);

    // #Internal Signals#
    logic [PC_BITS-1:0] taken_address   ;
    logic               fifo_valid, fifo_ready, fifo_ready_2, fifo_pop;
    logic               was_mispredicted;

	//FSM state
	// 1-> capture next pc on next transaction
	// 0 -> do nothing
    logic [              PC_BITS-1:0] saved_correct_addr;
    logic [     ROB_INDEX_BITS-1 : 0] saved_rob_ticket  ;
    logic [$clog2(MAX_BRANCH_IF)-1:0] saved_rat_id      ;
    logic                             capture_1, capture_2;
    logic                             must_capture, delayed_capture;

	//Create the Flush command on misprediction
    assign must_flush       = (pr_update.valid_jump | delayed_capture) ? was_mispredicted & fifo_valid: 1'b0;
    assign delayed_flush    = delayed_capture & was_mispredicted & fifo_valid;
    assign was_mispredicted = (correct_address!=taken_address);
    assign rob_ticket       = delayed_capture ? saved_rob_ticket : pr_update.ticket;
    assign rat_id           = delayed_capture ? saved_rat_id : pr_update.rat_id;
    //Pick the Correct Target Address of the Jump
    always_comb begin : CorrectAddress
        if(delayed_capture) begin
            correct_address = saved_correct_addr;
        end else if(pr_update.jump_taken) begin
            correct_address = pr_update.jump_address;
        end else if(pr_update.is_comp) begin
            correct_address = pr_update.orig_pc+2;
        end else begin
            correct_address = pr_update.orig_pc+4;
        end
    end

    assign fifo_pop = (pr_update.valid_jump | delayed_capture) & fifo_valid;
    //Initialize the Fifo
    fifo_dual_ported #(
        .DW         (PC_BITS),
        .DEPTH      (8)
    )
    fifo_dual_ported  (
        .clk            (clk),
        .rst            (~rst_n),

        .valid_flush    (must_flush),

        .push_1         (capture_1),
        .ready_1        (fifo_ready),
        .push_data_1    (pc_in_1),

        .push_2         (capture_2),
        .ready_2        (fifo_ready_2),
        .push_data_2    (pc_in_2),

        .pop_data_1     (taken_address),
        .valid_1        (fifo_valid),
        .pop_1          (fifo_pop),

        .pop_data_2     (),
        .valid_2        (),
        .pop_2          (1'b0)
        );

	//Signal Address stores
    assign capture_1 = must_capture & valid_transaction;
    assign capture_2 = valid_branch_32a & valid_transaction_2;

    // Delayed Capture FSM
    always_ff @(posedge clk or negedge rst_n) begin : DelayedCapture
        if(!rst_n) begin
            delayed_capture <= 0;
        end else begin
            if(pr_update.valid_jump && must_capture && !fifo_valid) begin
                delayed_capture    <= 1;
                saved_rob_ticket   <= pr_update.ticket;
                saved_rat_id       <= pr_update.rat_id;
                saved_correct_addr <= pr_update.jump_taken ? pr_update.jump_address : pr_update.orig_pc + 4;
            end else if(delayed_capture && fifo_valid) begin
                delayed_capture <= 0;
            end
        end
    end

	//FSM Control (indicates the save of a PC after a branch)
	always_ff @(posedge clk or negedge rst_n) begin : CaptureState
		if(!rst_n) begin
			must_capture <= 0;
		end else begin
            if(must_flush) begin
                must_capture <= 0;
            end	else if(must_capture && valid_transaction) begin
				//Reset Capture State
				must_capture <= (valid_branch_32b & valid_transaction_2) | (valid_branch_32a & ~valid_transaction_2);
			end else if (!must_capture && valid_transaction) begin
				//Get a new Capture State
				must_capture <= (valid_branch_32b & valid_transaction_2) | (valid_branch_32a & ~valid_transaction_2);
			end
		end
	end

`ifdef INCLUDE_SVAS
    `include "flush_controller_sva.sv"
`endif

endmodule