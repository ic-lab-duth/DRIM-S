module alu #(parameter int DATA_WIDTH=64,
			 parameter int EXECUTION_OUTPUT=64,
			 parameter int MICROOP_BIT=9
		   )(input logic clk,
			 input logic rst,
			 //input of alu
			 input logic [2:0] sew,
			 input logic [DATA_WIDTH-1:0] operand_1_immediate,
			 input logic [DATA_WIDTH-1:0] operand_1_scalar,
			 input logic [DATA_WIDTH-1:0] operand_1_vector,
			 input logic [DATA_WIDTH-1:0] operand_2_vector,
			 input logic [DATA_WIDTH-1:0] operand_3_vector,
			 input logic masked_result,
			 input logic [(DATA_WIDTH/8)-1:0] mask_bits,
			 input logic [MICROOP_BIT-1:0] alu_op,
			 //output of alu
			 output logic [EXECUTION_OUTPUT-1:0] result,
		     output logic masked_write_back);


logic [DATA_WIDTH-1:0] operand_1;
logic [DATA_WIDTH-1:0] operand_2;

//multiplication signals
logic [DATA_WIDTH-1:0] operand_1_mul;
logic [DATA_WIDTH-1:0] operand_2_mul;
logic sign;
logic high;
logic diff;
logic [DATA_WIDTH-1:0] temp_mul;
//comparator signals
logic less;
logic greater_flag;
logic equal_flag;
logic not_equal;
logic signed_comp;
logic [DATA_WIDTH-1:0] temp_comp;
//adder signals
logic carry_enable;
logic [(DATA_WIDTH/8)-1:0] carry_in_operand;
logic [DATA_WIDTH-1:0] temp_add;
//and signal
logic [DATA_WIDTH-1:0] temp_and;
//or signal
logic [DATA_WIDTH-1:0] temp_or;
//xor signal
logic [DATA_WIDTH-1:0] temp_xor;
//sll signal
logic [DATA_WIDTH-1:0] temp_shift;
//srl signal
// logic [DATA_WIDTH-1:0] temp_vsrl;
//sra signal
// logic [DATA_WIDTH-1:0] temp_vsra;
logic [DATA_WIDTH-1:0] temp_vfma;
logic [DATA_WIDTH-1:0] temp;

logic [3:0] sew_rev_oh;
assign sew_rev_oh = 4'b1000 >> sew[1:0];

//setting operand_1 for all operations except multiplication
logic immediate;
logic scalar_op;
logic invert_operand_1;
logic vmacc;
logic vmadd;
logic [4:0] operand_1_choice;

