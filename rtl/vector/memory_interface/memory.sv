module vmemory #(parameter int MEMORY_BITS=32,
                parameter int ADDR_RANGE=32768
              )(input logic clk,
                input logic we,
                input logic [MEMORY_BITS-1:0] data_in,
                input logic [$clog2(ADDR_RANGE)-1:0] address,
                output logic [MEMORY_BITS-1:0] rddata);

logic [MEMORY_BITS-1:0] memory [0:ADDR_RANGE-1];

always_ff @(posedge clk) begin
    if(we)
        memory[address]<=data_in;
end

always_ff @(posedge clk) begin
    rddata<=memory[address];
end


endmodule