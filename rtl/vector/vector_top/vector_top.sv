module vector_top #(parameter int LANES_DATA_WIDTH=64,
                    parameter int MICROOP_BIT=9,
                    parameter int INSTRUCTION_BITS=32,
                    parameter int NUMBER_VECTOR_LANES=4,
                    parameter int VREG_BITS=256,
                    parameter int SCALAR_DATA_WIDTH=32,
                    parameter int ADDR_RANGE=32768,
                    parameter int LENGTH_RANGE=32,
			        parameter int BUS_WIDTH=32,
                    parameter int MEMORY_BITS=32,
                    parameter int REGISTER_NUMBERS=32,
                    parameter int DATA_FROM_SCALAR=96,
                    parameter int MULTICYCLE_OPERATION_CYCLES=2)
                   (input logic clk,
                    input logic rst,
                    //inputs from scoreboard
                    input logic valid_fifo,
                    input logic [DATA_FROM_SCALAR-1:0] instruction, 
                    output logic ready);

//setting wires for multiply module
logic [LANES_DATA_WIDTH-1:0] mask_register [0:NUMBER_VECTOR_LANES-1];
logic [2:0] memory_sew;
logic [2:0] indexed_sew;
logic load_operation_memory;
logic store_operation_memory;
logic [$clog2(ADDR_RANGE)+1:0] stride;
logic [$clog2(ADDR_RANGE)+1:0] addr;
logic [1:0] mode_memory;
logic memory_enable;
logic [MICROOP_BIT-1:0] alu_op_out [0:NUMBER_VECTOR_LANES-1];
logic [4:0] operand_1;
logic [4:0] operand_2;
logic [4:0] destination;
logic [(LANES_DATA_WIDTH/8)-1:0] mask_bits [0:NUMBER_VECTOR_LANES-1];
logic masked_operation;
logic load_operation;
logic store_operation;
logic indexed_memory_operation;
logic write_back_enable;
logic [LANES_DATA_WIDTH-1:0] operand_1_immediate_out;
logic [LANES_DATA_WIDTH-1:0] operand_1_scalar_out;
logic multiplication_flag;
logic [2:0] sew_out;
logic operation_done;
logic [4:0] register_to_write;
logic read_done_in_dispatch;
logic [4:0] destination_id;
logic [4:0] destination_id_in;

//////////////////////////////////////////////////////////////
/////                     DISPATCH                       /////
/////                                                    /////
//////////////////////////////////////////////////////////////

