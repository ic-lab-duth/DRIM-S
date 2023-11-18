module vector_register_file #(parameter int VREG_BITS=64,
                              parameter int NUMBER_OF_REGISTERS=32
                            )(input logic clk, 
                              input logic rst,
                              input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] addr_1,
                              input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] addr_2,
                              input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] addr_3,
                              input logic write_enable,
                              input logic write_enable_from_load,
                              input logic [VREG_BITS-1:0] data_from_load,
                              input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] load_data_destination,
                              input logic [VREG_BITS-1:0] write_data,
                              input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] destination,
                              output logic [VREG_BITS-1:0] data_1,
                              output logic [VREG_BITS-1:0] data_2,
                              output logic [VREG_BITS-1:0] data_3,
                              output logic [VREG_BITS-1:0] mask_register);

logic [VREG_BITS-1:0] vector_register [0:NUMBER_OF_REGISTERS-1];

always_ff @(posedge clk) begin
  if(write_enable)
    vector_register[destination]<=write_data;
  if(write_enable_from_load)
    vector_register[load_data_destination]<=data_from_load;
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    data_1<=0;
    data_2<=0;
    data_3<=0;
  end
  else begin
    data_1<=vector_register[addr_1];
    data_2<=vector_register[addr_2];
    data_3<=vector_register[addr_3];
  end
end

assign mask_register=vector_register[0];

endmodule