package dut_parameters_pkg;
    parameter int ADDR_BITS        = 32;
    parameter int INSTR_BITS       = 32;
    parameter int FETCH_WIDTH      = 64;
    parameter int DATA_WIDTH       = 32;
    parameter int MICROOP_WIDTH    = 5;
    parameter int PR_WIDTH         = 6;
    parameter int ROB_ENTRIES      = 16;
    parameter int RAS_DEPTH        = 8;
    parameter int GSH_HISTORY_BITS = 2;
    parameter int GSH_SIZE         = 128;
    parameter int BTB_SIZE         = 128;
    parameter int DUAL_ISSUE       = 1;
    parameter int MAX_BRANCH_IF    = 16;
    parameter int CSR_DEPTH        = 64;
    parameter int VECTOR_ENABLED   = 0;
    parameter int VECTOR_ELEM      = 4;
    parameter int VECTOR_ACTIVE_EL = 4;
    parameter int PC_BITS          = ADDR_BITS;
    parameter int PACKET_SIZE      = 65; // Fixed, pc+data+taken_branch
    parameter int ROB_INDEX_BITS   = $clog2(ROB_ENTRIES);
    parameter int C_NUM            = MAX_BRANCH_IF;
    parameter int FU_NUMBER        = 4;
    parameter int SCOREBOARD_SIZE  = 64;
    parameter int GSH_COUNTER_NUM  = 4;
    parameter int INSTR_COUNT = 2;
    parameter int PORT_NUM = INSTR_COUNT;
    parameter int P_REGISTERS = 64;
    parameter int L_REGISTERS = 2**PR_WIDTH;
    parameter int P_ADDR_WIDTH = $clog2(P_REGISTERS);
    parameter int L_ADDR_WIDTH = $clog2(32);
    parameter int L_REGS = 2 ** L_ADDR_WIDTH;

endpackage