module dispatch #(parameter int INSTRUCTION_BITS=32,
                  parameter int NUMBER_VECTOR_LANES=4,
                  parameter int DATA_FROM_SCALAR=96,
                  parameter int VREG_BITS=256,
                  parameter int LANES_DATA_WIDTH=64,
                  parameter int SCALAR_DATA_WIDTH=32,
                  parameter int MICROOP_BIT=9,
                  parameter int ADDR_RANGE=32768,
                  parameter int REGISTER_NUMBERS=32,
                  parameter int MULTICYCLE_OPERATION_CYCLES=2
                )(input logic clk,
                  input logic rst,
                  //inputs and outputs to fifo
                  input logic [DATA_FROM_SCALAR-1:0] instruction,
                  input logic valid_fifo,
                  output logic ready,
                  //inputs and outputs to memory
                  input logic read_done,
                  input logic store_done,
                  input logic [4:0] destination_id_in,
                  output logic [2:0] memory_sew,
                  output logic [2:0] indexed_sew,
                  output logic load_operation_memory,
                  output logic store_operation_memory,
                  output logic [$clog2(ADDR_RANGE)+1:0] stride,
                  output logic [$clog2(ADDR_RANGE)+1:0] addr,
                  output logic [1:0] mode_memory,
                  output logic memory_enable,
                  output logic [4:0] destination_id,
                  //inputs and outputs to vector_lane
                  input logic operation_done,
                  input logic [4:0] register_to_write,
                  input logic [LANES_DATA_WIDTH-1:0] mask_register [0:NUMBER_VECTOR_LANES-1],
                  output logic [MICROOP_BIT-1:0] alu_op_out [0:NUMBER_VECTOR_LANES-1],
                  output logic [4:0] operand_1,
                  output logic [4:0] operand_2,
                  output logic [4:0] destination,
                  output logic [(LANES_DATA_WIDTH/8)-1:0] mask_bits [0:NUMBER_VECTOR_LANES-1],
                  output logic masked_operation,
                  output logic load_operation,
                  output logic store_operation,
                  output logic indexed_memory_operation,
                  output logic write_back_enable,
                  output logic [LANES_DATA_WIDTH-1:0] operand_1_immediate_out,
                  output logic [LANES_DATA_WIDTH-1:0] operand_1_scalar_out,
                  output logic multiplication_flag,
                  output logic [2:0] sew_out);

//////////////////////////////////////////////////////////////
/////                     dec_mul                        /////
/////                                                    /////        
//////////////////////////////////////////////////////////////

logic [2:0] sew;
logic valid_vector;
logic ready_vector;

dec_mul #(.INSTRUCTION_BITS(INSTRUCTION_BITS),
          .NUMBER_VECTOR_LANES(NUMBER_VECTOR_LANES),
          .VREG_BITS(VREG_BITS),
          .LANES_DATA_WIDTH(LANES_DATA_WIDTH),
          .SCALAR_DATA_WIDTH(SCALAR_DATA_WIDTH),
          .MICROOP_BIT(MICROOP_BIT),
          .ADDR_RANGE(ADDR_RANGE))
 dec_mul (.clk(clk),
          .rst(rst),
          .instruction_in(instruction),
          .ready_vector(ready_vector),
          .valid_instruction(valid_vector),
          .sew_temp(sew),
          .memory_sew(memory_sew),
          .indexed_sew(indexed_sew),
          .load_operation_memory(load_operation_memory),
          .store_operation_memory(store_operation_memory),
          .stride(stride),
          .addr(addr),
          .mode_memory(mode_memory),
          .memory_enable(memory_enable),
          .destination_id(destination_id),
          .mask_register(mask_register),
          .alu_op_out(alu_op_out),
          .operand_1(operand_1),
          .operand_2(operand_2),
          .destination(destination),
          .mask_bits(mask_bits),
          .masked_operation(masked_operation),
          .load_operation(load_operation),
          .store_operation(store_operation),
          .indexed_memory_operation(indexed_memory_operation),
          .write_back_enable(write_back_enable),
          .operand_1_immediate_out(operand_1_immediate_out),
          .operand_1_scalar_out(operand_1_scalar_out),
          .multiplication_flag(multiplication_flag),
          .sew_out(sew_out));


//////////////////////////////////////////////////////////////
/////                    scoreboard                      /////
/////                                                    /////        
//////////////////////////////////////////////////////////////

logic pop_data;

scoreboard #(.INSTRUCTION_BITS(INSTRUCTION_BITS),
             .REGISTER_NUMBERS(REGISTER_NUMBERS),
             .DATA_FROM_SCALAR(DATA_FROM_SCALAR),
             .MULTICYCLE_OPERATION_CYCLES(MULTICYCLE_OPERATION_CYCLES))
        scoreboard_unit(.clk(clk),
                        .rst(rst),
                        .valid_fifo(valid_fifo),
                        .instruction_to_issue(instruction),
                        .operation_done(operation_done),
                        .read_done(read_done),
                        .store_done(store_done),
                        .mem_dest(destination_id_in),
                        .alu_dest(register_to_write),
                        .ready_vector(ready_vector),
                        .valid_vector(valid_vector),
                        .pop_data(pop_data));

assign ready=pop_data & ready_vector;

//////////////////////////////////////////////////////////////
/////                    sew_register                    /////
/////                                                    /////        
//////////////////////////////////////////////////////////////

sew_register #(.DATA_FROM_SCALAR(DATA_FROM_SCALAR),
               .INSTRUCTION_BITS(INSTRUCTION_BITS))
        sew_reg (.clk(clk),
                 .rst(rst),
                 .valid_fifo(valid_fifo),
                 .instruction_in(instruction),
                 .sew(sew));

endmodule