/*
* @info Intruction Fetch Stage
* @info Sub Modules: Predictor.sv, icache.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief The first stage of the processor. It contains the predictor and the icache
*
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module ifetch #(
    parameter int PC_BITS          = 32  ,
    parameter int INSTR_BITS       = 32  ,
    parameter int FETCH_WIDTH      = 64  ,
    parameter int PACKET_SIZE      = 64  ,
    parameter int RAS_DEPTH        = 8   ,
    parameter int GSH_HISTORY_BITS = 2   ,
    parameter int GSH_SIZE         = 256 ,
    parameter int BTB_SIZE         = 256)
    //Input List
    (
    input  logic                                clk,
    input  logic                                rst_n,
    //Output Interface
    output logic[2*PACKET_SIZE-1:0]             data_out,
    output logic                                valid_o,
    input  logic                                ready_in,
    //Predictor Update Interface
    input  logic                                is_branch,
    input  predictor_update                     pr_update,
    //Restart Interface
    input  logic                                invalid_instruction,
    input  logic                                invalid_prediction,
    input  logic                                is_return_in,
    input  logic                                is_jumpl,
    input  logic[PC_BITS-1:0]                   old_pc,
    //Flush Interface
    input  logic                                must_flush,
    input  logic[PC_BITS-1:0]                   correct_address,
    //ICache Interface
    output logic    [PC_BITS-1:0]               current_pc,
    input  logic                                hit_cache,
    input  logic                                miss,
    input  logic                                partial_access,
    input  logic            [1:0]               partial_type,
    input  logic  [FETCH_WIDTH-1:0]             fetched_data
);

    typedef enum logic[1:0] {NONE, LOW, HIGH} override_priority;
    logic             [    FETCH_WIDTH-1:0] instruction_out    ;
    logic             [        PC_BITS-1:0] next_pc            ;
    logic             [        PC_BITS-1:0] next_pc_2          ;
    logic             [        PC_BITS-1:0] pc_orig            ;
    logic             [        PC_BITS-1:0] target_pc          ;
    logic             [        PC_BITS-1:0] saved_pc           ;
    logic             [        PC_BITS-1:0] next_pc_saved      ;
    logic             [        PC_BITS-1:0] old_pc_saved       ;
    logic             [3*FETCH_WIDTH/4-1:0] partial_saved_instr;
    logic             [                1:0] partial_type_saved ;
    override_priority                       over_priority      ;
    logic                                   hit                ;
    logic                                   new_entry          ;
    logic                                   is_taken           ;
    logic                                   is_return          ;
    logic                                   is_return_fsm      ;
    logic                                   taken_branch_saved ;
    logic                                   taken_branch_1     ;
    logic                                   half_access        ;
    logic                                   taken_branch_2     ;

    fetched_packet packet_a, packet_b;

    assign data_out              = {packet_b,packet_a};
    assign packet_a.pc           = half_access? old_pc_saved : current_pc;
    assign packet_a.data         = instruction_out[INSTR_BITS-1:0];
    assign packet_a.taken_branch = half_access ? taken_branch_saved : taken_branch_1;
    assign packet_b.pc           = half_access ? current_pc : current_pc+4;
    assign packet_b.data         = instruction_out[2*INSTR_BITS-1:INSTR_BITS];
    assign packet_b.taken_branch = half_access ? taken_branch_1 : taken_branch_2;
    assign valid_o = half_access ? hit       & (over_priority==NONE) & ~(is_return_in | is_return_fsm) & ~invalid_prediction & ~must_flush & ~invalid_instruction :
                                   hit_cache & (over_priority==NONE) & ~(is_return_in | is_return_fsm) & ~invalid_prediction & ~must_flush & ~invalid_instruction & ~taken_branch_1;

    //Intermidiate Signals
    assign new_entry = pr_update.valid_jump;
    assign pc_orig   = pr_update.orig_pc;
    assign target_pc = pr_update.jump_address;
    assign is_taken  = pr_update.jump_taken;

    assign is_return = (is_return_in | is_return_fsm) & hit;      //- Might need to use FSM for is_return_in if it's not constantly supplied from the IF/ID
    always_ff @(posedge clk or negedge rst_n) begin : returnFSM
        if(!rst_n) begin
            is_return_fsm <= 0;
        end else begin
            if(!is_return_fsm && is_return_in && !hit) begin
                is_return_fsm <= ~must_flush;
            end else if(is_return_fsm && hit) begin
                is_return_fsm <= 0;
            end
        end
    end

    predictor #(
        .PC_BITS         (PC_BITS         ),
        .RAS_DEPTH       (RAS_DEPTH       ),
        .GSH_HISTORY_BITS(GSH_HISTORY_BITS),
        .GSH_SIZE        (GSH_SIZE        ),
        .BTB_SIZE        (BTB_SIZE        ),
        .FETCH_WIDTH     (FETCH_WIDTH     )
    ) predictor (
        .clk            (clk                 ),
        .rst_n          (rst_n               ),

        .must_flush     (must_flush          ),
        .is_branch      (is_branch           ),
        .branch_resolved(pr_update.valid_jump),

        .new_entry      (new_entry           ),
        .pc_orig        (pc_orig             ),
        .target_pc      (target_pc           ),
        .is_taken       (is_taken            ),

        .is_return      (is_return           ),
        .is_jumpl       (is_jumpl            ),
        .invalidate     (invalid_prediction  ),
        .old_pc         (old_pc              ),

        .pc_in          (current_pc          ),
        .taken_branch_a (taken_branch_1      ),
        .next_pc_a      (next_pc             ),
        .taken_branch_b (taken_branch_2      ),
        .next_pc_b      (next_pc_2           )
    );

    // Create the Output
    assign hit = hit_cache & ~partial_access;
    always_comb begin : DataOut
        if(half_access) begin
            if(partial_type_saved == 2'b11) begin
                instruction_out = {fetched_data[FETCH_WIDTH/4-1:0],partial_saved_instr[FETCH_WIDTH/4-1:0]};
            end else if(partial_type_saved == 2'b10) begin
                instruction_out = {fetched_data[FETCH_WIDTH/2-1:0],partial_saved_instr[FETCH_WIDTH/2-1:0]};
            end else begin
                instruction_out = {fetched_data[3*FETCH_WIDTH/4-1:0],partial_saved_instr[FETCH_WIDTH/4-1:0]};
            end
        end else begin
            instruction_out = fetched_data;
        end
    end

    // Two-Cycle Fetch FSM
    always_ff @(posedge clk or negedge rst_n) begin : isHalf
        if(!rst_n) begin
            half_access <= 0;
        end else begin
            if(partial_access && !half_access && hit_cache) begin
                half_access <= ~(invalid_prediction | invalid_instruction | is_return_in | must_flush | over_priority!=NONE);
            end else if(taken_branch_1 && !half_access && hit_cache) begin
                half_access <= ~((over_priority!=NONE) | invalid_prediction | invalid_instruction | is_return_in | must_flush);
            end else if(half_access && valid_o && ready_in) begin
                half_access <= 0;
            end else if(half_access && hit_cache) begin
                half_access <= ~((over_priority!=NONE) | invalid_prediction | invalid_instruction | is_return_in | must_flush);
            end
        end
    end
    // Half Instruction Management
    always_ff @(posedge clk) begin : HalfInstr
        if(!half_access && hit_cache) begin
            if(partial_access && partial_type == 2'b01) begin
                partial_saved_instr <= {{48{1'b0}},fetched_data[FETCH_WIDTH/4-1:0]};
                old_pc_saved        <= current_pc;
                taken_branch_saved  <= 1'b0;
                next_pc_saved       <= current_pc+8;
                partial_type_saved  <= partial_type;
            end else if(taken_branch_1) begin
                partial_saved_instr <= {{32{1'b0}},fetched_data[FETCH_WIDTH/2-1:0]};
                old_pc_saved        <= current_pc;
                taken_branch_saved  <= taken_branch_1;
                next_pc_saved       <= next_pc+4;
                partial_type_saved  <= 2'b10;
            end else if(partial_access && partial_type == 2'b10) begin
                partial_saved_instr <= {{32{1'b0}},fetched_data[FETCH_WIDTH/2-1:0]};
                old_pc_saved        <= current_pc;
                taken_branch_saved  <= 1'b0;
                next_pc_saved       <= current_pc+8;
                partial_type_saved  <= partial_type;
            end else if(partial_access && partial_type == 2'b11) begin
                partial_saved_instr <= fetched_data[3*FETCH_WIDTH/4-1:0];
                old_pc_saved        <= current_pc;
                taken_branch_saved  <= 1'b0;
                next_pc_saved       <= current_pc+8;
                partial_type_saved  <= partial_type;
            end
        end
    end
    // PC Address Management
    always_ff @(posedge clk or negedge rst_n) begin : PCManagement
        if(!rst_n) begin
            current_pc <= 0;
        end else begin
            // Normal Operation
            if(hit_cache) begin
                if(over_priority==HIGH) begin
                    current_pc <= saved_pc;
                end else if(must_flush) begin
                    current_pc <= correct_address;
                end else if(over_priority==LOW && is_return_fsm) begin
                    current_pc <= next_pc;
                end else if(over_priority==LOW) begin
                    current_pc <= saved_pc;
                end else if(invalid_prediction) begin
                    current_pc <= old_pc;
                end else if (invalid_instruction) begin
                    current_pc <= old_pc;
                end else if (is_return_in) begin
                    current_pc <= next_pc;
                end else if(partial_access && partial_type== 1 && !half_access) begin
                    current_pc <= current_pc +2;
                end else if(taken_branch_1 && !half_access) begin
                    current_pc <= next_pc;
                end else if (partial_access && partial_type== 2 && !half_access) begin
                    current_pc <= current_pc +4;
                end else if (partial_access && partial_type== 3 && !half_access) begin
                    current_pc <= current_pc +6;
                end else if (ready_in && !half_access) begin
                    current_pc <= taken_branch_2 ? next_pc_2 : next_pc;
                end else if (ready_in && half_access) begin
                    current_pc <= taken_branch_1 ? next_pc : next_pc_saved;
                end
            end
        end
    end
    //Override FSM used to indicate a redirection must happen after cache unblocks
        //Flushing takes priority due to being an older instruction
    always_ff @(posedge clk or negedge rst_n) begin : overrideManagement
        if(!rst_n) begin
            over_priority <= NONE;
        end else begin
            if(must_flush && over_priority!=HIGH && !hit_cache) begin
                over_priority <= HIGH;
                saved_pc      <= correct_address;
            end else if(invalid_prediction && over_priority==NONE && !hit_cache) begin
                over_priority <= LOW;
                saved_pc      <= old_pc;
            end else if(invalid_instruction && over_priority==NONE && !hit_cache) begin
                over_priority <= LOW;
                saved_pc      <= old_pc;
            end else if(is_return_in && over_priority==NONE && !hit_cache) begin
                over_priority <= LOW;
                saved_pc      <= old_pc;
            end else if(hit_cache) begin
                over_priority <= NONE;
            end
        end
    end

`ifdef INCLUDE_SVAS
    `include "ifetch_sva.sv"
`endif

endmodule