`ifdef MODEL_TECH
    `include "vstructs.sv"
`endif

module writeback #(parameter int DATA_WIDTH=64
                  )(input logic clk,
                    input logic rst,
                    //wait_for_load
                    input logic wait_for_load,
                    input logic [4:0] load_destination,
                    //memory inputs
                    input logic valid_read,
                    input logic [DATA_WIDTH-1:0] data_from_load,
                    //execution inputs
                    input to_writeback data_in,
                    //signals that are going to the multiplexer and after to register
                    output logic [DATA_WIDTH-1:0] operand_3,
                    output logic [DATA_WIDTH-1:0] data_write,
                    output logic [4:0] data_destination,
                    output logic [2:0] sew_out,
                    output logic masked_write_back_out,
                    output logic write_enable,
                    output logic read_done,
                    output logic [4:0] load_data_destination,
                    output logic [DATA_WIDTH-1:0] data_from_load_out);

logic wait_for_load_temp;
logic [4:0] load_destination_temp;

//set wait_for_load_temp and load_destination_temp
always_ff @(posedge clk or posedge rst) begin
    if(rst)
        wait_for_load_temp<=0;
    else begin
        if(wait_for_load_temp==0)
            wait_for_load_temp<=wait_for_load;
        if(read_done)
            wait_for_load_temp<=0;
    end
end

always_ff @(posedge clk or posedge rst) begin
    if(rst)
        load_destination_temp<=0;
    else begin
        if(wait_for_load_temp==0)
            load_destination_temp<=load_destination;
    end
end
//

//save previous state
logic [DATA_WIDTH-1:0] data_write_temp;
logic [4:0] data_destination_temp;
logic masked_write_back_temp;

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        data_write_temp<=0;
        data_destination_temp<=0;
        masked_write_back_temp<=0;
    end
    else begin
        data_write_temp<=data_write;
        data_destination_temp<=data_destination;
        masked_write_back_temp<=masked_write_back_out;
    end
end


//////////////////////////////////////////////////////////////
/////                  Setting outputs                   /////
/////                                                    /////
//////////////////////////////////////////////////////////////

assign sew_out=data_in.sew_out;

always_comb begin
    if(data_in.write_back_enable_out) begin
        data_write=data_in.result_out;
        data_destination=data_in.destination_out;
        masked_write_back_out=data_in.masked_write_back_out;
        write_enable=1;
    end
    else begin
        data_write=data_write_temp;
        data_destination=data_destination_temp;
        masked_write_back_out=masked_write_back_temp;
        write_enable=0;
    end
end

assign data_from_load_out=data_from_load;
assign operand_3=data_in.operand_3;
assign load_data_destination=load_destination_temp;
assign read_done=(wait_for_load_temp & valid_read);

endmodule