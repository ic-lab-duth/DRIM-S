`include "macros.sv"

module scoreboard #(parameter int INSTRUCTION_BITS=32,
                    parameter int REGISTER_NUMBERS=32,
                    parameter int DATA_FROM_SCALAR=96,
                    parameter int MULTICYCLE_OPERATION_CYCLES=2)
                   (input logic clk,
                    input logic rst,
                    //inputs and outputs to scalar
                    input logic valid_fifo,
                    input logic [DATA_FROM_SCALAR-1:0] instruction_to_issue,
                    //inputs and outputs with the vector
                    input logic operation_done,
                    input logic read_done,
                    input logic store_done,
                    input logic [$clog2(REGISTER_NUMBERS)-1:0] mem_dest,
                    input logic [$clog2(REGISTER_NUMBERS)-1:0] alu_dest,
                    input logic ready_vector,
                    output logic valid_vector,
                    output logic pop_data);

logic [1:0] register_status [0:REGISTER_NUMBERS];

//array for alu unit
logic alu_state;
//

//array for memory unit
logic [1:0] mem_state;
//

logic mem_avail;
logic alu_avail;

//set flags for the instruction that we will check if it is available to be issued
logic [DATA_FROM_SCALAR-1:0] instruction_temp;
logic lane_operation;
logic imm_or_scal;
logic vmadd_vmacc;
logic indexed;
logic vm;
logic mask_operation;
logic vset;

assign instruction_temp=instruction_to_issue[DATA_FROM_SCALAR-INSTRUCTION_BITS+:INSTRUCTION_BITS];
assign lane_operation=instruction_temp[6:0]==7'b1010111;
assign imm_or_scal=(instruction_temp[14:12]==3'b011 || instruction_temp[14:12]==3'b100 || instruction_temp[14:12]==3'b101 || instruction_temp[14:12]==3'b110);
assign vmadd_vmacc=((instruction_temp[14:12]==3'b010 || instruction_temp[14:12]==3'b110) && (instruction_temp[31:26]==6'b101001 || instruction_temp[31:26]==6'b101101));
assign indexed=(instruction_temp[27:26]==2'b01 || instruction_temp[27:26]==2'b11);
assign vm=(instruction_temp[31:26]==6'b010111 && (instruction_temp[14:12]==3'b000 || instruction_temp[14:12]==3'b011 || instruction_temp[14:12]==3'b100));
assign mask_operation=~instruction_temp[25];
assign vset=(instruction_temp[14:12]==3'b111);
//

//set address of register status where we will check for dependencies
logic [$clog2(REGISTER_NUMBERS)-1:0] op_dest;
logic [$clog2(REGISTER_NUMBERS)-1:0] op_A;
logic [$clog2(REGISTER_NUMBERS)-1:0] op_B;

assign op_dest=instruction_temp[11:7];
assign op_A=(lane_operation && !imm_or_scal && !vset)?instruction_temp[19:15]:REGISTER_NUMBERS;
assign op_B=((lane_operation && !vm && !vset) || (!lane_operation && indexed))?instruction_temp[24:20]:REGISTER_NUMBERS;

logic op1_avail;
logic op2_avail;
logic dest_avail;
logic mask_avail;

assign op1_avail=(register_status[op_A]==`IDLE || (operation_done && op_A==alu_dest) || ((store_done || read_done) && op_A==mem_dest));
assign op2_avail=(register_status[op_B]==`IDLE || (operation_done && op_B==alu_dest) || ((store_done || read_done) && op_B==mem_dest));
assign dest_avail=(register_status[op_dest]==`IDLE || (operation_done && op_dest==alu_dest) || ((store_done || read_done) && op_dest==mem_dest));
assign mask_avail=(register_status[0]==`IDLE);

//check if instruction is ready to be issued
logic valid_vector_temp;

assign valid_vector_temp=((lane_operation && !vmadd_vmacc && !mask_operation && op1_avail && op2_avail && alu_avail && dest_avail && !vset) ||
                          (lane_operation && !vmadd_vmacc && mask_operation && op1_avail && op2_avail && alu_avail && dest_avail && mask_avail && !vset) ||
                          (!lane_operation && indexed && !mask_operation && op2_avail && mem_avail && dest_avail) ||
                          (!lane_operation && indexed && mask_operation && op2_avail && mem_avail && dest_avail && mask_avail) ||
                          (lane_operation && vmadd_vmacc && !mask_operation && op1_avail && op2_avail && alu_avail && dest_avail) ||
                          (lane_operation && vmadd_vmacc && mask_operation && op1_avail && op2_avail && alu_avail && dest_avail & mask_avail) ||
                          (!lane_operation && !indexed && !mask_operation && mem_avail && dest_avail) ||
                          (!lane_operation && !indexed && mask_operation && mem_avail && dest_avail && mask_avail));

//set counter to determine alu_availability
logic [$clog2(MULTICYCLE_OPERATION_CYCLES-2):0] counter;

logic [$clog2(MULTICYCLE_OPERATION_CYCLES-2):0] counter_limit;

assign counter_limit=MULTICYCLE_OPERATION_CYCLES-2;

always_ff @(posedge clk or posedge rst) begin
  if(rst)
    counter<=0;
  else begin
    if(alu_state==`ALU_UNAVAILABLE && counter<counter_limit)
      counter<=counter+1;
    else
      counter<=0;
  end
