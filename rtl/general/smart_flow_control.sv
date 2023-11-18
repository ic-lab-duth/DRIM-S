module smart_flow_control   #(
                                parameter int INPUT_PORTS   = 1,
                                parameter int OUTPUT_PORTS  = 1,
                                parameter int DATA_WIDTH    = 32,
                                parameter int FIFOS         = 1
                            )(
                                input logic clk,
                                input logic rst,

                                // flush port
                                input logic flush,

                                // input port
                                output  logic [INPUT_PORTS - 1 : 0]                         pop,
                                input   logic [INPUT_PORTS - 1 : 0]                         valid_in,
                                input   logic [FIFOS - 1 : 0][INPUT_PORTS - 1 : 0]          valid_signals,
                                input   logic [INPUT_PORTS - 1 : 0][DATA_WIDTH - 1 : 0]     data_in,

                                // output port
                                output  logic [FIFOS - 1 : 0][OUTPUT_PORTS - 1 : 0]                       push,
                                input   logic [FIFOS - 1 : 0][OUTPUT_PORTS - 1 : 0]                       ready_in,
                                output  logic [FIFOS - 1 : 0][OUTPUT_PORTS - 1 : 0][DATA_WIDTH - 1 : 0]   data_out,

                                // for scoreboard
                                output logic [INPUT_PORTS - 1 : 0] smart_push_ready
                            );

    logic [INPUT_PORTS - 1 : 0] valid_temp;

    logic [FIFOS - 1 : 0][INPUT_PORTS - 1 : 0] smart_pop_valid;

    smart_pop #(.INPUT_PORTS(INPUT_PORTS)) smart_pop (.clk(clk), .rst(rst), .flush(flush), .valid_in(valid_in), .pop(pop), .ready_in(smart_push_ready), .valid_out(valid_temp));

    always_comb begin : create_smart_pop_valid
        for (int i = 0; i < FIFOS; i += 1) begin
            smart_pop_valid[i] = valid_signals[i] & valid_temp;
        end
    end

    logic [FIFOS - 1 : 0][INPUT_PORTS - 1 : 0] ready_temp;

    genvar i;
    generate
        for (i = 0; i < FIFOS; i += 1) begin
            smart_push  #(
                            .INPUT_PORTS    (INPUT_PORTS),
                            .OUTPUT_PORTS   (OUTPUT_PORTS),
                            .DATA_WIDTH     (DATA_WIDTH))
            smart_push  (
                            .ready_out  (ready_temp[i]),
                            .valid_in   (smart_pop_valid[i]),
                            .data_in    (data_in),

                            .push       (push[i]),
                            .ready_in   (ready_in[i]),
                            .data_out   (data_out[i])
                        );
        end
    endgenerate

    always_comb begin : create_smart_push_ready
        smart_push_ready = ready_temp[0];
        for (int i = 1; i < FIFOS; i += 1) begin
            smart_push_ready |= ready_temp[i];
        end
    end

endmodule