`ifdef MODEL_TECH
    `include "vstructs.sv"
`endif

module vis #(parameter int LANES_DATA_WIDTH=64,
             parameter int MICROOP_BIT=9
           )(input logic clk,
             input logic rst,
             //inputs and outputs with the module that multiplies instruction
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
             //output to execution
             output to_vector_execution data_in,
             //wait_load_signal and load destination
             output logic wait_load_signal,
             output logic [4:0] load_destination,
             //output to memory interface
             output logic [LANES_DATA_WIDTH-1:0] wrdata,
             output logic [LANES_DATA_WIDTH-1:0] indexed,
             //inputs from multiplexer after writeback
             input logic write_back_enable_wb,
             input logic [LANES_DATA_WIDTH-1:0] data_write,
             input logic [4:0] destination_write,
             input logic read_done,
             input logic [4:0] load_data_destination,
             input logic [LANES_DATA_WIDTH-1:0] data_from_load);

logic store_operation_temp;
logic load_operation_temp;
logic indexed_memory_operation_temp;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    store_operation_temp<=0;
    indexed_memory_operation_temp<=0;
    load_operation_temp<=0;
  end
  else begin
    store_operation_temp<=store_operation;
    indexed_memory_operation_temp<=indexed_memory_operation;
    load_operation_temp<=load_operation;
  end
end

//////////////////////////////////////////////////////////////
/////                  Setting outputs                   /////
/////                                                    /////        
//////////////////////////////////////////////////////////////

//pipeline all the signals

//vector_register_file
vector_register_file #(.VREG_BITS(LANES_DATA_WIDTH))
                   vrf(.clk(clk),
                       .rst(rst),
                       .addr_1(operand_1),
                       .addr_2(operand_2),
                       .addr_3(destination),
                       .write_enable(write_back_enable_wb),
                       .write_enable_from_load(read_done),
                       .data_from_load(data_from_load),
                       .load_data_destination(load_data_destination),
                       .write_data(data_write),
                       .destination(destination_write),
                       .data_1(data_in.operand_1_vector_register_out),
                       .data_2(data_in.operand_2_vector_register_out),
                       .data_3(data_in.operand_3_vector_register_out),
                       .mask_register(vector_mask));
//

//signals that will go to execute
always_ff @(posedge clk or posedge rst)
  if(rst) begin
    data_in.operand_1_immediate_out<=0;
    data_in.operand_1_scalar_out<=0;
    data_in.mask_bits_out<=0;
    data_in.alu_op_out<=0;
    data_in.masked_operation_out<=0;
    data_in.write_back_enable_out<=0;
    data_in.multiplication_flag_out<=0;
    data_in.sew_out<=0;
    data_in.destination_out<=0;
  end
  else begin
    data_in.operand_1_immediate_out<=operand_1_immediate;
    data_in.operand_1_scalar_out<=operand_1_scalar;
    data_in.mask_bits_out<=mask_bits;
    data_in.alu_op_out<=alu_op;
    data_in.masked_operation_out<=masked_operation;
    data_in.write_back_enable_out<=write_back_enable;
    data_in.multiplication_flag_out<=multiplication_flag;
    data_in.sew_out<=sew_in;
    data_in.destination_out<=destination;
  end
//

//signals that will go to memory_interface
assign wrdata=(store_operation_temp)?data_in.operand_3_vector_register_out:0;
assign indexed=(indexed_memory_operation_temp && (store_operation_temp || load_operation_temp))?data_in.operand_2_vector_register_out:0;

//wait_load_signal and load_destination
assign wait_load_signal=load_operation_temp;
assign load_destination=data_in.destination_out;

endmodule