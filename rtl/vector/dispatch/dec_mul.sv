module dec_mul #(parameter int INSTRUCTION_BITS=32,
                 parameter int NUMBER_VECTOR_LANES=4,
                 parameter int DATA_FROM_SCALAR=96,
                 parameter int VREG_BITS=256,
                 parameter int LANES_DATA_WIDTH=64,
                 parameter int SCALAR_DATA_WIDTH=32,
                 parameter int MICROOP_BIT=9,
                 parameter int ADDR_RANGE=32768
              )( input logic clk,
                 input logic rst,
                 //inputs outputs from fifo
                 input logic [DATA_FROM_SCALAR-1:0] instruction_in,
                 output logic ready_vector,
                 //input from scoreboard
                 input logic valid_instruction,
                 //input from sew_register
                 input logic [2:0] sew_temp,
                 //inputs and outputs to memory
                 output logic [2:0] memory_sew,
                 output logic [2:0] indexed_sew,
                 output logic load_operation_memory,
                 output logic store_operation_memory,
                 output logic [$clog2(ADDR_RANGE)+1:0] stride,
                 output logic [$clog2(ADDR_RANGE)+1:0] addr,
                 output logic [1:0] mode_memory,
                 output logic memory_enable,
                 output logic [4:0] destination_id,
                 //inputs and outputs to vector_lane
                 input logic [LANES_DATA_WIDTH-1:0] mask_register [0:NUMBER_VECTOR_LANES-1],
                 output logic [MICROOP_BIT-1:0] alu_op_out [0:NUMBER_VECTOR_LANES-1],
                 output logic [4:0] operand_1,
                 output logic [4:0] operand_2,
                 output logic [4:0] destination,
                 output logic [(LANES_DATA_WIDTH/8)-1:0] mask_bits [0:NUMBER_VECTOR_LANES-1],
                 output logic masked_operation,
                 output logic load_operation,
                 output logic store_operation,
                 output logic indexed_memory_operation,
                 output logic write_back_enable,
                 output logic [LANES_DATA_WIDTH-1:0] operand_1_immediate_out,
                 output logic [LANES_DATA_WIDTH-1:0] operand_1_scalar_out,
                 output logic multiplication_flag,
                 output logic [2:0] sew_out);

//instruction
logic [INSTRUCTION_BITS-1:0] instruction_temp;
logic [SCALAR_DATA_WIDTH-1:0] scalar_op_1_temp;
logic [SCALAR_DATA_WIDTH-1:0] scalar_op_2_temp;

assign instruction_temp=instruction_in[DATA_FROM_SCALAR-INSTRUCTION_BITS+:INSTRUCTION_BITS];
assign scalar_op_1_temp=instruction_in[0+:SCALAR_DATA_WIDTH];
assign scalar_op_2_temp=instruction_in[SCALAR_DATA_WIDTH+:SCALAR_DATA_WIDTH];
//

logic vadc_op;
logic [MICROOP_BIT-1:0] alu_op_temp [0:NUMBER_VECTOR_LANES-1];
logic [8:0] choice;

logic [LANES_DATA_WIDTH-1:0] scalar_op_1_sign_extended;
logic [LANES_DATA_WIDTH-1:0] scalar_op_2_sign_extended;

logic [LANES_DATA_WIDTH-1:0] operand_1_immediate;
logic [LANES_DATA_WIDTH-1:0] operand_1_scalar;

logic [(LANES_DATA_WIDTH/8)-1:0] mask_bits_temp [0:NUMBER_VECTOR_LANES-1];

logic [VREG_BITS-1:0] vector_mask;
logic multiplication_flag_temp;
logic masked_operation_temp;


//setting vector_mask for lanes
always_comb begin
    for(int f=0;f<NUMBER_VECTOR_LANES;f++) begin
        vector_mask[LANES_DATA_WIDTH*f+:LANES_DATA_WIDTH]=mask_register[f];
    end
end
//

//sign extend scalar operands
generate
   if(LANES_DATA_WIDTH>SCALAR_DATA_WIDTH) begin
      assign scalar_op_1_sign_extended[SCALAR_DATA_WIDTH-1:0]=scalar_op_1_temp;
      assign scalar_op_1_sign_extended[LANES_DATA_WIDTH-1:SCALAR_DATA_WIDTH]={(LANES_DATA_WIDTH-SCALAR_DATA_WIDTH){scalar_op_1_temp[SCALAR_DATA_WIDTH-1]}};
      assign scalar_op_2_sign_extended[SCALAR_DATA_WIDTH-1:0]=scalar_op_2_temp;
      assign scalar_op_2_sign_extended[LANES_DATA_WIDTH-1:SCALAR_DATA_WIDTH]={(LANES_DATA_WIDTH-SCALAR_DATA_WIDTH){scalar_op_2_temp[SCALAR_DATA_WIDTH-1]}};
   end
   else begin
      assign scalar_op_1_sign_extended=scalar_op_1_temp;
      assign scalar_op_2_sign_extended=scalar_op_2_temp;
   end
