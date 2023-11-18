`ifdef MODEL_TECH
    `include "structs.sv"
`endif

module reservation_station   #(
                                parameter int INPUT_PORTS           = 2,
                                parameter int OUTPUT_PORTS          = 2,
                                parameter int SEARCH_PORTS          = 4,
                                parameter int ROB_DEPTH             = 16,
                                parameter int OPERAND_WIDTH         = 32,
                                parameter int DEPTH                 = 4,
                                parameter int EXTRA_DATA_WIDTH      = 4
                            )(
                                input   logic clk,
                                input   logic rst,

                                // push port
                                output  logic [INPUT_PORTS - 1 : 0]                             ready_out,
                                input   logic [INPUT_PORTS - 1 : 0]                             valid_in,
                                input   reservation_entry_t [INPUT_PORTS - 1 : 0]               data_in,
                                input   logic [INPUT_PORTS - 1 : 0][EXTRA_DATA_WIDTH - 1 : 0]   extra_in,

                                // pop port
                                output  logic [OUTPUT_PORTS - 1 : 0]                            valid_out,
                                input   logic [OUTPUT_PORTS - 1 : 0]                            ready_in,
                                output  reservation_entry_t [OUTPUT_PORTS - 1 : 0]              data_out,
                                output  logic [OUTPUT_PORTS - 1 : 0][EXTRA_DATA_WIDTH - 1 : 0]  extra_out,

                                // search port
                                input logic [SEARCH_PORTS - 1 : 0]                              search_valid,
                                input logic [SEARCH_PORTS - 1 : 0][$clog2(ROB_DEPTH) - 1 : 0]   search_tags,
                                input logic [SEARCH_PORTS - 1 : 0][OPERAND_WIDTH - 1 : 0]       search_data,

                                // flush port
                                input logic branch_resolved,
                                input logic flush
                            );

    logic [DEPTH - 1 : 0][EXTRA_DATA_WIDTH - 1  :0] extra;
    reservation_entry_t [DEPTH - 1 : 0]             data;

    logic [DEPTH - 1 : 0] valid;
    logic [DEPTH - 1 : 0] tail;
    logic [DEPTH - 1 : 0] head;
    logic [DEPTH - 1 : 0] count;
    logic [DEPTH - 1 : 0] next_head;
    logic [DEPTH - 1 : 0] next_tail;
    logic [DEPTH - 1 : 0] next_count;
    logic [DEPTH - 1 : 0] flush_head;
    logic [DEPTH - 1 : 0] flush_tail;
    logic [DEPTH - 1 : 0] flush_count;


    always_ff @ (posedge clk, posedge rst) begin : current_counters
        if (rst) begin
            head    <= {{DEPTH - OUTPUT_PORTS{1'b0}}, {OUTPUT_PORTS{1'b1}}};
            tail    <= {{DEPTH - INPUT_PORTS{1'b0}}, {INPUT_PORTS{1'b1}}};
            count   <= 0;
        end else if (flush) begin
            head    <= flush_head;
            tail    <= flush_tail;
            count   <= flush_count;
        end else begin
            head    <= next_head;
            tail    <= next_tail;
            count   <= next_count;
        end
    end

    always_comb begin : next_counters
        next_head   = head;
        next_tail   = tail;
        next_count  = count;
        for (int i = 0; i < INPUT_PORTS; i += 1) begin
            if (valid_in[i]) begin
                next_tail  = {next_tail[DEPTH - 2:0], next_tail[DEPTH - 1]};
                next_count = {next_count[DEPTH - 2:0], 1'b1};
            end
        end
        for (int i = 0; i < OUTPUT_PORTS; i += 1) begin
            if (ready_in[i]) begin
                next_head   = {next_head[DEPTH - 2:0], next_head[DEPTH - 1]};
                next_count  = {1'b0, next_count[DEPTH - 1:1]};
            end
        end
    end

    always_comb begin : flush_counters
        flush_head = next_head;
        flush_tail = next_tail;
        flush_count = next_count;
        for (int i = 0; i < DEPTH; ++i) begin
            for (int j = 0; j < DEPTH; ++j) begin
                if (next_count[i] & |flush_count  & flush_tail[(j + INPUT_PORTS - 1)%DEPTH] & flush_tail[j] & |data[j - 1].branch_if) begin
                    flush_count  = {1'b0, flush_count[DEPTH - 1:1]};
                    flush_tail  = {flush_tail[0], flush_tail[DEPTH - 1:1]};
                end
            end
        end
    end

    always_comb begin : create_data_out
        data_out = 0;
        extra_out = 0;
        for (int i = 0; i < DEPTH; i += 1) begin
            if (head[(i + OUTPUT_PORTS - 1)%DEPTH] & head[i]) begin
                for (int j = 0 ; j < OUTPUT_PORTS; j += 1) begin
                    data_out[j]     = data[(i + j)%DEPTH];
                    extra_out[j]    = extra[(i + j)%DEPTH];
                end
            end
        end
    end

    always_ff @ (posedge clk) begin : final_data
        for (int i = 0; i < DEPTH; i += 1) begin
            data[i].branch_if <= data[i].branch_if >> branch_resolved;
            for (int k = 0; k < SEARCH_PORTS; k += 1) begin
                if (data[i].tagA == search_tags[k] && search_valid[k]) begin
                    data[i].opA         <= search_data[k];
                    data[i].pendingA    <= 0;
                end
                if (data[i].tagB == search_tags[k] && search_valid[k]) begin
                    data[i].opB         <= search_data[k];
                    data[i].pendingB    <= 0;
                end
            end
            if (tail[(i + INPUT_PORTS - 1)%DEPTH] & tail[i]) begin
                for (int j = 0; j < INPUT_PORTS; j += 1) begin
                    if (valid_in[j]) begin
                        data[(i + j)%DEPTH]     <= data_in[j];
                        extra[(i + j)%DEPTH]    <= extra_in[j];
                        for (int k = 0; k < SEARCH_PORTS; k += 1) begin
                            if (data_in[j].tagA == search_tags[k] && search_valid[k]) begin
                                data[(i + j)%DEPTH].opA         <= search_data[k];
                                data[(i + j)%DEPTH].pendingA    <= 0;
                            end
                            if (data_in[j].tagB == search_tags[k] && search_valid[k]) begin
                                data[(i + j)%DEPTH].opB         <= search_data[k];
                                data[(i + j)%DEPTH].pendingB    <= 0;
                            end
                        end
                    end
                end
            end
        end
    end


    // READY AND VALID OUTPUTS
    logic [INPUT_PORTS - 1 : 0] ready_out_trans;
    assign ready_out_trans = ~count[DEPTH - 1:DEPTH - INPUT_PORTS];

    always_comb begin : create_ready_out
        for (int i = 0; i < INPUT_PORTS; i += 1) begin
            ready_out[i] = ready_out_trans[INPUT_PORTS - i - 1];
        end
    end

    assign valid_out = count[OUTPUT_PORTS - 1:0];

endmodule