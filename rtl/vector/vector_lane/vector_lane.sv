`ifdef MODEL_TECH
    `include "vstructs.sv"
`endif

module vector_lane #(parameter int LANES_DATA_WIDTH=64,
                     parameter int MICROOP_BIT=9
                   )(input logic clk,
                     input logic rst,
                     //inputs and outputs to module that decodes and multiplies instructions
                     input logic [MICROOP_BIT-1:0] alu_op,
                     input logic [4:0] operand_1,
                     input logic [4:0] operand_2,
                     input logic [4:0] destination,
                     input logic [(LANES_DATA_WIDTH/8)-1:0] mask_bits,
                     input logic masked_operation,
                     input logic load_operation,
                     input logic store_operation,
                     input logic indexed_memory_operation,
                     input logic write_back_enable,
                     input logic [LANES_DATA_WIDTH-1:0] operand_1_immediate,
                     input logic [LANES_DATA_WIDTH-1:0] operand_1_scalar,
                     input logic multiplication_flag,
                     input logic [2:0] sew_in,
                     output logic [LANES_DATA_WIDTH-1:0] vector_mask,
                     //inputs and outputs to memory
                     input logic valid_read,
                     input logic [LANES_DATA_WIDTH-1:0] data_from_load,
                     output logic [LANES_DATA_WIDTH-1:0] wrdata,
                     output logic [LANES_DATA_WIDTH-1:0] indexed,
                     //outputs to multiplexer
                     output logic [LANES_DATA_WIDTH-1:0] operand_3,
                     output logic [LANES_DATA_WIDTH-1:0] data_write,
                     output logic [4:0] data_destination,
                     output logic [2:0] sew_out,
                     output logic masked_write_back_out,
                     output logic write_enable_out,
                     output logic read_done,
                     output logic [LANES_DATA_WIDTH-1:0] data_from_load_out,
                     output logic [4:0] load_data_destination,
                     //inputs from multiplexer
                     input logic write_back_enable_wb,
                     input logic [LANES_DATA_WIDTH-1:0] data_write_wb,
                     input logic [4:0] destination_write,
                     input logic read_done_in,
                     input logic [LANES_DATA_WIDTH-1:0] data_from_load_in,
                     input logic [4:0] load_data_destination_in);

to_vector_execution is_ex;

//////////////////////////////////////////////////////////////
/////                      IS-STAGE                      /////
/////                                                    /////
//////////////////////////////////////////////////////////////

logic wait_load_signal;
logic [4:0] load_destination;

vis #(.LANES_DATA_WIDTH(LANES_DATA_WIDTH),
      .MICROOP_BIT(MICROOP_BIT))
 vis_mod(.clk(clk),
         .rst(rst),
         .alu_op(alu_op),
         .operand_1(operand_1),
         .operand_2(operand_2),
         .destination(destination),
         .mask_bits(mask_bits),
         .masked_operation(masked_operation),
         .load_operation(load_operation),
         .store_operation(store_operation),
         .indexed_memory_operation(indexed_memory_operation),
         .write_back_enable(write_back_enable),
         .operand_1_immediate(operand_1_immediate),
         .operand_1_scalar(operand_1_scalar),
         .multiplication_flag(multiplication_flag),
         .sew_in(sew_in),
         .vector_mask(vector_mask),
         .data_in(is_ex),
         .wait_load_signal(wait_load_signal),
         .load_destination(load_destination),
         .wrdata(wrdata),
         .indexed(indexed),
         .write_back_enable_wb(write_back_enable_wb),
         .data_write(data_write_wb),
         .destination_write(destination_write),
         .read_done(read_done_in),
         .load_data_destination(load_data_destination_in),
         .data_from_load(data_from_load_in));

to_writeback ex_wb;

//////////////////////////////////////////////////////////////
/////                      EX-STAGE                      /////
/////                                                    /////
//////////////////////////////////////////////////////////////

logic [4:0] load_destination_out;
logic wait_load_signal_out;

vex #(.DATA_WIDTH(LANES_DATA_WIDTH),
      .MICROOP_BIT(MICROOP_BIT))
    vex_mod(.clk(clk),
            .rst(rst),
            .wait_load_signal(wait_load_signal),
            .load_destination(load_destination),
            .data_in(is_ex),
            .data_out(ex_wb),
            .wait_load_signal_out(wait_load_signal_out),
            .load_destination_out(load_destination_out));

//////////////////////////////////////////////////////////////
/////                   WRITEBACK_STAGE                  /////
/////                                                    /////
//////////////////////////////////////////////////////////////            

writeback #(.DATA_WIDTH(LANES_DATA_WIDTH))
    wb_mod (.clk(clk),
            .rst(rst),
            .wait_for_load(wait_load_signal_out),
            .load_destination(load_destination_out),
            .valid_read(valid_read),
            .data_from_load(data_from_load),
            .data_in(ex_wb),
            .operand_3(operand_3),
            .data_write(data_write),
            .data_destination(data_destination),
            .sew_out(sew_out),
            .masked_write_back_out(masked_write_back_out),
            .write_enable(write_enable_out),
            .read_done(read_done),
            .load_data_destination(load_data_destination),
            .data_from_load_out(data_from_load_out));

endmodule