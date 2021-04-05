/*
* @info Execution Stage
* @info Sub Modules: load_store_unit.sv, floating_alu.sv, int_alu.sv, branch_resolver.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief The fourth stage of the processor. Contains the Functional Units' Initialization and the Data Routing.
*
* @note  Check structs_ex.sv for the structs used.3
* @note:
* Functional Units:
* 00 : Load/Store Unit
* 01 : Floating Point Unit
* 10 : Integer Unit
* 11 : Branches
*
* @param INSTR_BITS     : # of Instruction's Bits
* @param ADDR_BITS      : # of Address Bits
* @param DATA_WIDTH     : # of Data Bits
* @param FU_NUMBER      : # of functional units
* @param R_ADDR         : # of Register's Bits
* @param MICROOP_WIDTH  : # of Microoperation Bits
* @param BLOCK_WIDTH    : # of Data Cache Block's Bits
* @param ROB_INDEX_BITS : # of ROB's ticket Bits
* @param CSR_DEPTH      : # CSR registers
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module execution #(
    parameter INSTR_BITS     = 32,
    parameter ADDR_BITS      = 32,
    parameter DATA_WIDTH     = 32,
    parameter FU_NUMBER      = 4 ,
    parameter R_ADDR         = 6 ,
    parameter MICROOP_WIDTH  = 5 ,
    parameter ROB_INDEX_BITS = 3 ,
    parameter CSR_DEPTH      = 64
) (
    input  logic                             clk                  ,
    input  logic                             rst_n                ,
    input  to_execution [               1:0] t_execution          ,
    input  ex_update                         cache_fu_update      ,
    input  logic                             cache_load_blocked   ,
    //Forward Interface
    output logic        [     ADDR_BITS-1:0] frw_address          ,
    output logic        [ MICROOP_WIDTH-1:0] frw_microop          ,
    input  logic        [    DATA_WIDTH-1:0] frw_data             ,
    input  logic                             frw_valid            ,
    input  logic                             frw_stall            ,
    //Input Interface from ROB (commited stores)
    input  logic                             cache_writeback_valid,
    //Output Interface to ROB (for stores)
    output logic                             store_valid          ,
    output logic        [     ADDR_BITS-1:0] store_address        ,
    output logic        [    DATA_WIDTH-1:0] store_data           ,
    output logic        [ MICROOP_WIDTH-1:0] store_microop        ,
    output logic        [ROB_INDEX_BITS-1:0] store_ticket         ,
    //Output Interface to DCache (for loads)
    output logic                             cache_load_valid     ,
    output logic        [     ADDR_BITS-1:0] cache_load_addr      ,
    output logic        [        R_ADDR-1:0] cache_load_dest      ,
    output logic        [ MICROOP_WIDTH-1:0] cache_load_microop   ,
    output logic        [ROB_INDEX_BITS-1:0] cache_load_ticket    ,
    //Outputs
    output logic                             output_used          ,
    output logic        [     FU_NUMBER-1:0] busy_fu              ,
    output ex_update    [     FU_NUMBER-1:0] fu_update            ,
    output predictor_update                  pr_update            ,
    //Committed Instrs
    input  writeback_toARF                   commit_1             ,
    input  writeback_toARF                   commit_2
);
	// #Internal Signals#
    to_execution [FU_NUMBER-1 : 0] input_data;
    logic        [          1 : 0] fu_selector_1, fu_selector_2;
    logic        [FU_NUMBER-1 : 0] valid;

    logic valid_ret, dual_ret;

	logic                         csr_wr_en  ;
	logic [       DATA_WIDTH-1:0] csr_data, csr_wr_data;
	logic [$clog2(CSR_DEPTH)-1:0] csr_address;

    //Initialize the Load/Store Functional Unit with the Data Cache
    load_store_unit #(
        .DATA_WIDTH(DATA_WIDTH    ),
        .ADDR_BITS (ADDR_BITS     ),
        .R_WIDTH   (R_ADDR        ),
        .MICROOP   (MICROOP_WIDTH ),
        .ROB_TICKET(ROB_INDEX_BITS)
    ) load_store_unit (
        .clk                  (clk                  ),
        .rst_n                (rst_n                ),
        //Input Interface
        .valid                (valid[0]             ),
        .input_data           (input_data[0]        ),
        .cache_fu_update      (cache_fu_update      ),
        .cache_load_blocked   (cache_load_blocked   ),
        //Forward Interface
        .frw_address          (frw_address          ),
        .frw_microop          (frw_microop          ),
        .frw_data             (frw_data             ),
        .frw_valid            (frw_valid            ),
        .frw_stall            (frw_stall            ),
        //Input Interface from ROB (commited stores)
        .cache_writeback_valid(cache_writeback_valid),
        //Output Interface to ROB (for stores)
        .store_valid          (store_valid          ),
        .store_address        (store_address        ),
        .store_data           (store_data           ),
        .store_microop        (store_microop        ),
        .store_ticket         (store_ticket         ),
        //Load to Data Cache
        .cache_load_valid     (cache_load_valid     ),
        .cache_load_addr      (cache_load_addr      ),
        .cache_load_dest      (cache_load_dest      ),
        .cache_load_microop   (cache_load_microop   ),
        .cache_load_ticket    (cache_load_ticket    ),
        //Outputs
        .output_used          (output_used          ),
        .fu_update            (fu_update[0]         ),
        .busy_fu              (busy_fu[0]           )
    );

    //Initialize the Floating Functional Unit
    floating_alu #(.INSTR_BITS ())
    floating_alu (clk,rst_n,valid[1],input_data[1],fu_update[1],busy_fu[1]);

    //Initialize the Integer Functional Unit
    int_alu #(INSTR_BITS,DATA_WIDTH,R_ADDR,ROB_INDEX_BITS)
    int_alu (
        .clk       (clk          ),
        .rst_n     (rst_n        ),
        .valid     (valid[2]     ),
        .input_data(input_data[2]),
        .fu_update (fu_update[2] ),
        .busy_fu   (busy_fu[2]   )
    );

    //Initialize the Branch Functional Unit
	branch_resolver #(
		.INSTR_BITS    (INSTR_BITS       ),
		.DATA_WIDTH    (DATA_WIDTH       ),
		.CSR_ADDR_WIDTH($clog2(CSR_DEPTH))
	) branch_resolver (
		.clk        (clk          ),
		.rst_n      (rst_n        ),
		.valid      (valid[3]     ),
		.input_data (input_data[3]),
		.fu_update  (fu_update[3] ),
		.pr_update  (pr_update    ),
		.busy_fu    (busy_fu[3]   ),
		.csr_address(csr_address  ),
		.csr_data   (csr_data     ),
		.csr_wr_en  (csr_wr_en    ),
		.csr_wr_data(csr_wr_data  )
	);

	assign valid_ret = commit_1.valid_commit;
	assign dual_ret  = commit_1.valid_commit && commit_2.valid_commit;
	csr_registers #(
		.DATA_WIDTH  (DATA_WIDTH       ),
		.ADDR_WIDTH  ($clog2(CSR_DEPTH)),
		.CSR_DEPTH   (CSR_DEPTH        ),
		.CYCLE_PERIOD(                 )
	) csr_registers (
		.clk       (clk        ),
		.rst_n     (rst_n      ),

		.read_addr (csr_address),
		.data_out  (csr_data   ),
		.write_en  (csr_wr_en  ),
		.write_addr(csr_address),
		.write_data(csr_wr_data),
		.valid_ret (valid_ret  ),
		.dual_ret  (dual_ret   )
	);
    //Create the Selectors
    assign fu_selector_1 = t_execution[0].functional_unit;
    assign fu_selector_2 = t_execution[1].functional_unit;

    //Route the Data to the Correct FU
    always_comb begin : ReRoute_Data
        for (int i = 0; i < FU_NUMBER; i++) begin
            if(i==fu_selector_1) begin
                input_data[i] = t_execution[0];
            end else begin
                input_data[i] = t_execution[1];
            end
        end
    end

    //Create the Validity Bits for the FUs
    always_comb begin : ValidityBits
        for (int i = 0; i < FU_NUMBER; i++) begin
            if(i==fu_selector_1) begin
                valid[i] = t_execution[0].valid;
            end else if(i==fu_selector_2) begin
                valid[i] = t_execution[1].valid;;
            end else begin
                valid[i] = 0;
            end
        end
    end

endmodule