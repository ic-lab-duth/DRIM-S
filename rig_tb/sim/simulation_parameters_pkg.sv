package simulation_parameters_pkg;

	// General knobs
	parameter int NO_OF_INSTRUCTIONS = 500;

	// Instruction type
	parameter int SHIFTS_DIST     = 20;
	parameter int OPERATIONS_DIST = 30;
	parameter int COMPARES_DIST   = 10;
	parameter int LOADS_DIST      = 0;
	parameter int STORES_DIST     = 0;
	parameter int DIV_DIST        = 20;

	// Control type
	parameter int FOR_LOOP_RATE       = 0;
	parameter int NESTED_LOOP_RATE    = 0;
	parameter int FORWARD_BRANCH_RATE = 0;

	// Hazard rate
	parameter int RAW_HAZARD_RATE     = 0;
	parameter int WAR_HAZARD_RATE     = 0;
	parameter int WAW_HAZARD_RATE     = 0;

endpackage