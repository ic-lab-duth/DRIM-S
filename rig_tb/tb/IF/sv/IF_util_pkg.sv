package IF_util_pkg;
  import dut_parameters_pkg::*;
  import tb_util_pkg::*;
  // Structs
  parameter int INSTRUCTION_NUM=1;
// Structs
typedef struct packed {
  logic          valid_jump  ;
  logic          jump_taken  ;
  logic          is_comp     ;
  logic [ 1 : 0] rat_id      ;
  logic [31 : 0] orig_pc     ;
  logic [31 : 0] jump_address;
  logic [ 2 : 0] ticket      ;
} predictor_update;

typedef struct packed {
  predictor_update pr_update;
  bit skip_btb;
  bit skip_once;
} predictor_update_extended;

typedef struct packed {
  bit[PC_BITS-1:0]  orig_pc;
  bit[PC_BITS-1:0]  target_pc;
  bit               valid;
} btb_array_entry_s;

typedef struct packed {
  bit[PC_BITS-1:0] target_pc;
  bit hit;
} btb_read_s;

typedef struct packed {
  // Restart
  bit invalid_instruction;
  bit invalid_prediction;
  // Functions
  bit function_call;
  bit [PC_BITS-1:0] function_call_PC;
  bit function_return;
  // Flush
  bit flushed;
  bit valid;
  bit[PC_BITS-1:0] restart_PC, flush_PC;

  bit skip_last_cycle_pr_update;
  bit skip_btb_update;
  bit pr_after_btb_inv;

  bit partial_access;
  bit[1:0] partial_type;
} monitor_DUT_s;


typedef struct packed {
    logic [31 : 0] pc          ;
    logic [31 : 0] data        ;
    logic          taken_branch;
} fetched_packet;


typedef struct packed {
  bit [PC_BITS-1:0] current_pc_gr;
  fetched_packet[INSTR_COUNT-1:0] packet_;
  bit valid_o_gr;
  longint sim_time;
} output_array_s;

typedef struct packed {
  // Restart
  bit invalid_instruction;
  bit invalid_prediction;
  // Functions
  bit function_call;
  bit function_return;
  // Flush
  bit flushed;
  bit[PC_BITS-1:0] restart_PC, flush_PC;
} restart_s;

typedef struct packed {
  int cycle;
  predictor_update pr_update;
  bit pr_valid;
  bit pr_exec;
  restart_s restart;
  bit rst_valid;
  bit rst_exec;
  bit valid_entry;
} event_entry_s;


  monitor_DUT_s [INSTRUCTION_NUM-1:0] trans_properties;
  int trans_pointer_synced;

endpackage