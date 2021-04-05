package tb_util_pkg;
	import dut_parameters_pkg::*;
	parameter bit ENABLE_CHECKERS = 0;
	parameter bit ENABLE_ASSERTIONS = 0;
	parameter int TIME_OUT_CYCLES = 100;    // cycles to wait for IF pc to be stable before consider the test over
	bit[L_REGS-1:0][P_ADDR_WIDTH-1:0] rat_table;
	bit[SCOREBOARD_SIZE-1:0][DATA_WIDTH-1:0] regfile;

endpackage