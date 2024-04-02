module requestor #(
    parameter int LENGTH_RANGE          = 32,
    parameter int BUS_WIDTH             = 32,
    parameter int LANES_DATA_WIDTH      = 64,
    parameter int VREG_BITS             = 256,
    parameter int NUMBER_VECTOR_LANES   = 4
)(
    input logic clk,
    input logic rst,
    //inputs from processor
    input logic memory_enable,
    input logic operation,
    input logic [1:0] mode_in,
    input logic [2:0] sew_in,
    input logic [2:0] indexed_sew,
    input logic [VREG_BITS-1:0] indexed_in,
    input logic [LANES_DATA_WIDTH-1:0] wrdata_in [0:NUMBER_VECTOR_LANES-1],
    input logic [31:0] stride_in,
    input logic [31:0] addr_in,
    //outputs to processor
    output logic [LANES_DATA_WIDTH-1:0] rddata_out [0:NUMBER_VECTOR_LANES-1],
    output logic [NUMBER_VECTOR_LANES-1:0] valid_read,
    output logic store_done,

    input   logic mem_ready,
    input   logic mem_valid_o,
    input   logic [255 : 0] mem_data_o,
    output  logic mem_valid_rd,
    output  logic mem_valid_wr,
    output  logic mem_unit,
    output  logic [1:0] mem_sew,
    output  logic [31 : 0] mem_address,
    output  logic [255 : 0] mem_data_wr
);

logic [VREG_BITS-1:0] wrdata_inserted, indexed_value, data_temp;
logic unitstride_load_done;
always_comb begin
	for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
		wrdata_inserted[LANES_DATA_WIDTH*i+:LANES_DATA_WIDTH] = wrdata_in[i];
        if (unitstride_load_done) rddata_out[i] = mem_data_o[LANES_DATA_WIDTH*i+:LANES_DATA_WIDTH];
        else rddata_out[i] = data_temp[LANES_DATA_WIDTH*i+:LANES_DATA_WIDTH];
	end
end

localparam int OFFSET_BITS = $clog2(VREG_BITS/8);
logic [OFFSET_BITS:0] counter;
logic decrease_counter;
always_ff @(posedge clk) begin : counter_logic
    if (rst) counter <= 0;
    else if (memory_enable) counter <= (32 >> sew_in) - 1;
    else if (decrease_counter) counter <= counter - 1;
end

logic waiting, start_waiting;
always_ff @(posedge clk) begin : waiting_logic
    if (rst) waiting <= 1'b0;
    else if (memory_enable) waiting <= 1'b0;
    else if (start_waiting) waiting <= 1'b1;
end

typedef enum logic [2:0] {
    IDLE,
    UREAD,
    UWRITE,
    SREAD,
    SWRITE,
    IREAD,
    IWRITE
} mem_state;
mem_state state;
always_ff @(posedge clk) begin : fsm_logic
    if (rst) state <= IDLE;
    else begin
        case (state)
        IDLE:   if (memory_enable) begin
                    case (mode_in)
                        1: state <= operation ? UWRITE : UREAD;
                        2: state <= operation ? SWRITE : SREAD;
                        3: state <= operation ? IWRITE : IREAD;
                    endcase
                end
        UREAD:  if (mem_valid_o && waiting) state <= IDLE;
        UWRITE: if (mem_ready) state <= IDLE;
        SREAD:  if (counter == 0 && mem_valid_o) state <= IDLE;
        SWRITE: if (counter == 0) state <= IDLE;
        IREAD:  if (counter == 0 && mem_valid_o) state <= IDLE;
        IWRITE: if (counter == 0) state <= IDLE;
        endcase
    end
end
logic [31:0] strided_value;
logic [2:0] sew_temp;
logic [2:0] indexed_sew_temp;
assign mem_sew = sew_temp;
always_ff @(posedge clk) begin : control_save_logic
    if (rst) begin
        sew_temp            <= 0;
        strided_value       <= 0;
        indexed_sew_temp    <= 0;
    end else if (memory_enable) begin
        sew_temp            <= mode_in != 3 ? sew_in : indexed_sew;
        strided_value       <= stride_in;
        indexed_sew_temp    <= sew_in;
    end
end

