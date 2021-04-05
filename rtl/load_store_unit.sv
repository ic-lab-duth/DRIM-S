/*
* @info Load Store Functional Unit (2-stage pipelined)
* @info Sub-Modules: data_cache.sv, data_operation.sv, eb_buff_generic.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief Includes the non-blocking Data Cache, as well as the wrapping logic for the functional unit
*
* @param DATA_WIDTH    : # of Data Bits
* @param ADDR_BITS     : # of Address Bits
* @param R_WIDTH       : # of Register Bits
* @param MICROOP       : # of Microoperation Bits
* @param ROB_TICKET    : # of Register Bits
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module load_store_unit #(
    parameter DATA_WIDTH     = 32        ,
    parameter ADDR_BITS      = 32        ,
    parameter R_WIDTH        = 6         ,
    parameter MICROOP        = 5         ,
    parameter ROB_TICKET     = 3
) (
    input  logic                  clk                  ,
    input  logic                  rst_n                ,
    //Input Interface
    input  logic                  valid                ,
    input  to_execution           input_data           ,
    input  ex_update              cache_fu_update      ,
    //Forward Interface
    output logic [ ADDR_BITS-1:0] frw_address          ,
    output logic [   MICROOP-1:0] frw_microop          ,
    input  logic [DATA_WIDTH-1:0] frw_data             ,
    input  logic                  frw_valid            ,
    input  logic                  frw_stall            ,
    //Input Interface from ROB (commited stores)
    input  logic                  cache_writeback_valid,
    //Output Interface to ROB (for stores)
    output logic                  store_valid          ,
    output logic [ ADDR_BITS-1:0] store_address        ,
    output logic [DATA_WIDTH-1:0] store_data           ,
    output logic [   MICROOP-1:0] store_microop        ,
    output logic [ROB_TICKET-1:0] store_ticket         ,
    //Load to Data Cache
    input  logic                  cache_load_blocked   ,
    output logic                  cache_load_valid     ,
    output logic [ ADDR_BITS-1:0] cache_load_addr      ,
    output logic [   R_WIDTH-1:0] cache_load_dest      ,
    output logic [   MICROOP-1:0] cache_load_microop   ,
    output logic [ROB_TICKET-1:0] cache_load_ticket    ,
    //Output Interface
    output logic                  output_used          ,
    output ex_update              fu_update            ,
    output logic                  busy_fu
);

    // #Internal Signals (first stage)#
    logic [DATA_WIDTH-1 : 0] address, data;
    logic [   MICROOP-1 : 0] microoperation;
    logic                    valid_i, is_store, data_found, misaligned_stall, second_used;
    logic                    ppl_ready_o, ppl_valid_o, ppl_ready_i;

    // #Internal Signals (second stage)#
    ex_update                    internal_fu_update;
    logic     [DATA_WIDTH-1 : 0] data_o, data_ready;
    logic                        valid_o, is_store_o, data_found_o, misaligned_stall_o, load_valid;
    logic     [             3:0] exc  ;
    logic                        exc_v;

    //Calculate the Data Width required for the Internal Pipeline Register
    localparam PPL_WIDTH = $bits(valid_i) + $bits(is_store) + $bits(data_found) + $bits(misaligned_stall)
                            + $bits(address) + $bits(data) + $bits(microoperation) + $bits(cache_load_ticket) + $bits(cache_load_dest);
    logic [PPL_WIDTH-1: 0] pipeline_vector_i, pipeline_vector_o;

    assign microoperation = input_data.microoperation;
    //Create the Busy Signal
    always_comb begin : BusySignals
        if(valid) begin
            if(is_store) begin
                busy_fu = 0;
            end else begin
                busy_fu = 1;
            end
        end else begin
            busy_fu = ~ppl_ready_o;
        end
    end
    //Valid Operation
    assign valid_i = valid & input_data.valid;
    //Operation is store
    assign is_store         = (microoperation==5'b00110) | (microoperation==5'b00111) | (microoperation==5'b01000);
    assign misaligned_stall = ~is_store & frw_stall;
    //Create the Address (rs1+immediate)
    assign address     = input_data.data1 + input_data.immediate;
    assign frw_address = second_used ? cache_load_addr : address;
    assign frw_microop = second_used ? cache_load_microop : microoperation;
    //Grab the Data
    assign data        = is_store ? input_data.data2 : frw_data;
    assign data_found  = frw_valid;
    //Create the Vector for the Pipeline Register
    assign pipeline_vector_i = {valid_i, is_store, data_found, misaligned_stall, address, data, microoperation, input_data.ticket, input_data.destination};


    //Internal Pipeline Register
    eb_buff_generic #(PPL_WIDTH,1,4)
    eb_buff_generic(
        .clk        (clk),
        .rst        (~rst_n),

        .data_i     (pipeline_vector_i),
        .valid_i    (valid_i),
        .ready_o    (ppl_ready_o),

        .data_o     (pipeline_vector_o),
        .valid_o    (ppl_valid_o),
        .ready_i    (ppl_ready_i)
        );
    //Grab the Output Vector of the Internal Pipeline Register
    assign cache_load_dest    = pipeline_vector_o[5:0];
    assign cache_load_ticket  = pipeline_vector_o[8:6];
    assign cache_load_microop = pipeline_vector_o[13:9];
    assign data_o             = pipeline_vector_o[45:14];
    assign cache_load_addr    = pipeline_vector_o[77:46];
    assign misaligned_stall_o = pipeline_vector_o[78];
    assign data_found_o       = pipeline_vector_o[79];
    assign is_store_o         = pipeline_vector_o[80];
    assign valid_o            = pipeline_vector_o[81];

    //Search the ROB on misalignment until no conflicts
    assign second_used = ppl_valid_o & valid_o & misaligned_stall_o;

    //Create the Signals for the STORE Interface (towards ROB)
    assign load_valid    = ppl_valid_o & valid_o & ~is_store_o;
    assign store_valid   = ppl_valid_o & valid_o & is_store_o;
    assign store_address = cache_load_addr;
    assign store_ticket  = cache_load_ticket;
    assign store_data    = data_o;
    assign store_microop = cache_load_microop;
    //Create the ppl_ready_i signal
    always_comb begin : PPLReadyIn
        if(valid_o & is_store_o) begin
            //Pop the STORE
            ppl_ready_i      = 1;
            output_used      = 0;
            cache_load_valid = 0;
        end else begin
            if(data_found_o) begin
                //Pop the forwarded LOAD if no port hazard
                ppl_ready_i      = load_valid & ~cache_writeback_valid & ~cache_load_blocked;
                output_used      = load_valid & ~cache_writeback_valid & ~cache_load_blocked;
                cache_load_valid = 0;
            end else if(!misaligned_stall_o) begin
                //Pop if no port hazard
                ppl_ready_i      = load_valid & ~cache_writeback_valid & ~cache_load_blocked;
                output_used      = 0;
                cache_load_valid = load_valid & ~cache_writeback_valid;
            end else begin
                //Pop a stalled hazard
                ppl_ready_i      = load_valid & ~cache_writeback_valid & ~frw_stall & ~cache_load_blocked;
                output_used      = 0;
                cache_load_valid = load_valid & ~cache_writeback_valid & ~frw_stall;
            end
        end
    end

    //Data operations for the forwarded Loads
    data_operation #(
        .ADDR_W     (ADDR_BITS),
        .DATA_W     (DATA_WIDTH),
        .MICROOP    (MICROOP),
        .BLOCK_W    (DATA_WIDTH),
        .LOAD_ONLY  (1)
        )
    data_operation  (
        .input_address  (),         //NC
        .input_block    (data_o),
        .input_data     (),         //NC
        .microop        (cache_load_microop),

        .valid_exc      (exc_v),
        .exception      (exc),
        .output_block   (),         //NC
        .output_vector  (data_ready)
        );
    //Create the output
    assign internal_fu_update.valid           = output_used;
    assign internal_fu_update.destination     = cache_load_dest;
    assign internal_fu_update.ticket          = cache_load_ticket;
    assign internal_fu_update.data            = data_ready;
    assign internal_fu_update.valid_exception = exc_v;
    assign internal_fu_update.cause           = exc;
    //Pick the correct Output
    always_comb begin : MakeOutput
        if(output_used) begin
            fu_update = internal_fu_update;
        end else begin
            fu_update = cache_fu_update;
        end
    end

endmodule