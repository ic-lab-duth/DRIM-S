module top_mem #(parameter int ADDR_RANGE=32768,
			           parameter int LENGTH_RANGE=32,
			           parameter int BUS_WIDTH=32,
                 parameter int MEMORY_BITS=32,
                 parameter int LANES_DATA_WIDTH=64,
                 parameter int VREG_BITS=256,
                 parameter int NUMBER_VECTOR_LANES=4
               )(input logic clk,
                 input logic rst,
                 input logic [4:0] destination_id,
                 input logic enable_in,
                 input logic load_operation,
                 input logic store_operation,
                 input logic [$clog2(ADDR_RANGE)+1:0] in_stride,
                 input logic [LANES_DATA_WIDTH-1:0] wrdata_in [0:NUMBER_VECTOR_LANES-1],
                 input logic [1:0] mode_in,
				         input logic [2:0] sew_in,
                 input logic [2:0] indexed_sew,
                 input logic [LANES_DATA_WIDTH-1:0] indexed [0:NUMBER_VECTOR_LANES-1],
                 input logic [$clog2(ADDR_RANGE)+1:0] in_addr,
                 output logic [LANES_DATA_WIDTH-1:0] rddata_out [0:NUMBER_VECTOR_LANES-1],
                 output logic [NUMBER_VECTOR_LANES-1:0] valid_read,
                 output logic store_done,
                 output logic [4:0] destination_id_out);

logic [$clog2(ADDR_RANGE)-1:0] stride_in;
logic [$clog2(ADDR_RANGE)-1:0] addr_in;
logic ready;
logic [BUS_WIDTH-1:0] rddata;
logic rddatavalid;
logic [BUS_WIDTH-1:0] wrdata;
logic [$clog2(ADDR_RANGE)-1:0] addr;
logic [$clog2(LENGTH_RANGE):0] length;
logic wr;
logic rd;
logic rddataready;
logic [1:0] mode;
logic [VREG_BITS-1:0] indexed_in;

//set destination_id_out
always_ff @(posedge clk or posedge rst) begin
  if(rst)
    destination_id_out<=0;
  else begin
    if(enable_in)
      destination_id_out<=destination_id;
  end
end
//

//delay_signals for one cycle
logic enable_in_temp;
logic load_operation_temp;
logic store_operation_temp;
logic [2:0] sew_in_temp;
logic [2:0] indexed_sew_temp;
logic [$clog2(ADDR_RANGE)+1:0] in_stride_temp;
logic [$clog2(ADDR_RANGE)+1:0] in_addr_temp;
logic [1:0] mode_in_temp;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    enable_in_temp<=0;
    load_operation_temp<=0;
    store_operation_temp<=0;
    sew_in_temp<=0;
    in_stride_temp<=0;
    in_addr_temp<=0;
    mode_in_temp<=0;
    indexed_sew_temp<=0;
  end
  else begin
    enable_in_temp<=enable_in;
    load_operation_temp<=load_operation;
    store_operation_temp<=store_operation;
    sew_in_temp<=sew_in;
    in_stride_temp<=in_stride;
    in_addr_temp<=in_addr;
    mode_in_temp<=mode_in;
    indexed_sew_temp<=indexed_sew;
  end
end

// setting operation flag and divide address and stride by 4 (4 bytes memory)
assign operation=(load_operation_temp)?0:1;
assign stride_in=(in_stride_temp>>>2);
assign addr_in=(in_addr_temp>>2);

//setting indexed_in
always_comb begin
    for(int f=0;f<NUMBER_VECTOR_LANES;f++) begin
        indexed_in[LANES_DATA_WIDTH*f+:LANES_DATA_WIDTH]=indexed[f];
    end
end

//////////////////////////////////////////////////////////////
/////                    requestor                       /////
/////                                                    /////        
//////////////////////////////////////////////////////////////

requestor #(.ADDR_RANGE(ADDR_RANGE),
            .LENGTH_RANGE(LENGTH_RANGE),
            .BUS_WIDTH(BUS_WIDTH),
            .LANES_DATA_WIDTH(LANES_DATA_WIDTH),
            .VREG_BITS(VREG_BITS),
            .NUMBER_VECTOR_LANES(NUMBER_VECTOR_LANES))
          req(.clk(clk),
              .rst(rst),
              .memory_enable(enable_in_temp),
              .operation(operation),
              .mode_in(mode_in_temp),
              .sew_in(sew_in_temp),
              .indexed_sew(indexed_sew_temp),
              .indexed_in(indexed_in),
              .wrdata_in(wrdata_in),
              .stride_in(stride_in),
              .addr_in(addr_in),
              .ready(ready),
              .rddata(rddata),
              .rddatavalid(rddatavalid),
              .wrdata(wrdata),
              .addr(addr),
              .length(length),
              .mode(mode),
              .wr(wr),
              .rd(rd),
              .rddataready(rddataready),
              .rddata_out(rddata_out),
              .valid_read(valid_read),
              .store_done(store_done));

//////////////////////////////////////////////////////////////
/////                    completer                       /////
/////                                                    /////        
//////////////////////////////////////////////////////////////

completer #(.ADDR_RANGE(ADDR_RANGE),
            .LENGTH_RANGE(LENGTH_RANGE),
            .BUS_WIDTH(BUS_WIDTH),
            .MEMORY_BITS(MEMORY_BITS),
            .LANES_DATA_WIDTH(LANES_DATA_WIDTH),
            .VREG_BITS(VREG_BITS),
            .NUMBER_VECTOR_LANES(NUMBER_VECTOR_LANES))
          comp(.clk(clk),
               .rst(rst),
               .wrdata(wrdata),
               .addr(addr),
               .length(length),
               .mode_in(mode),
               .wr(wr),
               .rd(rd),
               .rddataready(rddataready),
               .ready(ready),
               .rddatavalid(rddatavalid),
               .rddata(rddata));

endmodule