logic [31:0] addr_temp;
logic update_index, update_stride, update_data;
always_ff @(posedge clk) begin : data_save_logic
    if (rst) begin
        addr_temp           <= 0;
        indexed_value       <= 0;
        data_temp           <= 0;
    end else if (memory_enable) begin
        addr_temp           <= addr_in;
        indexed_value       <= indexed_in;
        data_temp           <= wrdata_inserted;
    end else begin
        if (update_stride) addr_temp <= addr_temp + strided_value;
        if (update_index) case(indexed_sew_temp[1:0])
            2'b00: indexed_value <= {8'b0, indexed_value[VREG_BITS-1:8]};
            2'b01: indexed_value <= {16'b0, indexed_value[VREG_BITS-1:16]};
            2'b10: indexed_value <= {32'b0, indexed_value[VREG_BITS-1:32]};
            2'b11: indexed_value <= {64'b0, indexed_value[VREG_BITS-1:64]};
        endcase
        if (update_data) case(sew_temp[1:0])
            2'b00: data_temp <= {mem_data_o[7:0],   data_temp[VREG_BITS-1:8]};
            2'b01: data_temp <= {mem_data_o[15:0],  data_temp[VREG_BITS-1:16]};
            2'b10: data_temp <= {mem_data_o[31:0],  data_temp[VREG_BITS-1:32]};
            2'b11: data_temp <= {mem_data_o[63:0],  data_temp[VREG_BITS-1:64]};
        endcase
    end
end

logic [31:0] indexed_offset;
always_comb case(sew_temp[1:0])
    2'b00:indexed_offset = (indexed_value[7:0]);
    2'b01:indexed_offset = (indexed_value[15:0]);
    2'b10:indexed_offset = (indexed_value[31:0]);
    2'b11:indexed_offset = (indexed_value[31:0]);
endcase


always_comb begin : output_logic
    valid_read = 0;
    store_done = 0;

    mem_address = 0;
    mem_valid_rd = 0;
    mem_valid_wr = 0;
    mem_unit = 0;
    mem_data_wr = 0;

    update_data = 0;
    update_index = 0;
    update_stride = 0;

    decrease_counter = 0;
    start_waiting = 0;
    unitstride_load_done = 0;

    case (state)
    UREAD: begin
        if (mem_valid_o && waiting) begin
            valid_read = {NUMBER_VECTOR_LANES{1'b1}};
            unitstride_load_done = 1'b1;
        end else if (mem_ready && !waiting) begin
            mem_address = addr_temp;
            mem_valid_rd = 1'b1;
            mem_unit = 1'b1;
            start_waiting = 1'b1;
        end
    end
    UWRITE: begin
        if (mem_ready) begin
            mem_address = addr_temp;
            mem_valid_wr = 1'b1;
            mem_unit = 1'b1;
            mem_data_wr = data_temp;
            store_done = 1'b1;
        end
    end
    SREAD: begin
        if (counter == 0 && mem_valid_o) begin
            valid_read = {NUMBER_VECTOR_LANES{1'b1}};
        end else if (mem_valid_o && waiting) begin
            update_data = 1'b1;
            update_stride = 1'b1;
            mem_address = addr_temp + strided_value;
            mem_valid_rd = 1'b1;
            decrease_counter = 1'b1;
        end else if (mem_ready && !waiting) begin
            mem_address = addr_temp;
            mem_valid_rd = 1'b1;
            start_waiting = 1'b1;
        end
    end
    SWRITE: begin
        if (counter == 0) begin
            store_done = 1'b1;
        end else if (mem_ready) begin
            mem_valid_wr = 1'b1;
            mem_address = addr_temp;
            mem_data_wr = data_temp;
            update_data = 1'b1;
            update_stride = 1'b1;
            decrease_counter = 1'b1;
        end
    end
    IREAD: begin
        if (counter == 0 && mem_valid_o) begin
            valid_read = {NUMBER_VECTOR_LANES{1'b1}};
        end else if (mem_valid_o && waiting) begin
            update_data = 1'b1;
            mem_address = addr_temp + indexed_offset;
            mem_valid_rd = 1'b1;
            update_index = 1'b1;
            decrease_counter = 1'b1;
        end else if (mem_ready && !waiting) begin
            mem_address = addr_temp + indexed_offset;
            mem_valid_rd = 1'b1;
            start_waiting = 1'b1;
            update_index = 1'b1;
        end
    end
    IWRITE: begin
        if (counter == 0) begin
            store_done = 1'b1;
        end else if (mem_ready) begin
            mem_valid_wr = 1'b1;
            mem_address = addr_temp + indexed_offset;
            mem_data_wr = data_temp;
            update_data = 1'b1;
            update_index = 1'b1;
            decrease_counter = 1'b1;
        end
    end
    endcase
end

endmodule