end
//

//setting alu state
logic [8:0] instruction_opcodes;
logic mul_operation;

assign instruction_opcodes={instruction_temp[14:12],instruction_temp[31:26]};
assign mul_operation=(instruction_opcodes==9'b010100101||instruction_opcodes==9'b110100101||instruction_opcodes==9'b010100111||instruction_opcodes==9'b110100111||
                      instruction_opcodes==9'b010100100||instruction_opcodes==9'b110100100||instruction_opcodes==9'b010100110||instruction_opcodes==9'b110100110||
                      instruction_opcodes==9'b010101101||instruction_opcodes==9'b110101101||instruction_opcodes==9'b010101001||instruction_opcodes==9'b110101001);

logic float_operation;
assign float_operation = instruction_temp[14:12] == 3'b001 || instruction_temp[14:12] == 3'b101;


logic [1:0] alu_state_choice;
logic unavailable_alu;
logic alu_multiply_state;

assign unavailable_alu=(valid_vector && (mul_operation || float_operation) && ready_vector);
assign alu_multiply_state=(alu_state==`ALU_UNAVAILABLE);
assign alu_state_choice={unavailable_alu,alu_multiply_state};

always_ff @(posedge clk or posedge rst) begin
  if(rst)
    alu_state<=`ALU_UNAVAILABLE;
  else begin
    casez(alu_state_choice)
      2'b10:alu_state<=`ALU_UNAVAILABLE;
      2'b?1: begin
        if(counter==counter_limit)
          alu_state<=`ALU_AVAILABLE;
      end
      default:alu_state<=alu_state;
    endcase
  end
end

assign alu_avail=(alu_state==`ALU_AVAILABLE);
//


//setting mem state
logic store_operation;
logic load_operation;

assign store_operation=(instruction_temp[6:0]==7'b0100111);
assign load_operation=(instruction_temp[6:0]==7'b0000111);

logic [2:0] mem_choice;
logic push_vector;
logic memory_finished;

assign memory_finished=(read_done | store_done);
assign push_vector=(valid_vector & ready_vector);
assign mem_choice={push_vector,load_operation,store_operation};

always_ff @(posedge clk or posedge rst) begin
  if(rst)
    mem_state<=`MEM_AVAILABLE;
  else begin
    if(memory_finished) begin
      mem_state<=`MEM_AVAILABLE;
    end
    casez(mem_choice)
        3'b110:mem_state<=`MEM_LOAD;
        3'b101:mem_state<=`MEM_STORE;
        default: begin
          if(!memory_finished)
            mem_state<=mem_state;
        end
    endcase
  end
end

assign mem_avail=(mem_state==`MEM_AVAILABLE || store_done || read_done);
//

//register status

logic [3:0] register_status_choice;

assign register_status_choice={push_vector,load_operation,store_operation,vset};

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        for(int i=0;i<REGISTER_NUMBERS+1;i++) begin
            register_status[i]<=`IDLE;
        end
    end
    else begin
      if(operation_done) begin
          register_status[alu_dest]<=`IDLE;
      end
      if(memory_finished) begin
        register_status[mem_dest]<=`IDLE;
      end
      casez(register_status_choice)
          4'b1000:register_status[op_dest]<=`LANE_OPERATION;
          4'b101?:register_status[op_dest]<=`STORE;
          4'b110?:register_status[op_dest]<=`LOAD;
          default: begin
              if(!operation_done && !memory_finished) begin
                  register_status<=register_status;
              end
          end
      endcase
    end
end

//////////////////////////////////////////////////////////////
/////                  Setting outputs                   /////
/////                                                    /////
//////////////////////////////////////////////////////////////

assign valid_vector=(valid_vector_temp && valid_fifo);
assign pop_data=((valid_vector_temp && valid_fifo) || (lane_operation && vset));

endmodule