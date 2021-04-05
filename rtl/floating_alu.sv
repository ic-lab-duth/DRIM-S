/*
* @info Floating Alu Functional Unit
* @info Just a placeholder at the moment
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @param INSTR_BITS      : # of Instruction Bits (default==32)
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module floating_alu
	#(parameter INSTR_BITS=32)

	(clk,rst_n,valid,input_data,fu_update,busy_fu);

	input logic clk,rst_n,valid;
	input to_execution input_data;

	output logic busy_fu;
	output ex_update fu_update;	

    assign busy_fu = 1'b1;
    assign fu_update.valid_exception = 1'b0; 
    assign fu_update.cause           = 'b0; 
    assign fu_update.valid           = 1'b0;
	assign fu_update.destination     = 'b0;
	assign fu_update.ticket 		 = 'b0;
	assign fu_update.data            = 'b0;


endmodule