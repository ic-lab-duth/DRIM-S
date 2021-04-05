/*
* @info Decoder
* @info Sub-Modules: 2x decoder_full.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @note Functional Units:
* 00 : Load/Store Unit
* 01 : Floating Point Unit
* 10 : Integer Unit
* 11 : Branches
*
* @param INSTR_BITS: # of Instruction Bits (default 32 bits)
* @param PC_BITS   : # of PC Bits (default 32 bits)
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module decoder #(INSTR_BITS = 32, PC_BITS=32) (
    input  logic                  clk                ,
    input  logic                  rst_n              ,
    //Port towards IS
    input  logic                  valid_i            ,
    output logic                  ready_o            ,
    input  logic                  valid_i_2          ,
    input  logic                  taken_branch_1     ,
    input  logic                  taken_branch_2     ,
    input  logic [   PC_BITS-1:0] pc_in_1            ,
    input  logic [INSTR_BITS-1:0] instruction_in_1   ,
    input  logic [   PC_BITS-1:0] pc_in_2            ,
    input  logic [INSTR_BITS-1:0] instruction_in_2   ,
    //Output Port towards IF (Redirection Ports)
    output logic                  invalid_instruction,
    output logic                  invalid_prediction ,
    output logic                  is_return_out      ,
    output logic                  is_jumpl_out       ,
    output logic [   PC_BITS-1:0] old_pc             ,
    //Output Port towards Flush Controller
    output logic                  valid_transaction  ,
    output logic                  valid_branch_32a   ,
    output logic                  valid_branch_32b   ,
    //Port towards IS (instruction queue)
    input  logic                  ready_i            , //must indicate at least 2 free slots in queue
    output logic                  valid_o            , //indicates first push
    output decoded_instr          output1            ,
    output logic                  valid_o_2          , //indicates second push
    output decoded_instr          output2            ,
    //Benchmarking Ports
    input  logic                  second_port_free
);

    // #Internal Signals#
    decoded_instr output_full_a,output_full_b;
    logic         must_restart_32a,must_restart_32b;
    logic         valid, valid_32_a, valid_32_b;
    logic         is_jumpl_a,is_jumpl_b, is_return_32a, is_return_32b;
    logic         invalid_instruction_a, invalid_instruction_b;

    assign valid             = valid_i & ready_i;
    assign ready_o           = ready_i;

    assign valid_32_a        = valid;
    assign valid_32_b        = valid & valid_i_2;

    assign valid_o           = valid_32_a & ~must_restart_32a; // & ~invalid_prediction;// & output_full_a.is_valid;
    // assign valid_o_2         = valid_32_b & ~invalid_prediction & ~(is_return_32a && output_full_a.is_valid);// & output_full_b.is_valid;
    assign valid_o_2         = valid_32_b & ~invalid_prediction & ~(is_return_32a && valid_o);// & output_full_b.is_valid;
    assign valid_transaction = valid_o;
    //Pick the Decoded Outputs
    assign output1 = output_full_a;
    assign output2 = output_full_b;

    //Initialize 1 full-decoder for the 32-bit Instructions (full length instructions)
    decoder_full #(INSTR_BITS,PC_BITS) decoder_full_a (
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .valid           (valid_32_a      ),
        .PC_in           (pc_in_1         ),
        .instruction_in  (instruction_in_1),
        .outputs         (output_full_a   ),
        .valid_branch    (valid_branch_32a),
        .is_jumpl        (is_jumpl_a      ),
        .is_return       (is_return_32a   ),
        .second_port_free(second_port_free)
    );
    decoder_full #(INSTR_BITS,PC_BITS) decoder_full_b (
        .clk             (clk             ),
        .rst_n           (rst_n           ),
        .valid           (valid_32_b      ),
        .PC_in           (pc_in_2         ),
        .instruction_in  (instruction_in_2),
        .outputs         (output_full_b   ),
        .valid_branch    (valid_branch_32b),
        .is_jumpl        (is_jumpl_b      ),
        .is_return       (is_return_32b   ),
        .second_port_free(second_port_free)
    );

    //Restart the Fetch on misPredicted taken on non-branch instruction
    assign invalid_prediction = must_restart_32a | must_restart_32b;
    assign must_restart_32a   = taken_branch_1 & ~valid_branch_32a & output_full_a.is_valid;
    assign must_restart_32b   = taken_branch_2 & ~valid_branch_32b & output_full_b.is_valid;

    always_comb begin : OldPC
        if(must_restart_32a) begin
            old_pc = pc_in_1;
        end else if(invalid_instruction_a) begin
            old_pc = pc_in_1;
        end else if(must_restart_32b) begin
            old_pc = pc_in_2;
        end else if(invalid_instruction_b) begin
            old_pc = pc_in_2;
        end else if(is_jumpl_out) begin
            old_pc = is_jumpl_a ? pc_in_1+4 : pc_in_2+4;
            // old_pc = is_jumpl_a ? pc_in_1 : pc_in_2;
        end else begin
            old_pc = pc_in_1;
        end
    end

    // assign is_jumpl_out  = valid & ((is_jumpl_a & output_full_a.is_valid) | (is_jumpl_b & output_full_b.is_valid));
    assign is_jumpl_out  = valid & ((is_jumpl_a & valid_o) | (is_jumpl_b & valid_o_2));
    // assign is_return_out = valid & ((is_return_32a && output_full_a.is_valid) | (is_return_32b && output_full_b.is_valid));
    assign is_return_out = valid & ((is_return_32a && valid_o) | (is_return_32b && valid_o_2));

    //Restart due to misaligned - invalid instructions
    assign invalid_instruction   = invalid_instruction_a | invalid_instruction_b;
    assign invalid_instruction_a = valid_32_a & (~output_full_a.is_valid);
    assign invalid_instruction_b = valid_32_b & (~output_full_b.is_valid);

`ifdef INCLUDE_SVAS
    `include "decoder_sva.sv"
`endif

endmodule