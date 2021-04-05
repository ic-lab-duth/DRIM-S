/*
* @info Intruction Decode Stage
* @info Sub Modules: decoder.sv, flush_controller.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief The second stage of the processor. It contains two decoders for compressd instructions
         a decoder for the full-length isntructions, as well as the flush controller.
*
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module idecode #(
    parameter INSTR_BITS     = 32,
    parameter FETCH_WIDTH    = 32,
    parameter PC_BITS        = 32,
    parameter ROB_INDEX_BITS = 3 ,
    parameter MAX_BRANCH_IF  = 2
) (
    input  logic                             clk                ,
    input  logic                             rst_n              ,
    //Port towards IF
    input  logic                             valid_i            ,
    input  logic                             valid_i_2          ,
    output logic                             ready_o            ,
    input  logic                             taken_branch_1     ,
    input  logic                             taken_branch_2     ,
    input  logic [              PC_BITS-1:0] pc_in_1            ,
    input  logic [           INSTR_BITS-1:0] instruction_in_1   ,
    input  logic [              PC_BITS-1:0] pc_in_2            ,
    input  logic [           INSTR_BITS-1:0] instruction_in_2   ,
    output logic                             is_branch          ,
    //Output Port towards IF (Redirection Ports)
    output logic                             invalid_instruction,
    output logic                             invalid_prediction ,
    output logic                             is_return          ,
    output logic                             is_jumpl           ,
    output logic [              PC_BITS-1:0] old_pc             ,
    //Port towards IS (instruction queue)
    input  logic                             ready_i            , //must indicate at least 2 free slots in queue
    output logic                             valid_o            , //indicates first push
    output decoded_instr                     output1            ,
    output logic                             valid_o_2          , //indicates second push
    output decoded_instr                     output2            ,
    //Predictor Update Port
    input  predictor_update                  pr_update          ,
    //Flush Port
    output logic                             must_flush         ,
    output logic                             delayed_flush      ,
    output logic [              PC_BITS-1:0] correct_address    ,
    output logic [       ROB_INDEX_BITS-1:0] rob_ticket         ,
    output logic [$clog2(MAX_BRANCH_IF)-1:0] flush_rat_id       ,
    //Benchmarking Port
    input  logic                             second_port_free
);

    // #Internal Signals#
    logic [$clog2(MAX_BRANCH_IF):0] branch_if;
    logic                           valid_transaction, valid_branch_32a, valid_branch_32b, ready_o_d;
    logic                           one_slot_free, branch_stall, two_slots_free, two_branches;
    logic                           valid_o_d, valid_o_2_d;

    //Control Flow -IF
    assign ready_o = (ready_o_d & ~branch_stall ) | must_flush;
    //Control Flow -RR
    assign valid_o   = valid_o_d & ~branch_stall & ~must_flush;
    assign valid_o_2 = valid_o_2_d & ~branch_stall & ~must_flush;


    assign branch_stall  = (~one_slot_free & is_branch) | (~two_slots_free & two_branches);
    assign one_slot_free = ~(branch_if == MAX_BRANCH_IF);
    assign two_slots_free= (branch_if <= MAX_BRANCH_IF -2);
    assign is_branch     = valid_branch_32a | valid_branch_32b;
    assign two_branches  = valid_branch_32a & valid_branch_32b;
    //Initialize the Decoder
    decoder #(INSTR_BITS,PC_BITS) decoder (
        .clk                (clk                ),
        .rst_n              (rst_n              ),

        .valid_i            (valid_i            ),
        .valid_i_2          (valid_i_2          ),
        .ready_o            (ready_o_d          ),
        .taken_branch_1     (taken_branch_1     ),
        .taken_branch_2     (taken_branch_2     ),
        .pc_in_1            (pc_in_1            ),
        .instruction_in_1   (instruction_in_1   ),
        .pc_in_2            (pc_in_2            ),
        .instruction_in_2   (instruction_in_2   ),

        .invalid_instruction(invalid_instruction),
        .invalid_prediction (invalid_prediction ),
        .is_return_out      (is_return          ),
        .is_jumpl_out       (is_jumpl           ),
        .old_pc             (old_pc             ),

        .valid_transaction  (valid_transaction  ),
        .valid_branch_32a   (valid_branch_32a   ),
        .valid_branch_32b   (valid_branch_32b   ),

        .ready_i            (ready_i            ),
        .valid_o            (valid_o_d          ),
        .output1            (output1            ),
        .valid_o_2          (valid_o_2_d        ),
        .output2            (output2            ),

        .second_port_free   (second_port_free   )
    );
	//Initialize the Flush Controller
    flush_controller #(
        .PC_BITS       (PC_BITS       ),
        .ROB_INDEX_BITS(ROB_INDEX_BITS),
        .MAX_BRANCH_IF (MAX_BRANCH_IF )
    ) flush_controller (
        .clk                (clk                              ),
        .rst_n              (rst_n                            ),

        .pc_in_1            (pc_in_1                          ),
        .pc_in_2            (pc_in_2                          ),

        .valid_transaction  (valid_transaction & ~branch_stall),
        .valid_branch_32a   (valid_branch_32a                 ),
        .valid_transaction_2(valid_o_2                        ),
        .valid_branch_32b   (valid_branch_32b                 ),

        .pr_update          (pr_update                        ),

        .must_flush         (must_flush                       ),
        .correct_address    (correct_address                  ),
        .delayed_flush      (delayed_flush                    ),
        .rob_ticket         (rob_ticket                       ),
        .rat_id             (flush_rat_id                     )
    );

    always_ff @(posedge clk or negedge rst_n) begin : BranchInFlight
        if(!rst_n) begin
            branch_if <= 0;
        end else begin
            if(must_flush) begin
                branch_if <= 0;
            end else if(two_branches && !branch_stall) begin
                if(!pr_update.valid_jump) begin
                    branch_if <= branch_if + 2;
                end else begin
                    branch_if <= branch_if + 1;
                end
            end else if(is_branch && !branch_stall) begin
                if(!pr_update.valid_jump) begin
                    branch_if <= branch_if + 1;
                end
            end else if (pr_update.valid_jump && |branch_if) begin
                branch_if <= branch_if - 1;
            end
        end
    end

`ifdef INCLUDE_SVAS
    `include "idecode_sva.sv"
`endif


endmodule