endgenerate

//set immediate operands for lanes
always_comb begin
   operand_1_immediate=0;
   case(sew_temp)
      3'b000: begin
         for(int i=0;i<LANES_DATA_WIDTH/8;i++) begin
            operand_1_immediate[8*i+:8]={{3{instruction_temp[19]}},instruction_temp[19:15]};
         end
      end
      3'b001: begin
         for(int i=0;i<LANES_DATA_WIDTH/16;i++) begin
            operand_1_immediate[16*i+:16]={{11{instruction_temp[19]}},instruction_temp[19:15]};
         end
      end
      3'b010: begin
         for(int i=0;i<LANES_DATA_WIDTH/32;i++) begin
            operand_1_immediate[32*i+:32]={{27{instruction_temp[19]}},instruction_temp[19:15]};
         end
      end
      3'b011: begin
         for(int i=0;i<LANES_DATA_WIDTH/64;i++) begin
            operand_1_immediate[64*i+:64]={{59{instruction_temp[19]}},instruction_temp[19:15]};
         end
      end
      default: begin
         operand_1_immediate=0;
      end
   endcase
end
//

//scalar value for operation purposes
always_comb begin
   operand_1_scalar=0;
   case(sew_temp)
      3'b000: begin
         for(int i=0;i<LANES_DATA_WIDTH/8;i++) begin
            operand_1_scalar[8*i+:8]=scalar_op_1_sign_extended[7:0];
         end
      end
      3'b001: begin
         for(int i=0;i<LANES_DATA_WIDTH/16;i++) begin
            operand_1_scalar[16*i+:16]=scalar_op_1_sign_extended[15:0];
         end
      end
      3'b010: begin
         for(int i=0;i<LANES_DATA_WIDTH/32;i++) begin
            operand_1_scalar[32*i+:32]=scalar_op_1_sign_extended[31:0];
         end
      end
      3'b011: begin
         for(int i=0;i<LANES_DATA_WIDTH/64;i++) begin
            operand_1_scalar[64*i+:64]=scalar_op_1_sign_extended[63:0];
         end
      end
      default: begin
         operand_1_scalar=0;
      end
   endcase
end
//
//


assign choice={instruction_temp[14:12],instruction_temp[31:26]};

assign vadc_op=(choice==9'b000010000 || choice==9'b100010000 || choice==9'b011010000);


//multiplication flag to indicate execution needs more than one cycle
assign multiplication_flag_temp=(choice==9'b010100101||choice==9'b110100101||choice==9'b010100111||choice==9'b110100111||
                                    choice==9'b010100100||choice==9'b110100100||choice==9'b010100110||choice==9'b110100110||
                                    choice==9'b010101101||choice==9'b110101101||choice==9'b010101001||choice==9'b110101001);
logic float_flag_temp;
assign float_flag_temp = instruction_temp[14:12] == 3'b001 || instruction_temp[14:12] == 3'b101;
//distribute mask bits for operation
generate
   if(LANES_DATA_WIDTH==8) begin
      always_comb begin
         for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
            mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/8)*i+:(LANES_DATA_WIDTH/8)];
         end
      end
   end
   else if(LANES_DATA_WIDTH==16) begin
      always_comb begin
         case(sew_temp)
            3'b000: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/8)*i+:(LANES_DATA_WIDTH/8)];
               end
            end
            default: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/16)*i+:(LANES_DATA_WIDTH/16)];
               end
            end
         endcase
      end
   end
   else if(LANES_DATA_WIDTH==32) begin
      always_comb begin
         case(sew_temp)
            3'b000: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/8)*i+:(LANES_DATA_WIDTH/8)];
               end
            end
            3'b001: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/16)*i+:(LANES_DATA_WIDTH/16)];
               end
            end
            default: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/32)*i+:(LANES_DATA_WIDTH/32)];
               end
            end
         endcase
      end
   end
   else begin
      always_comb begin
         case(sew_temp)
            3'b000: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/8)*i+:(LANES_DATA_WIDTH/8)];
               end
            end
            3'b001: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/16)*i+:(LANES_DATA_WIDTH/16)];
               end
            end
            3'b010: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/32)*i+:(LANES_DATA_WIDTH/32)];
               end
            end
            default: begin
               for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
                  mask_bits_temp[i]=vector_mask[(LANES_DATA_WIDTH/64)*i+:LANES_DATA_WIDTH/64];
               end
            end
         endcase
      end
   end
endgenerate
//

//determining if we have mask operation
assign masked_operation_temp=(!vadc_op && !instruction_temp[25]);