assign immediate=(alu_op[MICROOP_BIT-1:MICROOP_BIT-3]==3'b011);
assign scalar_op=(alu_op[MICROOP_BIT-1:MICROOP_BIT-3]==3'b100 || alu_op[MICROOP_BIT-1:MICROOP_BIT-3]==3'b101);
assign invert_operand_1=(alu_op[5:0]==6'b000010);
assign vmacc=(alu_op[5:0]==6'b101101);
assign vmadd=(alu_op[7:0]==8'b10101001);

logic [3:0] f_op;
assign f_op = 	alu_op[5:0] == 6'b000000 ? 4'b0010 :
				alu_op[5:0] == 6'b000010 ? 4'b1010 :
				alu_op[5:0] == 6'b100100 ? 4'b0001 :
				alu_op[5:0] == 6'b101000 ? 4'b0011 :
				alu_op[5:0] == 6'b101001 ? 4'b0111 :
				alu_op[5:0] == 6'b101010 ? 4'b1011 :
				alu_op[5:0] == 6'b101011 ? 4'b1111 : 4'b0000;

assign operand_1_choice={immediate,scalar_op,invert_operand_1,vmacc,vmadd};

always_comb begin
	casez(operand_1_choice)
		5'b10000:operand_1=operand_1_immediate;
		5'b01000:operand_1=operand_1_scalar;
		5'b10100:operand_1=operand_1_immediate;
		5'b01100:operand_1=operand_1_scalar;
		5'b???10:operand_1=operand_3_vector;
		5'b???01:operand_1=operand_2_vector;
		5'b00100:operand_1=operand_1_vector;
		default:operand_1=operand_1_vector;
	endcase
end
//

//setting operand_1 for mul
logic scalar_mul;

assign scalar_mul=(alu_op[MICROOP_BIT-1:MICROOP_BIT-3]==3'b110);

always_comb begin
	if(scalar_mul)
		operand_1_mul=operand_1_scalar;
	else
		operand_1_mul=operand_1_vector;
end
//

//setting operand_2 for all operations except multiplication
logic invert_operand_2;
logic vmacc_vmadd_operand_2;
logic [1:0] operand_2_choice;

assign invert_operand_2=(alu_op[5:0]==6'b000011);
assign vmacc_vmadd_operand_2=(vmacc | vmadd);

assign operand_2_choice={invert_operand_2,vmacc_vmadd_operand_2};

always_comb begin
	case(operand_2_choice)
		2'b10:operand_2=operand_2_vector;
		2'b01:operand_2=temp_mul;
		default:operand_2=operand_2_vector;
	endcase
end
//

//setting operand_2 for mul
always_comb begin
	if(vmadd)
		operand_2_mul=operand_3_vector;
	else
		operand_2_mul=operand_2_vector;
end
//

//setting multiplication flags
logic sign_high;
logic unsigned_high;
logic high_su;
logic [2:0] mul_flags_choice;

assign sign_high=(alu_op[5:0]==6'b100111);
assign unsigned_high=(alu_op[5:0]==6'b100100);
assign high_su=(alu_op[5:0]==6'b100110);

assign high=(sign_high | unsigned_high | high_su);
assign sign=(sign_high | high_su | ((~sign_high) & (~unsigned_high) & (~high_su)));
assign diff=high_su;

//

//setting addition flags
logic adc;
logic addition;
logic [1:0] addition_flags;

assign adc=(alu_op[5:0]==6'b010000);
assign addition=(alu_op[5:0]==6'b000000 | vmacc | vmadd);

assign carry_enable=(adc | (~addition));

assign addition_flags={adc,addition};

always_comb begin
	case(addition_flags)
		2'b10:begin
			carry_in_operand=mask_bits;
		end
		2'b01:begin
			carry_in_operand=0;
		end
		default: begin
			carry_in_operand={(DATA_WIDTH/8){1'b1}};
		end
	endcase
end
//

//setting comparator flags

assign less=(alu_op[5:0]==6'b011011 | alu_op[5:0]==6'b011010 | alu_op[5:0]==6'b011101 | alu_op[5:0]==6'b011100);
assign greater_flag=(alu_op[5:0]==6'b011111 | alu_op[5:0]==6'b011110);
assign equal_flag=(alu_op[5:0]==6'b011000 | alu_op[5:0]==6'b011101 | alu_op[5:0]==6'b011100 | alu_op[5:0]==6'b011001);
assign not_equal=(alu_op[5:0]==6'b011001);
assign signed_comp=(alu_op[5:0]==6'b011011 | alu_op[5:0]==6'b011101 | alu_op[5:0]==6'b011111);

//
genvar gv;
generate
	for (gv = 0; gv < DATA_WIDTH/32; ++gv) begin
		fma #(.FW(23), .EW(8)) fma (
									.clk	(clk),
									.rm		(3'b0),
									.op		(f_op),
									.opA	(operand_1[gv*32 +: 32]),
									.opB	(operand_2[gv*32 +: 32]),
									.opC	(operand_3_vector[gv*32 +: 32]),
									.result	(temp_vfma[gv*32 +: 32])
	);
	end
endgenerate

simd_adder #(
	.MIN_WIDTH(8),
	.MAX_WIDTH(DATA_WIDTH))
adder (
	.sub	(~addition),
	.rev	(alu_op[5:0]==6'b000011),
	.carry	(adc),
	.sew	(sew_rev_oh),
	.mask	(mask_bits),
	.opA	(operand_2),
	.opB	(operand_1),
	.result	(temp_add)
);

// adder #(.OPERANDS_WIDTH(DATA_WIDTH))
// 	  add(.sew(sew),
// 		  .carry_enable(carry_enable),
// 		  .carry_in_operand(carry_in_operand),
// 		  .operand_1(operand_1),
// 		  .operand_2(operand_2),
// 		  .result(temp_add));

simd_multiplier #(
	.MIN_WIDTH(8),
	.MAX_WIDTH(DATA_WIDTH))
mul(
	.clk	(clk),
	.high	(high),
	.signA	(sign),
	.signB	(diff | sign),
	.sew	(sew_rev_oh),
	.opA	(operand_1_mul),
	.opB	(operand_2_mul),
	.result	(temp_mul)
);

comperator #(.DATA_WIDTH(DATA_WIDTH))
			 comp(.operand_1(operand_1),
			   	  .operand_2(operand_2),
				  .sew(sew),
				  .sign(signed_comp),
				  .greater(greater_flag),
				  .smaller(less),
				  .equal(equal_flag),
				  .invert(not_equal),
				  .result(temp_comp));

vand #(.DATA_WIDTH(DATA_WIDTH))
	and_mod(.operand_1(operand_1),
			.operand_2(operand_2),
			.result(temp_and));

vor #(.DATA_WIDTH(DATA_WIDTH))
	or_mod(.operand_1(operand_1),
		   .operand_2(operand_2),
		   .result(temp_or));

vxor #(.DATA_WIDTH(DATA_WIDTH))
	xor_mod(.operand_1(operand_1),
		    .operand_2(operand_2),
		    .result(temp_xor));

// vsll #(.DATA_WIDTH(DATA_WIDTH))
// 	vsll_mod(.operand_1(operand_1),
// 		     .operand_2(operand_2),
// 			 .sew(sew),
// 		     .result(temp_vsll));

// vsrl #(.DATA_WIDTH(DATA_WIDTH))
// 	vsrl_mod(.operand_1(operand_1),
// 		     .operand_2(operand_2),
// 			 .sew(sew),
// 		     .result(temp_vsrl));

// vsra #(.DATA_WIDTH(DATA_WIDTH))
// 	vsra_mod(.operand_1(operand_1),
// 		     .operand_2(operand_2),
// 			 .sew(sew),
// 		     .result(temp_vsra));

simd_shifter #(
	.MIN_WIDTH(8),
	.MAX_WIDTH(DATA_WIDTH))
shift(
	.right	(alu_op[5:0]==6'b101000 || alu_op[5:0]==6'b101001),
	.sign	(alu_op[5:0]==6'b101001),
	.sew	(sew_rev_oh),
	.opA	(operand_2),
	.opB	(operand_1),
	.result	(temp_shift)
);

//outputs of alu
always_comb begin
	masked_write_back=0;
	casez(alu_op)
		//vadd(OPIVV,OPIVX,OPIVI)
		9'b000000000: temp=temp_add;
		9'b010000000: temp=temp_add;
		9'b011000000: temp=temp_add;
		9'b100000000: temp=temp_add;
		9'b110000000: temp=temp_add;
		9'b001000000: temp=temp_vfma;
		9'b101000000: temp=temp_vfma;
		//vand(OPIVV,OPIVX,OPIVI)
		9'b???001001:temp=temp_and;
		//vor(OPIVV,OPIVX,OPIVI)
		9'b???001010:temp=temp_or;
		//vxor(OPIVV,OPIVX,OPIVI)
		9'b???001011:temp=temp_xor;
		//vmul(OPMVV,OPMVX)
		9'b?10100101:temp=temp_mul;
		//vmulh(OPMVV,OPMVX)
		9'b???100111:temp=temp_mul;
		//vmulhu(OPMVV,OPMVX)
		9'b000100100:temp=temp_mul;
		9'b010100100:temp=temp_mul;
		9'b011100100:temp=temp_mul;
		9'b100100100:temp=temp_mul;
		9'b110100100:temp=temp_mul;
		9'b001100100:temp=temp_vfma;
		9'b101100100:temp=temp_vfma;

		9'b001101010:temp=temp_vfma;
		9'b101101010:temp=temp_vfma;

		9'b001101011:temp=temp_vfma;
		9'b101101011:temp=temp_vfma;
		//vmulhsu(OPMVV)
		9'b???100110:temp=temp_mul;
		//vmacc(OPMVV,OPMVX)
		9'b???101101:temp=temp_add;
		//vsll(OPIVV,OPIVX)
		9'b?00100101:temp=temp_shift;
		//vsll(OPIVI)
		9'b011100101:temp=temp_shift;
		//vsrl(OPIVV,OPIVX,OPIVI)
		9'b000101000:temp=temp_shift;
		9'b010101000:temp=temp_shift;
		9'b011101000:temp=temp_shift;
		9'b100101000:temp=temp_shift;
		9'b110101000:temp=temp_shift;
		9'b001101000:temp=temp_vfma;
		9'b101101000:temp=temp_vfma;
		//vsra(OPIVV,OPIVX)
		9'b?00101001:temp=temp_shift;
		//vsra(OPIVI)
		9'b011101001:temp=temp_shift;
		9'b001101001:temp=temp_vfma;
		9'b101101001:temp=temp_vfma;
		//vmseq(OPIVV,OPIVX,OPIVI)
		9'b???011000: begin
			temp=temp_comp;
			masked_write_back=1;
		end
		//vmsne(OPIVV,OPIVX,OPIVI)
		9'b???011001: begin
			temp=temp_comp;
			masked_write_back=1;
		end
		//vmslt(OPIVV,OPIVX)
		9'b???011011: begin
			temp=temp_comp;
			masked_write_back=1;
		end
		//vmsltu(OPIVV,OPIVX)
		9'b???011010: begin
			temp=temp_comp;
			masked_write_back=1;
		end
		//vmsle(OPIVV,OPIVX,OPIVI)
		9'b???011101: begin
			temp=temp_comp;
			masked_write_back=1;
		end
		//vmsleu(OPIVV,OPIVX,OPIVI)
		9'b???011100: begin
			temp=temp_comp;
			masked_write_back=1;
		end
		//vadc(OPIVV,OPIVI)
		9'b???010000:temp=temp_add;
		//vsub(OPIVV,OPIVX,OPIVI)
		9'b000000010:temp=temp_add;
		9'b010000010:temp=temp_add;
		9'b011000010:temp=temp_add;
		9'b100000010:temp=temp_add;
		9'b110000010:temp=temp_add;
		9'b001000010:temp=temp_vfma;
		9'b101000010:temp=temp_vfma;
		//vmsgt (OPIVX,OPIVI)
		9'b???011111: begin
			temp=temp_comp;
			masked_write_back=1;
		end
		//vmsgtu (OPIVX,OPIVI)
		9'b???011110: begin
			temp=temp_comp;
			masked_write_back=1;
		end
		//vmv(OPIVV,OPIVX,OPIVI)
		9'b???010111:temp=operand_1;
		//vmadd(OPMVV,OPMVX)
		9'b?10101001:temp=temp_add;
		//vrsub(OPIVX,OPIVI)
		9'b???000011:temp=temp_add;
		default:temp=operand_3_vector;
    endcase

end

// result
logic [4:0] result_choice;

assign result_choice={masked_result,sew,masked_write_back};

//mask elements if we have masked operation
always_comb begin
	result=0;
	case(result_choice)
		5'b10000: begin
			for(int i=0;i<DATA_WIDTH/8;i++) begin
				result[8*i+:8]=(mask_bits[i])?temp[8*i+:8]:operand_3_vector[8*i+:8];
			end
		end
		5'b10010: begin
			for(int i=0;i<DATA_WIDTH/16;i++) begin
				result[16*i+:16]=(mask_bits[i])?temp[16*i+:16]:operand_3_vector[16*i+:16];
			end
		end
		5'b10100: begin
			for(int i=0;i<DATA_WIDTH/32;i++) begin
				result[32*i+:32]=(mask_bits[i])?temp[32*i+:32]:operand_3_vector[32*i+:32];
			end
		end
		5'b10110: begin
			for(int i=0;i<DATA_WIDTH/64;i++) begin
				result[64*i+:64]=(mask_bits[i])?temp[64*i+:64]:operand_3_vector[64*i+:64];
			end
		end
		5'b10001: begin
			for(int i=0;i<DATA_WIDTH/8;i++) begin
				result[i+:1]=(mask_bits[i])?temp[i+:1]:0;
			end
		end
		5'b10011: begin
			for(int i=0;i<DATA_WIDTH/16;i++) begin
				result[i+:1]=(mask_bits[i])?temp[i+:1]:0;
			end
		end
		5'b10101: begin
			for(int i=0;i<DATA_WIDTH/32;i++) begin
				result[i+:1]=(mask_bits[i])?temp[i+:1]:0;
			end
		end
		5'b10111: begin
			for(int i=0;i<DATA_WIDTH/64;i++) begin
				result[i+:1]=(mask_bits[i])?temp[i+:1]:0;
			end
		end
		default: result=temp;
	endcase
end
//

endmodule