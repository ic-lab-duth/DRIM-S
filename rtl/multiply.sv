/*
* @info Multiplication Unit
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief A fully pipelines multiplication Unit. A new operation can begin each cycle
*
* @param DATA_SIZE     : # of Data Bits (default 32 bits)
*/
module multiply #(parameter DATA_SIZE=32) (
    input  logic                   clk      ,
    input  logic                   rst_n    ,
    //Input Port
    input  logic                   enable   ,
    input  logic                   sign     ,
    input  logic                   diff_type,
    input  logic [  DATA_SIZE-1:0] data_1   ,
    input  logic [  DATA_SIZE-1:0] data_2   ,
    //Output Port
    output logic                   ready    ,
    output logic [2*DATA_SIZE-1:0] result
);

    logic [DATA_SIZE-1+8:0] part_1, part_2, part_3, part_4;
    logic [2*DATA_SIZE-1:0] extended_1,extended_2,extended_3,extended_4;
    logic [2*DATA_SIZE-1:0] result_i   ;
    logic [  DATA_SIZE-1:0] data_1_i, data_2_i;
    logic [            2:0] saved_ready, saved_sign;
    logic [  DATA_SIZE-1:0] saved_data_1, saved_data_2;

	//Create the ready flag for the correct Data (perhaps not needed?)
	assign ready = saved_ready[2];
	//Create the correct data form to be used
	always_comb begin : data
		data_1_i = (!sign || !data_1[31]) ?  data_1 : ~data_1 + 1'b1;
        data_2_i = (!sign || !data_2[31]) ?  data_2 : ~data_2 + 1'b1;
	end

	always_ff @(posedge clk) begin : Multiplication
        saved_data_1 <= data_1_i;
        saved_data_2 <= data_2_i;
		//Create Partial Products
		part_1 <= saved_data_1 * saved_data_2[7:0];
		part_2 <= saved_data_1 * saved_data_2[15:8];
		part_3 <= saved_data_1 * saved_data_2[23:16];
		part_4 <= saved_data_1 * saved_data_2[31:24];
		//Create the result
		result_i <= extended_1+extended_2+extended_3+extended_4;
	end
    assign extended_1 = {24*{1'b0},part_1};
    assign extended_2 = {16*{1'b0},part_2,8*{1'b0}};
    assign extended_3 = {8*{1'b0},part_3,16*{1'b0}};
    assign extended_4 = {part_4,24*{1'b0}};
    //Create the result
    // assign result_i = extended_1+extended_2+extended_3+extended_4;
	//Create the Output
	assign result   = !saved_sign[2] ? result_i : ~result_i + 1'b1;

	always_ff @(posedge clk) begin : TempStorage
		//Propagate ready bits
        saved_ready[2] <= saved_ready[1];
		saved_ready[1] <= saved_ready[0];
		saved_ready[0] <= enable;
		//Propagate Sign bits
        saved_sign[2]  <= saved_sign[1];
		saved_sign[1]  <= saved_sign[0];
		saved_sign[0]  <= diff_type? data_1[31] : sign && data_1[31]^data_2[31];
	end

endmodule