//alu_op_temp
genvar j;
generate
   for(j=0;j<NUMBER_VECTOR_LANES;j++) begin:values
      assign alu_op_temp[j]=(mask_bits_temp[j]==0 && masked_operation_temp && !vadc_op)?{MICROOP_BIT{1'b1}}:choice;
   end
endgenerate
//

//////////////////////////////////////////////////////////////
/////              Setting outputs to memory             /////
/////                                                    /////
//////////////////////////////////////////////////////////////

//the sew encoding our memory instruction operation uses
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      memory_sew<=0;
   else begin
      if(valid_instruction && ready_vector) begin
         case(instruction_temp[14:12])
            3'b101:begin
               memory_sew<=1;
            end
            3'b110:begin
               memory_sew<=2;
            end
            3'b111:begin
               memory_sew<=3;
            end
            default:begin
               memory_sew<=0;
            end
         endcase
      end
   end
end
//

//sew of indexed memory operations
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      indexed_sew<=0;
   else
      indexed_sew<=sew_temp;
end

//address and stride values
always_ff @(posedge clk or posedge rst) begin
   if(rst) begin
      stride<=0;
      addr<=0;
   end
   else begin
      if(valid_instruction && ready_vector) begin
         stride<=scalar_op_2_sign_extended[$clog2(ADDR_RANGE)+1:0];
         addr<=scalar_op_1_sign_extended[$clog2(ADDR_RANGE)+1:0];
      end
   end
end


//mode of memory_unit
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      mode_memory<=0;
   else begin
      if(valid_instruction && ready_vector) begin
         case(instruction_temp[27:26])
            2'b00: begin
               mode_memory<=1;
            end
            2'b10: begin
               mode_memory<=2;
            end
            default: begin
               mode_memory<=3;
            end
         endcase
      end
   end
end
//

//flags of memory operations
always_ff @(posedge clk or posedge rst) begin
   if(rst) begin
      load_operation_memory<=0;
      store_operation_memory<=0;
   end
   else begin
      load_operation_memory<=(instruction_temp[6:0]==7'b0000111 && valid_instruction && ready_vector);
      store_operation_memory<=(instruction_temp[6:0]==7'b0100111 && valid_instruction && ready_vector);
   end
end

//memory enable flag
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      memory_enable<=0;
   else
      memory_enable<=((instruction_temp[6:0]==7'b0000111 || instruction_temp[6:0]==7'b0100111) && valid_instruction && ready_vector);
end

//destination_id
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      destination_id<=0;
   else begin
      if(valid_instruction && ready_vector)
         destination_id<=instruction_temp[11:7];
   end
end

//////////////////////////////////////////////////////////////
/////              Setting outputs to vector             /////
/////                                                    /////
//////////////////////////////////////////////////////////////

//set operands
always_ff @(posedge clk or posedge rst) begin
   if(rst) begin
      operand_1<=0;
      operand_2<=0;
      destination<=0;
      operand_1_immediate_out<=0;
      operand_1_scalar_out<=0;
      sew_out<=0;
   end
   else begin
      if(valid_instruction && ready_vector) begin
         operand_1<=instruction_temp[19:15];
         operand_2<=instruction_temp[24:20];
         destination<=instruction_temp[11:7];
         operand_1_immediate_out<=operand_1_immediate;
         operand_1_scalar_out<=operand_1_scalar;
         sew_out<=sew_temp;
      end
   end
end
//

//masked_operation flag

always_ff @(posedge clk or posedge rst) begin
   if(rst)
      masked_operation<=0;
   else begin
      if(valid_instruction && ready_vector)
         masked_operation<=masked_operation_temp;
   end
end
//

//mask_bits and alu_op_out
always_ff @(posedge clk or posedge rst) begin
   if(rst) begin
      for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
         mask_bits[i]<=0;
         alu_op_out[i]<=0;
      end
   end
   else begin
      if(valid_instruction && ready_vector) begin
         mask_bits<=mask_bits_temp;
         alu_op_out<=alu_op_temp;
      end
   end
end
//

//multiplication flag
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      multiplication_flag<=0;
   else begin
      if(valid_instruction && ready_vector) begin
         multiplication_flag<=multiplication_flag_temp | float_flag_temp;
      end
   end
end
//

//flags of operations
always_ff @(posedge clk or posedge rst) begin
   if(rst) begin
      load_operation<=0;
      store_operation<=0;
      write_back_enable<=0;
   end
   else begin
      load_operation<=(instruction_temp[6:0]==7'b0000111 && valid_instruction && ready_vector);
      store_operation<=(instruction_temp[6:0]==7'b0100111 && valid_instruction && ready_vector);
      write_back_enable<=(instruction_temp[6:0]!=7'b0000111 && instruction_temp[6:0]!=7'b0100111 && valid_instruction && ready_vector);
   end
end

//flag for indexed memory operation for vector lane
always_ff @(posedge clk or posedge rst) begin
   if(rst)
      indexed_memory_operation<=0;
   else begin
      indexed_memory_operation<=(valid_instruction && ready_vector && (instruction_temp[27:26]==2'b01 || instruction_temp[27:26]==2'b11));
   end
end


//////////////////////////////////////////////////////////////
/////                  ready_signal                      /////
/////                                                    /////
//////////////////////////////////////////////////////////////
assign ready_vector=1;

endmodule