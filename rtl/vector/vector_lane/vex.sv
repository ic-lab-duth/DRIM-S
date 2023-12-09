`ifdef MODEL_TECH
    `include "vstructs.sv"
`endif

module vex #(parameter int DATA_WIDTH=64,
			       parameter int MICROOP_BIT=9)
            (   input logic clk,
                input logic rst,
                input logic wait_load_signal,
                input logic [4:0] load_destination,
                input to_vector_execution data_in,
                output to_writeback data_out,
                output logic wait_load_signal_out,
                output logic [4:0] load_destination_out);

logic [DATA_WIDTH-1:0] result_temp;
logic masked_write_back_temp;

logic [4:0] destination_mid;
logic masked_write_back_mid;
logic [2:0] sew_mid;
logic [3:0]write_back_enable_mid;
logic multiplication_flag_mid;
logic [DATA_WIDTH-1:0] operand_3_mid;

//preventing load and store operations to insert in alu
logic [DATA_WIDTH-1:0] operand_1_immediate_in;
logic [DATA_WIDTH-1:0] operand_1_scalar_in;
logic [DATA_WIDTH-1:0] operand_1_vector_in;
logic [DATA_WIDTH-1:0] operand_2_vector_in;
logic [DATA_WIDTH-1:0] operand_3_vector_in;
logic masked_operation_in;
logic [(DATA_WIDTH/8)-1:0] mask_bits_in;
logic [MICROOP_BIT-1:0] alu_op_in;
logic [2:0] sew_in;

logic [DATA_WIDTH-1:0] operand_1_immediate_temp;
logic [DATA_WIDTH-1:0] operand_1_scalar_temp;
logic [DATA_WIDTH-1:0] operand_1_vector_temp;
logic [DATA_WIDTH-1:0] operand_2_vector_temp;
logic [DATA_WIDTH-1:0] operand_3_vector_temp;
logic masked_operation_temp;
logic [(DATA_WIDTH/8)-1:0] mask_bits_temp;
logic [MICROOP_BIT-1:0] alu_op_temp;
logic [2:0] sew_temp;

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    operand_1_immediate_temp<=0;
    operand_1_scalar_temp<=0;
    operand_1_vector_temp<=0;
    operand_2_vector_temp<=0;
    operand_3_vector_temp<=0;
    masked_operation_temp<=0;
    mask_bits_temp<=0;
    alu_op_temp<=0;
    sew_temp<=0;
  end
  else begin
    operand_1_immediate_temp<=operand_1_immediate_in;
    operand_1_scalar_temp<=operand_1_scalar_in;
    operand_1_vector_temp<=operand_1_vector_in;
    operand_2_vector_temp<=operand_2_vector_in;
    operand_3_vector_temp<=operand_3_vector_in;
    masked_operation_temp<=masked_operation_in;
    mask_bits_temp<=mask_bits_in;
    alu_op_temp<=alu_op_in;
    sew_temp<=sew_in;
  end
end

assign operand_1_immediate_in=(data_in.write_back_enable_out)?data_in.operand_1_immediate_out:operand_1_immediate_temp;
assign operand_1_scalar_in=(data_in.write_back_enable_out)?data_in.operand_1_scalar_out:operand_1_scalar_temp;
assign operand_1_vector_in=(data_in.write_back_enable_out)?data_in.operand_1_vector_register_out:operand_1_vector_temp;
assign operand_2_vector_in=(data_in.write_back_enable_out)?data_in.operand_2_vector_register_out:operand_2_vector_temp;
assign operand_3_vector_in=(data_in.write_back_enable_out)?data_in.operand_3_vector_register_out:operand_3_vector_temp;
assign masked_operation_in=(data_in.write_back_enable_out)?data_in.masked_operation_out:masked_operation_temp;
assign alu_op_in=(data_in.write_back_enable_out)?data_in.alu_op_out:alu_op_temp;
assign mask_bits_in=(data_in.write_back_enable_out)?data_in.mask_bits_out:mask_bits_temp;
assign sew_in=(data_in.write_back_enable_out)?data_in.sew_out:sew_temp;
//



//alu
alu #(.DATA_WIDTH(DATA_WIDTH),
      .EXECUTION_OUTPUT(DATA_WIDTH),
      .MICROOP_BIT(MICROOP_BIT))
  alu(.clk(clk),
      .rst(rst),
      .sew(sew_in),
      .operand_1_immediate(operand_1_immediate_in),
      .operand_1_scalar(operand_1_scalar_in),
      .operand_1_vector(operand_1_vector_in),
      .operand_2_vector(operand_2_vector_in),
      .operand_3_vector(operand_3_vector_in),
      .masked_result(masked_operation_in),
      .mask_bits(mask_bits_in),
      .alu_op(alu_op_in),
      .result(result_temp),
      .masked_write_back(masked_write_back_temp));
//

//one cycle delay for multiplication
always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    destination_mid<=0;
    masked_write_back_mid<=0;
    sew_mid<=0;
    multiplication_flag_mid<=0;
    operand_3_mid<=0;
  end
  else begin
    if(data_in.write_back_enable_out) begin
      destination_mid<=data_in.destination_out;
      masked_write_back_mid<=masked_write_back_temp;
      sew_mid<=data_in.sew_out;
      multiplication_flag_mid<=data_in.multiplication_flag_out;
      operand_3_mid<=data_in.operand_3_vector_register_out;
    end
  end
end

always_ff @(posedge clk or posedge rst) begin
  if(rst)
    write_back_enable_mid<=0;
  else begin
    if(data_in.multiplication_flag_out)
      write_back_enable_mid[0]<=data_in.write_back_enable_out;
    else
      write_back_enable_mid[0]<=0;

    write_back_enable_mid[1] <= write_back_enable_mid[0];
    write_back_enable_mid[2] <= write_back_enable_mid[1];
    write_back_enable_mid[3] <= write_back_enable_mid[2];
  end
end

//



logic [2:0] exec_choice;

assign exec_choice={data_in.write_back_enable_out,data_in.multiplication_flag_out,multiplication_flag_mid};

//////////////////////////////////////////////////////////////
/////                  Setting outputs                   /////
/////                                                    /////
//////////////////////////////////////////////////////////////

//outputs to writeback
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        data_out.destination_out<=0;
        data_out.result_out<=0;
        data_out.masked_write_back_out<=0;
        data_out.sew_out<=0;
        data_out.write_back_enable_out<=0;
        data_out.operand_3<=0;
        wait_load_signal_out<=0;
        load_destination_out<=0;
    end
    else begin
      wait_load_signal_out<=wait_load_signal;
      load_destination_out<=load_destination;
      casez(exec_choice)
        3'b10?: begin
          data_out.destination_out<=data_in.destination_out;
          data_out.result_out<=result_temp;
          data_out.masked_write_back_out<=masked_write_back_temp;
          data_out.sew_out<=data_in.sew_out;
          data_out.write_back_enable_out<=data_in.write_back_enable_out;
          data_out.operand_3<=operand_3_vector_in;
        end
        3'b11?: begin
          data_out.destination_out<=destination_mid;
          data_out.result_out<=result_temp;
          data_out.masked_write_back_out<=masked_write_back_mid;
          data_out.sew_out<=sew_mid;
          data_out.write_back_enable_out<=write_back_enable_mid[3];
          data_out.operand_3<=operand_3_mid;
        end
        3'b0?1: begin
          data_out.destination_out<=destination_mid;
          data_out.result_out<=result_temp;
          data_out.masked_write_back_out<=masked_write_back_mid;
          data_out.sew_out<=sew_mid;
          data_out.write_back_enable_out<=write_back_enable_mid[3];
          data_out.operand_3<=operand_3_mid;
        end
        default: begin
          data_out.destination_out<=data_out.destination_out;
          data_out.result_out<=data_out.result_out;
          data_out.masked_write_back_out<=data_out.masked_write_back_out;
          data_out.sew_out<=data_out.sew_out;
          data_out.operand_3<=data_out.operand_3;
          data_out.write_back_enable_out<=0;
        end
      endcase
    end
end


endmodule