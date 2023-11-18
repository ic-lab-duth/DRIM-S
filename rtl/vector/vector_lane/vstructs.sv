parameter int LANES_DATA_WIDTH=64;
parameter int MICROOP_BIT=9;
parameter int ADDR_RANGE=32768;

typedef struct packed{
    logic [LANES_DATA_WIDTH-1:0] operand_1_immediate_out;
    logic [LANES_DATA_WIDTH-1:0] operand_1_scalar_out;
    logic [LANES_DATA_WIDTH-1:0] operand_1_vector_register_out;
    logic [LANES_DATA_WIDTH-1:0] operand_2_vector_register_out;
    logic [LANES_DATA_WIDTH-1:0] operand_3_vector_register_out;
    logic [(LANES_DATA_WIDTH/8)-1:0] mask_bits_out;
    logic [MICROOP_BIT-1:0] alu_op_out;
    logic masked_operation_out;
    logic write_back_enable_out;
    logic multiplication_flag_out;
    logic [2:0] sew_out;
    logic [4:0] destination_out;
} to_vector_execution;

typedef struct packed{
    logic [4:0] destination_out;
    logic [LANES_DATA_WIDTH-1:0] result_out;
    logic [2:0] sew_out;
    logic write_back_enable_out;
    logic masked_write_back_out;
    logic [LANES_DATA_WIDTH-1:0] operand_3;
} to_writeback;