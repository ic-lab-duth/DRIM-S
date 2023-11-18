module multiplexer_to_register #(parameter int LANES_DATA_WIDTH=64,
                                 parameter int NUMBER_VECTOR_LANES=4)
                                (input logic [2:0] sew [0:NUMBER_VECTOR_LANES-1],
                                 input logic [4:0] destination [0:NUMBER_VECTOR_LANES-1],
                                 input logic [LANES_DATA_WIDTH-1:0] data_write [0:NUMBER_VECTOR_LANES-1],
                                 input logic [NUMBER_VECTOR_LANES-1:0] mask_operation,
                                 input logic [NUMBER_VECTOR_LANES-1:0] write_enable,
                                 input logic [4:0] load_data_destination_in [0:NUMBER_VECTOR_LANES-1],
                                 input logic [LANES_DATA_WIDTH-1:0] data_from_load_in [0:NUMBER_VECTOR_LANES-1],
                                 input logic [NUMBER_VECTOR_LANES-1:0] read_done_in,
                                 input logic [LANES_DATA_WIDTH-1:0] operand_3 [0:NUMBER_VECTOR_LANES-1],
                                 output logic [4:0] destination_out [0:NUMBER_VECTOR_LANES-1],
                                 output logic [LANES_DATA_WIDTH-1:0] data_write_out [0:NUMBER_VECTOR_LANES-1],
                                 output logic [NUMBER_VECTOR_LANES-1:0] write_enable_out,
                                 output logic [4:0] load_destination_out [0:NUMBER_VECTOR_LANES-1],
                                 output logic [LANES_DATA_WIDTH-1:0] data_from_load_out [0:NUMBER_VECTOR_LANES-1],
                                 output logic [NUMBER_VECTOR_LANES-1:0] read_done_out);

logic [NUMBER_VECTOR_LANES*LANES_DATA_WIDTH-1:0] temp;
logic [NUMBER_VECTOR_LANES*LANES_DATA_WIDTH-1:0] operand_3_temp;
logic [NUMBER_VECTOR_LANES*LANES_DATA_WIDTH-1:0] temp_out;
logic masked;
logic [3:0] choice;

assign masked=(mask_operation!=0);
assign choice={masked,sew[0]};

//set values
always_comb begin
    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
        temp[LANES_DATA_WIDTH*i+:LANES_DATA_WIDTH]=data_write[i];
        operand_3_temp[LANES_DATA_WIDTH*i+:LANES_DATA_WIDTH]=operand_3[i];
    end
end

//group output
generate
    if(LANES_DATA_WIDTH==8) begin
        always_comb begin
            temp_out=operand_3_temp;
            if(choice==4'b1000) begin
                for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                    temp_out[(LANES_DATA_WIDTH/8)*i+:(LANES_DATA_WIDTH/8)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/8)]:0;
                end 
            end
            else
                temp_out=temp;
        end
    end
    else if(LANES_DATA_WIDTH==16) begin
        always_comb begin
            temp_out=operand_3_temp;
            case(choice)
                4'b1000: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/8)*i+:(LANES_DATA_WIDTH/8)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/8)]:0;
                    end        
                end
                4'b1001: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/16)*i+:(LANES_DATA_WIDTH/16)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/16)]:0;
                    end        
                end
                default:temp_out=temp; 
            endcase  
        end    
    end
    else if(LANES_DATA_WIDTH==32) begin
        always_comb begin
            temp_out=operand_3_temp;
            case(choice)
                4'b1000: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/8)*i+:(LANES_DATA_WIDTH/8)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/8)]:0;
                    end        
                end
                4'b1001: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/16)*i+:(LANES_DATA_WIDTH/16)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/16)]:0;
                    end        
                end
                4'b1010: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/32)*i+:(LANES_DATA_WIDTH/32)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/32)]:0;
                    end        
                end
                default:temp_out=temp;
            endcase
        end
    end
    else begin
        always_comb begin
            temp_out=operand_3_temp;
            case(choice)
                4'b1000: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/8)*i+:(LANES_DATA_WIDTH/8)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/8)]:0;
                    end        
                end
                4'b1001: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/16)*i+:(LANES_DATA_WIDTH/16)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/16)]:0;
                    end        
                end
                4'b1010: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/32)*i+:(LANES_DATA_WIDTH/32)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/32)]:0;
                    end        
                end
                4'b1011: begin
                    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                        temp_out[(LANES_DATA_WIDTH/64)*i+:(LANES_DATA_WIDTH/64)]=(mask_operation[i])?temp[LANES_DATA_WIDTH*i+:(LANES_DATA_WIDTH/64)]:0;
                    end        
                end
                default:temp_out=temp;
            endcase
        end
    end
endgenerate
//

//////////////////////////////////////////////////////////////
/////                     outputs                        /////
/////                                                    /////
//////////////////////////////////////////////////////////////

always_comb begin
    for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
        data_write_out[i]=temp_out[LANES_DATA_WIDTH*i+:LANES_DATA_WIDTH];
    end
end
assign write_enable_out=write_enable;
assign destination_out=destination;


assign read_done_out=read_done_in;
assign load_destination_out=load_data_destination_in;
assign data_from_load_out=data_from_load_in;

endmodule