`ifndef IF_IF_SV
`define IF_IF_SV
import dut_parameters_pkg::*;
import dut_structs_pkg::*;
interface IF_if(); 

  timeunit      1ns;
  timeprecision 1ps;

  import IF_pkg::*;

  logic clk;
  logic rst_n;
  logic [2*PACKET_SIZE-1:0] data_out;
  logic                     valid_o;
  logic                     ready_in;
  logic                     is_branch;
  predictor_update          pr_update;
  logic                     invalid_instruction;
  logic                     invalid_prediction;
  logic                     is_return_in;
  logic                     is_jumpl;
  logic [PC_BITS-1:0]       old_PC;
  logic                     must_flush;
  logic [PC_BITS-1:0]       correct_address;
  logic [PC_BITS-1:0]       current_PC;
  logic                     Hit_cache;
  logic                     Miss;
  logic                     partial_access;
  logic [1:0]               partial_type;
  logic [FETCH_WIDTH-1:0]   fetched_data;

  // // ------------------------   Assertion properties  --------------------------
  // // All restart signals that belong to the low tier(inv prediction, inv instruction, function return) are mutually exclusive
  // // only one can be active at each cycle
  // xor_restarts: assert property (@(negedge clk) disable iff(!rst_n) (invalid_prediction||invalid_instruction||is_return_in) |-> ^{invalid_prediction,invalid_instruction,is_return_in})
  //               else $fatal("Illegal to have more than one restart request");

  // // Valid/Ready protocol
  // Valid_stable: assert property (@(negedge clk) disable iff(!rst_n) (valid_o && !ready_in) |=> $stable(data_out))
  //               else $fatal("Data out changed while valid was asserted and ready was low");

  // // When flush is issued then data out cannot be valid
  // flush_valid:  assert property (@(negedge clk) disable iff(!rst_n) must_flush |-> !valid_o)
  //               else $fatal("Flush issued and valid out is asserted");


  // // ------------------------   Cover properties  --------------------------
  // // Sequences 
  // sequence partial_access_1_seq;
  //   partial_access && (partial_type==1) && Hit_cache;
  // endsequence
  // sequence partial_access_2_seq;
  //   partial_access && (partial_type==2) && Hit_cache;
  // endsequence
  // sequence partial_access_3_seq;
  //   partial_access && (partial_type==3) && Hit_cache;
  // endsequence
  // /*----------- Corner cases -----------*/
  // // Issue of invalid prediction (btb invalidation) and predictor update for the same pc at the same cycle
  // btb_invalid_and_pr_update_samePC: cover property (@(negedge clk) disable iff(!rst_n) invalid_prediction |-> (pr_update.valid_jump&&(pr_update.orig_pc==old_PC)));
  
  // // Partial access of type 1(16 valid bits) and branch 1 is taken
  // // IF should fetch the remaining 16 bits of 1st instruction and then fetch the target pc as second instruction
  fetched_packet packet_a, packet_b;
  assign {packet_b,packet_a} = data_out;
  // // partial_access_type1_branch: cover property (@(negedge clk) disable iff(!rst_n) partial_access_1_seq and (packet_a.taken_branch==1));

  // // Partial access of type 2(32 valid bits) and branch 1 is taken
  // // IF should fetch the target pc as second instruction
  // partial_access_type2_branch: cover property (@(negedge clk) disable iff(!rst_n) partial_access_2_seq and (packet_a.taken_branch==1));

  // // Partial access of type 3(48 valid bits) and branch 1 is taken
  // // IF should fetch the target pc as second instruction
  // // partial_access_type3_branch: cover property (@(negedge clk) disable iff(!rst_n) partial_access_3_seq and (packet_a.taken_branch==1));


  // /*----------- IF restart FSM scenarios -----------*/
  // // Invalid instruction while fsm is blocked
  // invalid_instruction_while_icache_blocked: cover property (@(negedge clk) disable iff(!rst_n) invalid_instruction |-> Miss);
  
  // // Invalid prediction while fsm is blocked
  // invalid_prediction_while_icache_blocked: cover property (@(negedge clk) disable iff(!rst_n) invalid_prediction |-> Miss);
  
  // // Flush while fsm is blocked
  // flush_while_icache_blocked: cover property (@(negedge clk) disable iff(!rst_n) must_flush |-> Miss);
  
  // // Flush & invalid instruction issued while fsm is blocked
  // flush_inv_ins_while_icache_blocked: cover property (@(negedge clk) disable iff(!rst_n) must_flush |-> (invalid_instruction&&Miss));
  
  // // Flush & invalid prediction issued while fsm is blocked
  // flush_inv_pred_while_icache_blocked: cover property (@(negedge clk) disable iff(!rst_n) must_flush |-> (invalid_prediction&&Miss));
  
  // // Flush & function return issued while fsm is blocked
  // flush_fnc_ret_while_icache_blocked: cover property (@(negedge clk) disable iff(!rst_n) must_flush |-> (is_return_in&&Miss));
  
  

  // /*----------- Invalid instruction issue scenarios -----------*/
  // // How many invalid instructions issued
  // invalid_instructions: cover property (@(negedge clk) disable iff(!rst_n) invalid_instruction);

  // // How many instructions issued while icache hit
  // invalid_instructions_at_hit: cover property (@(negedge clk) disable iff(!rst_n) invalid_instruction |-> Hit_cache);

  // // How many instructions issued while icache miss
  // invalid_instructions_at_miss: cover property (@(negedge clk) disable iff(!rst_n) invalid_instruction |-> Miss);

  // // How many instructions issued while flush issued
  // invalid_instructions_at_flus: cover property  (@(negedge clk) disable iff(!rst_n) invalid_instruction |-> must_flush);


  // /*----------- Invalid prediction issue scenarios -----------*/
  // // How many invalid predictions issued
  // invalid_predictions: cover property (@(negedge clk) disable iff(!rst_n) invalid_prediction);

  // // How many invalid predictions issued while icache hit
  // invalid_predictions_at_hit: cover property (@(negedge clk) disable iff(!rst_n) invalid_prediction |-> Hit_cache);

  // // How many invalid predictions issued while icache miss
  // invalid_predictions_at_miss: cover property (@(negedge clk) disable iff(!rst_n) invalid_prediction |-> Miss);

  // // How many invalid predictions issued while flush issued
  // invalid_predictions_at_flush: cover property (@(negedge clk) disable iff(!rst_n) invalid_prediction |-> must_flush);

  
  // /*----------- Flush issue scenarios -----------*/
  // // How many flushes issued
  // flushes: cover property (@(negedge clk) disable iff(!rst_n) must_flush);

  // // How many flushes issued while icache was unblocked
  // flush_at_hit: cover property (@(negedge clk) disable iff(!rst_n) must_flush |-> Hit_cache);

  // // How many flushes issued while icache was blocked
  // flush_at_miss: cover property (@(negedge clk) disable iff(!rst_n) must_flush |-> Miss);


  // /*----------- Function scenarios -----------*/
  // // How many function calls
  // function_call: cover property (@(negedge clk) disable iff(!rst_n) is_jumpl);

  // // How many function returns
  // function_return: cover property (@(negedge clk) disable iff(!rst_n) is_return_in);

  // // Function overflow & underflow is covered in dut/RAS.sv and dut/Predictor.sv
 
  // /*----------- Partial access -----------*/
  // // How many times icache issued partial access of type 1
  // // partial_access_type1: cover property (@(negedge clk) disable iff(!rst_n) partial_access_1_seq);

  // // How many times icache issued partial access of type 2
  // partial_access_type2: cover property (@(negedge clk) disable iff(!rst_n) partial_access_2_seq);

  // // How many times icache issued partial access of type 3
  // // partial_access_type3: cover property (@(negedge clk) disable iff(!rst_n) partial_access_3_seq);


endinterface : IF_if

`endif 