dispatch #(.INSTRUCTION_BITS(INSTRUCTION_BITS),
           .NUMBER_VECTOR_LANES(NUMBER_VECTOR_LANES),
           .VREG_BITS(VREG_BITS),
           .LANES_DATA_WIDTH(LANES_DATA_WIDTH),
           .SCALAR_DATA_WIDTH(SCALAR_DATA_WIDTH),
           .MICROOP_BIT(MICROOP_BIT),
           .ADDR_RANGE(ADDR_RANGE),
           .REGISTER_NUMBERS(REGISTER_NUMBERS),
           .MULTICYCLE_OPERATION_CYCLES(MULTICYCLE_OPERATION_CYCLES))
 dispatch_mod (.clk(clk),
               .rst(rst),
               .instruction(instruction),
               .valid_fifo(valid_fifo),
               .ready(ready),
               .read_done(read_done_in_dispatch),
               .store_done(store_done),
               .destination_id_in(destination_id_in),
               .memory_sew(memory_sew),
               .indexed_sew(indexed_sew),
               .load_operation_memory(load_operation_memory),
               .store_operation_memory(store_operation_memory),
               .stride(stride),
               .addr(addr),
               .mode_memory(mode_memory),
               .memory_enable(memory_enable),
               .destination_id(destination_id),
               .operation_done(operation_done),
               .register_to_write(register_to_write),
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

// setting wires for vector_lane
logic [NUMBER_VECTOR_LANES-1:0] valid_read;
logic [LANES_DATA_WIDTH-1:0] data_from_load [0:NUMBER_VECTOR_LANES-1];
logic [LANES_DATA_WIDTH-1:0] wrdata [0:NUMBER_VECTOR_LANES-1];
logic [LANES_DATA_WIDTH-1:0] indexed [0:NUMBER_VECTOR_LANES-1];
logic [LANES_DATA_WIDTH-1:0] data_write [0:NUMBER_VECTOR_LANES-1];
logic [4:0] data_destination [0:NUMBER_VECTOR_LANES-1];
logic [2:0] sew_out_lane [0:NUMBER_VECTOR_LANES-1];
logic [NUMBER_VECTOR_LANES-1:0] masked_write_back_out;
logic [NUMBER_VECTOR_LANES-1:0] write_enable_out;
logic [NUMBER_VECTOR_LANES-1:0] write_back_enable_wb;
logic [LANES_DATA_WIDTH-1:0] data_write_wb [0:NUMBER_VECTOR_LANES-1];
logic [4:0] destination_write [0:NUMBER_VECTOR_LANES-1];
logic [LANES_DATA_WIDTH-1:0] data_from_load_out [0:NUMBER_VECTOR_LANES-1];
logic [NUMBER_VECTOR_LANES-1:0] read_done;
logic [4:0] load_data_destination [0:NUMBER_VECTOR_LANES-1];
logic [LANES_DATA_WIDTH-1:0] data_from_load_in [0:NUMBER_VECTOR_LANES-1];
logic [4:0] load_data_destination_in [0:NUMBER_VECTOR_LANES-1];
logic [LANES_DATA_WIDTH-1:0] operand_3 [0:NUMBER_VECTOR_LANES-1];
logic [NUMBER_VECTOR_LANES-1:0] read_done_in;

genvar i;

//////////////////////////////////////////////////////////////
/////      vector_lane/multiplexer for mask operations   /////
/////                                                    /////
//////////////////////////////////////////////////////////////
generate
    for(i=0;i<NUMBER_VECTOR_LANES;i++)begin: vector_lanes
        vector_lane #(.LANES_DATA_WIDTH(LANES_DATA_WIDTH),
                      .MICROOP_BIT(MICROOP_BIT))
            vec_lane (.clk(clk),
                      .rst(rst),
                      .alu_op(alu_op_out[i]),
                      .operand_1(operand_1),
                      .operand_2(operand_2),
                      .destination(destination),
                      .mask_bits(mask_bits[i]),
                      .masked_operation(masked_operation),
                      .load_operation(load_operation),
                      .store_operation(store_operation),
                      .indexed_memory_operation(indexed_memory_operation),
                      .write_back_enable(write_back_enable),
                      .operand_1_immediate(operand_1_immediate_out),
                      .operand_1_scalar(operand_1_scalar_out),
                      .multiplication_flag(multiplication_flag),
                      .sew_in(sew_out),
                      .vector_mask(mask_register[i]),
                      .valid_read(valid_read[i]),
                      .data_from_load(data_from_load[i]),
                      .wrdata(wrdata[i]),
                      .indexed(indexed[i]),
                      .operand_3(operand_3[i]),
                      .data_write(data_write[i]),
                      .data_destination(data_destination[i]),
                      .sew_out(sew_out_lane[i]),
                      .masked_write_back_out(masked_write_back_out[i]),
                      .write_enable_out(write_enable_out[i]),
                      .read_done(read_done[i]),
                      .data_from_load_out(data_from_load_out[i]),
                      .load_data_destination(load_data_destination[i]),
                      .write_back_enable_wb(write_back_enable_wb[i]),
                      .data_write_wb(data_write_wb[i]),
                      .destination_write(destination_write[i]),
                      .read_done_in(read_done_in[i]),
                      .data_from_load_in(data_from_load_in[i]),
                      .load_data_destination_in(load_data_destination_in[i]));
    end
endgenerate

assign register_to_write=data_destination[0];
assign operation_done=write_enable_out[0];
assign read_done_in_dispatch=read_done[0];

//multiplexer
 multiplexer_to_register #(.LANES_DATA_WIDTH(LANES_DATA_WIDTH),
                           .NUMBER_VECTOR_LANES(NUMBER_VECTOR_LANES))
          multiplexer_mod (.sew(sew_out_lane),
                           .destination(data_destination),
                           .data_write(data_write),
                           .mask_operation(masked_write_back_out),
                           .write_enable(write_enable_out),
                           .load_data_destination_in(load_data_destination),
                           .data_from_load_in(data_from_load_out),
                           .read_done_in(read_done),
                           .operand_3(operand_3),
                           .destination_out(destination_write),
                           .data_write_out(data_write_wb),
                           .write_enable_out(write_back_enable_wb),
                           .load_destination_out(load_data_destination_in),
                           .data_from_load_out(data_from_load_in),
                           .read_done_out(read_done_in));

//////////////////////////////////////////////////////////////
/////                 memory interface                   /////
/////                                                    /////
//////////////////////////////////////////////////////////////

top_mem #(.ADDR_RANGE(ADDR_RANGE),
          .LENGTH_RANGE(LENGTH_RANGE),
          .BUS_WIDTH(BUS_WIDTH),
          .MEMORY_BITS(MEMORY_BITS),
          .LANES_DATA_WIDTH(LANES_DATA_WIDTH),
          .VREG_BITS(VREG_BITS),
          .NUMBER_VECTOR_LANES(NUMBER_VECTOR_LANES))
mem_mod (.clk(clk),
         .rst(rst),
         .destination_id(destination_id),
         .enable_in(memory_enable),
         .load_operation(load_operation_memory),
         .store_operation(store_operation_memory),
         .in_stride(stride),
         .wrdata_in(wrdata),
         .mode_in(mode_memory),
         .sew_in(memory_sew),
         .indexed_sew(indexed_sew),
         .indexed(indexed),
         .in_addr(addr),
         .rddata_out(data_from_load),
         .valid_read(valid_read),
         .store_done(store_done),
         .destination_id_out(destination_id_in));


endmodule