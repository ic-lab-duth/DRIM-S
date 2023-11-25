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

    assign busy_fu = 1'b0;
    assign fu_update.valid_exception = 1'b0;
    assign fu_update.cause           = 'b0;

	fma #(.FW(23), .EW(8)) fma (
									.clk	(clk),
									.rm		(input_data.rm),
									.op		(input_data.microoperation[3:0]),
									.opA	(input_data.data1),
									.opB	(input_data.data2),
									.opC	(input_data.data3),
									.result	(fu_update.data)
	);

	delay #(.DATA_WIDTH(11), .DELAY(4)) delay (.clk(clk), .data_i({input_data.valid, input_data.destination, input_data.ticket}), .data_o({fu_update.valid, fu_update.destination, fu_update.ticket}));

endmodule