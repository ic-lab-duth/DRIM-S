//////////////////////////////////////////////////////////////
/////                      ADDER                         /////
/////                                                    /////
//////////////////////////////////////////////////////////////
module add( input logic [7:0] op_1,
			input logic [7:0] op_2,
			input logic carry_in,
			output logic [7:0] result,
			output logic carry_out);


always_comb begin
	{carry_out,result}=op_1+op_2+carry_in;
end

endmodule

module adder #( parameter int OPERANDS_WIDTH=64
			 )( input logic [2:0] sew,
			 	input logic carry_enable,
				input logic [OPERANDS_WIDTH/8-1:0] carry_in_operand,
				input logic [OPERANDS_WIDTH-1:0] operand_1,
				input logic [OPERANDS_WIDTH-1:0] operand_2,
				output logic [OPERANDS_WIDTH-1:0] result);

logic carry_in;

assign carry_in=carry_in_operand[0];

logic zero_carry;
logic one_carry;

logic [OPERANDS_WIDTH/8-1:0] carry_out;

logic[7:0] result_mul [2*OPERANDS_WIDTH/8-2:0];
logic [2*OPERANDS_WIDTH/8-2:0] carry_mul;
logic [7:0] result_multiplexers [OPERANDS_WIDTH/8-1:0];
logic [OPERANDS_WIDTH/8-1:0] carry_multiplexers;
logic [OPERANDS_WIDTH/8-2:0] choice;
logic [3:0] flag;

genvar i;


add bit_8(.op_1(operand_1[7:0]),
		  .op_2(operand_2[7:0]),
		  .carry_in(carry_in),
		  .result(result_mul[0]),
		  .carry_out(carry_mul[0]));

generate
	for(i=0;i<OPERANDS_WIDTH/8-1;i++) begin: adders
		add adder_1(.op_1(operand_1[(i+1)*8+7:(i+1)*8]),
					.op_2(operand_2[(i+1)*8+7:(i+1)*8]),
					.carry_in(zero_carry),
					.result(result_mul[2*i+1]),
					.carry_out(carry_mul[2*i+1]));

		add adder_2(.op_1(operand_1[(i+1)*8+7:(i+1)*8]),
					.op_2(operand_2[(i+1)*8+7:(i+1)*8]),
					.carry_in(one_carry),
					.result(result_mul[2*i+2]),
					.carry_out(carry_mul[2*i+2]));

	end
endgenerate

assign zero_carry=0;
assign one_carry=1;

assign result_multiplexers[0]=result_mul[0];
assign carry_multiplexers[0]=carry_mul[0];

assign flag={carry_enable,sew};


//cut carry with multiplexer based on sew or pass carry on vmadc or vsub
always_comb begin
	choice=carry_multiplexers[OPERANDS_WIDTH/8-2:0];
	case(flag)
		4'b0001: begin
            for(int i=1;i<OPERANDS_WIDTH/8-1;i=i+2) begin
                choice[i]=0;
            end
		end
		4'b0010: begin
            for(int i=3;i<OPERANDS_WIDTH/8-1;i=i+4) begin
                choice[i]=0;
            end
		end
		4'b0011: begin
            //just in case it is used in lane with data width bigger than 64
            for(int i=7;i<OPERANDS_WIDTH/8-1;i=i+8) begin
                choice[i]=0;
            end
		end
		4'b1000:choice=carry_in_operand[OPERANDS_WIDTH/8-1:1];
		4'b1001: begin
            for(int i=1;i<OPERANDS_WIDTH/8-1;i=i+2) begin
                choice[i]=carry_in_operand[i/2+1];
            end
		end
		4'b1010: begin
            for(int i=3;i<OPERANDS_WIDTH/8-1;i=i+4) begin
                choice[i]=carry_in_operand[i/4+1];
            end
		end
		4'b1011: begin
            //just in case it is used in lane with data width bigger than 64
            for(int i=7;i<OPERANDS_WIDTH/8-1;i=i+8) begin
                choice[i]=carry_in_operand[i/8+1];
            end
		end
		default: begin
            choice=0;
		end
    endcase
end


generate
	for(i=0;i<=OPERANDS_WIDTH/8-2;i++) begin: multiplexers
		assign carry_multiplexers[i+1]=(choice[i])?carry_mul[2*i+2]:carry_mul[2*i+1];
		assign result_multiplexers[i+1]=(choice[i])?result_mul[2*i+2]:result_mul[2*i+1];
	end
endgenerate

generate
	for(i=0;i<OPERANDS_WIDTH/8;i++) begin: results
		assign result[i*8+7:i*8]=result_multiplexers[i];
        assign carry_out[i]=carry_multiplexers[i];
	end
endgenerate

endmodule