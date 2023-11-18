//////////////////////////////////////////////////////////////
/////                     MULTIPLIER                     /////
/////                                                    /////        
//////////////////////////////////////////////////////////////

//module for 8 bit additions
module add_mul (input logic [7:0] op_1,
			    input logic [7:0] op_2,
			    input logic carry_in,
			    output logic [7:0] result,
			    output logic carry_out);
			

always_comb begin
	{carry_out,result}=op_1+op_2+carry_in;
end

endmodule

//carry_select_adder for multiplication
module csmadder #( parameter int OPERANDS_WIDTH=64
			 )( input logic carry_in,
				input logic [OPERANDS_WIDTH-1:0] operand_1,
				input logic [OPERANDS_WIDTH-1:0] operand_2,
				output logic [OPERANDS_WIDTH-1:0] result);
				
logic zero_carry;
logic one_carry;

logic[7:0] result_mul [2*OPERANDS_WIDTH/8-2:0];
logic [2*OPERANDS_WIDTH/8-2:0] carry_mul;
logic [7:0] result_multiplexers [OPERANDS_WIDTH/8-1:0];
logic [OPERANDS_WIDTH/8-1:0] carry_multiplexers;

genvar i;


add_mul bit_8(.op_1(operand_1[7:0]),
		      .op_2(operand_2[7:0]),
		      .carry_in(carry_in),
		      .result(result_mul[0]),
		      .carry_out(carry_mul[0]));

generate
	for(i=0;i<OPERANDS_WIDTH/8-1;i++) begin: adders
		add_mul adder_1(.op_1(operand_1[(i+1)*8+7:(i+1)*8]),
					    .op_2(operand_2[(i+1)*8+7:(i+1)*8]),
					    .carry_in(zero_carry),
					    .result(result_mul[2*i+1]),
					    .carry_out(carry_mul[2*i+1]));

		add_mul adder_2(.op_1(operand_1[(i+1)*8+7:(i+1)*8]),
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

generate
	for(i=0;i<=OPERANDS_WIDTH/8-2;i++) begin: multiplexers
		assign carry_multiplexers[i+1]=(carry_multiplexers[i])?carry_mul[2*i+2]:carry_mul[2*i+1];
		assign result_multiplexers[i+1]=(carry_multiplexers[i])?result_mul[2*i+2]:result_mul[2*i+1];
	end
endgenerate

generate
	for(i=0;i<OPERANDS_WIDTH/8;i++) begin: results
		assign result[i*8+7:i*8]=result_multiplexers[i];
	end
endgenerate

endmodule

//carry_save module
module mul_adder #(parameter int ADD_WIDTH=32
				 )(input logic [ADD_WIDTH-1:0] operand_1,
				   input logic [ADD_WIDTH-1:0] operand_2,
				   input logic [ADD_WIDTH-1:0] operand_3,
				   input logic [ADD_WIDTH-1:0] operand_4,
				   output logic [ADD_WIDTH-1:0] result,
				   output logic [ADD_WIDTH-1:0] carry);
				   
integer i;

logic [ADD_WIDTH-1:0] result_mid;
logic [ADD_WIDTH:0] carry_mid;
logic [ADD_WIDTH:0] carry_second;
logic [ADD_WIDTH-1:0] temp_result;

logic carry_out;
logic zero_carry;

//carry_save//			 
always_comb begin
	carry_mid[0]=0;
	carry_second[0]=0;
	for(i=0;i<ADD_WIDTH;i++) begin
		result_mid[i]=operand_1[i]^operand_2[i]^operand_3[i];
		carry_mid[i+1]=(operand_1[i] & operand_2[i]) | (operand_1[i] & operand_3[i]) | (operand_2[i] & operand_3[i]);
		temp_result[i]=result_mid[i]^carry_mid[i]^operand_4[i];
		carry_second[i+1]=(result_mid[i] & carry_mid[i]) | (result_mid[i] & operand_4[i]) | (carry_mid[i] & operand_4[i]);	
	end
end			 


assign result=temp_result;
assign carry=carry_second[ADD_WIDTH-1:0];

endmodule

//multiplication module for 8 bit
module mul_8 #(parameter int OPERANDS_WIDTH=8 
			  )(input logic [OPERANDS_WIDTH-1:0] operand_1,
				input logic [OPERANDS_WIDTH-1:0] operand_2,
				input logic sign,
				input logic diff,
				input logic [2:0] sew,
				output logic [2*OPERANDS_WIDTH-1:0] result,
				output logic [2*OPERANDS_WIDTH-1:0] carry);

logic [5:0] data1_choice;
logic [5:0] data2_choice;

logic [OPERANDS_WIDTH-1:0] data_1;
logic [OPERANDS_WIDTH-1:0] data_2;

logic diff_sign_8;

logic [6:0] result_choice;
logic [2*OPERANDS_WIDTH-1:0] result_temp;

assign data1_choice={sign,diff,operand_1[OPERANDS_WIDTH-1],sew};
assign data2_choice={sign,diff,operand_2[OPERANDS_WIDTH-1],sew};

assign diff_sign_8=operand_1[OPERANDS_WIDTH-1]^operand_2[OPERANDS_WIDTH-1];

assign result_choice={sign,diff,diff_sign_8,operand_2[OPERANDS_WIDTH-1],sew};

//check if 2's complement is needed for operand_1
always_comb begin
    if(data1_choice==6'b101000)
        data_1=~operand_1+1'b1;
    else
        data_1=operand_1;
end

//check if 2's complement is needed for operand_2
always_comb begin
    if(data2_choice==6'b101000 || data2_choice==6'b111000)
        data_2=~operand_2+1'b1;
    else
        data_2=operand_2;
end

assign result_temp=data_1*data_2;

//check if 2's complement is needed for result
always_comb begin
	if(result_choice==7'b1010000 || result_choice==7'b1011000 || result_choice==7'b1101000 || result_choice==7'b1111000) begin
		result=~result_temp+1'b1;
	end
	else begin
        result=result_temp;
	end
end

assign carry=0;

endmodule


//multiplication module for 16 bits
module mul_16 #(parameter int OPERANDS_WIDTH=16 
			  )(input logic clk,
			  	input logic rst,
				input logic [OPERANDS_WIDTH-1:0] operand_1,
				input logic [OPERANDS_WIDTH-1:0] operand_2,
				input logic sign,
				input logic diff,
				input logic [2:0] sew,
				output logic [2*OPERANDS_WIDTH-1:0] result,
				output logic [2*OPERANDS_WIDTH-1:0] carry);
				
logic [OPERANDS_WIDTH-1:0] partial_product_1;
logic [OPERANDS_WIDTH-1:0] partial_product_2;
logic [OPERANDS_WIDTH-1:0] partial_product_3;
logic [OPERANDS_WIDTH-1:0] partial_product_4;

logic [OPERANDS_WIDTH-1:0] partial_carry_1;
logic [OPERANDS_WIDTH-1:0] partial_carry_2;
logic [OPERANDS_WIDTH-1:0] partial_carry_3;
logic [OPERANDS_WIDTH-1:0] partial_carry_4;

logic [2*OPERANDS_WIDTH-1:0] temp_1;
logic [2*OPERANDS_WIDTH-1:0] temp_2;
logic [2*OPERANDS_WIDTH-1:0] temp_3;
logic [2*OPERANDS_WIDTH-1:0] temp_4;

logic [2*OPERANDS_WIDTH-1:0] result_mid;
logic [2*OPERANDS_WIDTH-1:0] carry_mid;
logic [2*OPERANDS_WIDTH-1:0] result_before_mux;
logic [2*OPERANDS_WIDTH-1:0] carry_before_mux;
logic [2*OPERANDS_WIDTH-1:0] result_sew_8;
logic [2*OPERANDS_WIDTH-1:0] carry_sew_8;

logic [OPERANDS_WIDTH-1:0] upper_temp1;
logic [(OPERANDS_WIDTH/2)-1:0] upper_temp2;
logic [(OPERANDS_WIDTH/2)-1:0] upper_temp3;

logic [5:0] data1_choice;
logic [5:0] data2_choice;

logic [OPERANDS_WIDTH-1:0] data_1;
logic [OPERANDS_WIDTH-1:0] data_2;

logic diff_sign_16;

logic [6:0] result_choice;
logic [2*OPERANDS_WIDTH-1:0] result_temp;
logic [2*OPERANDS_WIDTH-1:0] carry_temp;

assign data1_choice={sign,diff,operand_1[OPERANDS_WIDTH-1],sew};
assign data2_choice={sign,diff,operand_2[OPERANDS_WIDTH-1],sew};

assign diff_sign_16=operand_1[OPERANDS_WIDTH-1]^operand_2[OPERANDS_WIDTH-1];

assign result_choice={sign,diff,diff_sign_16,operand_2[OPERANDS_WIDTH-1],sew};

//check if 2's complement is needed for operand_1
always_comb begin
	if(data1_choice==6'b101001)
		data_1[OPERANDS_WIDTH-1:0]=~operand_1[OPERANDS_WIDTH-1:0]+1'b1;
	else
		data_1=operand_1;
end 

//check if 2's complement is needed for operand_2
always_comb begin
	if(data2_choice==6'b101001 || data2_choice==6'b111001)
		data_2[OPERANDS_WIDTH-1:0]=~operand_2[OPERANDS_WIDTH-1:0]+1'b1;
	else
		data_2=operand_2;
end


assign upper_temp1[OPERANDS_WIDTH-1:0]={OPERANDS_WIDTH{1'b0}};

assign upper_temp2={(OPERANDS_WIDTH/2){1'b0}};
assign upper_temp3={(OPERANDS_WIDTH/2){1'b0}};

//partial_eproducts
mul_8 par1_8(.operand_1(data_1[OPERANDS_WIDTH/2-1:0]),
			.operand_2(data_2[OPERANDS_WIDTH/2-1:0]),
			.sew(sew),
			.sign(sign),
			.diff(diff),
			.result(partial_product_1),
			.carry(partial_carry_1));

mul_8 par2_8(.operand_1(data_1[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.operand_2(data_2[OPERANDS_WIDTH/2-1:0]),
			.sew(sew),
			.sign(sign),
			.diff(diff),
			.result(partial_product_2),
			.carry(partial_carry_2));
			
mul_8 par3_8(.operand_1(data_1[OPERANDS_WIDTH/2-1:0]),
			.operand_2(data_2[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.sew(sew),
			.sign(sign),
			.diff(diff),
			.result(partial_product_3),
			.carry(partial_carry_3));
			
mul_8 par4_8(.operand_1(data_1[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.operand_2(data_2[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.sew(sew),
			.sign(sign),
			.diff(diff),
			.result(partial_product_4),
			.carry(partial_carry_4));

assign temp_1={upper_temp1,partial_product_1};
assign temp_2={upper_temp2,partial_product_2,{(OPERANDS_WIDTH/2){1'b0}}};
assign temp_3={upper_temp3,partial_product_3,{OPERANDS_WIDTH/2{1'b0}}};
assign temp_4={partial_product_4,{OPERANDS_WIDTH{1'b0}}};


//carry save addition
mul_adder #(.ADD_WIDTH(2*OPERANDS_WIDTH))
		mul_16(.operand_1(temp_1),
			   .operand_2(temp_2),
			   .operand_3(temp_3),
			   .operand_4(temp_4),
			   .result(result_mid),
			   .carry(carry_mid));

assign result_before_mux=result_mid;
assign carry_before_mux=carry_mid;

assign result_sew_8=temp_1^temp_4;
assign carry_sew_8=0;

//choose results and carry based on sew
assign result_temp=(sew[0] | sew[1])?result_before_mux:result_sew_8;
assign carry_temp=(sew[0] | sew[1])?carry_before_mux:carry_sew_8;

//check if 2's complement is needed for result
always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		result<=0;
		carry<=0;
	end
	else begin
		if(result_choice==7'b1101001 || result_choice==7'b1111001 || result_choice==7'b1010001 || result_choice==7'b1011001) begin
			result<=~result_temp+1'b1;
			carry<=~carry_temp+1'b1;		
		end
		else begin
			result<=result_temp;
			carry<=carry_temp;
		end
	end
end

endmodule

//multiplication module in 32 bits
module mul_32 #(parameter int OPERANDS_WIDTH=32 
			  )(input logic clk,
			  	input logic rst,
				input logic [OPERANDS_WIDTH-1:0] operand_1,
				input logic [OPERANDS_WIDTH-1:0] operand_2,
				input logic [2:0] sew_in,
				input logic sign_in,
				input logic diff_in,
				output logic [2*OPERANDS_WIDTH-1:0] result,
				output logic [2*OPERANDS_WIDTH-1:0] carry);
				
logic [OPERANDS_WIDTH-1:0] partial_result_1;
logic [OPERANDS_WIDTH-1:0] partial_result_2;
logic [OPERANDS_WIDTH-1:0] partial_result_3;
logic [OPERANDS_WIDTH-1:0] partial_result_4;

logic [OPERANDS_WIDTH-1:0] partial_carry_1;
logic [OPERANDS_WIDTH-1:0] partial_carry_2;
logic [OPERANDS_WIDTH-1:0] partial_carry_3;
logic [OPERANDS_WIDTH-1:0] partial_carry_4;

logic [2*OPERANDS_WIDTH-1:0] temp_1;
logic [2*OPERANDS_WIDTH-1:0] temp_2;
logic [2*OPERANDS_WIDTH-1:0] temp_3;
logic [2*OPERANDS_WIDTH-1:0] temp_4;

logic [2*OPERANDS_WIDTH-1:0] temp_carry_1;
logic [2*OPERANDS_WIDTH-1:0] temp_carry_2;
logic [2*OPERANDS_WIDTH-1:0] temp_carry_3;
logic [2*OPERANDS_WIDTH-1:0] temp_carry_4;

logic [2*OPERANDS_WIDTH-1:0] result_first;
logic [2*OPERANDS_WIDTH-1:0] carry_first;
logic [2*OPERANDS_WIDTH-1:0] result_second;
logic [2*OPERANDS_WIDTH-1:0] carry_second;
logic [2*OPERANDS_WIDTH-1:0] result_third;
logic [2*OPERANDS_WIDTH-1:0] carry_third;

logic [2*OPERANDS_WIDTH-1:0] result_before_mux;
logic [2*OPERANDS_WIDTH-1:0] carry_before_mux;
logic [2*OPERANDS_WIDTH-1:0] result_sew_8_16;
logic [2*OPERANDS_WIDTH-1:0] carry_sew_8_16;

logic [OPERANDS_WIDTH-1:0] upper_temp1;
logic [(OPERANDS_WIDTH/2)-1:0] upper_temp2;
logic [(OPERANDS_WIDTH/2)-1:0] upper_temp3;

logic [OPERANDS_WIDTH-1:0] data_1;
logic [OPERANDS_WIDTH-1:0] data_2;

logic [5:0] data1_choice;
logic [5:0] data2_choice;


logic diff_sign_32;

logic [6:0] result_choice;
logic [2*OPERANDS_WIDTH-1:0] result_temp;
logic [2*OPERANDS_WIDTH-1:0] carry_temp;

logic [2*OPERANDS_WIDTH-1:0] result_before_cut;
logic [2*OPERANDS_WIDTH-1:0] carry_before_cut;

logic [6:0] cut;

assign upper_temp1[OPERANDS_WIDTH-1:0]={OPERANDS_WIDTH{1'b0}};

assign upper_temp2={(OPERANDS_WIDTH/2){1'b0}};
assign upper_temp3={(OPERANDS_WIDTH/2){1'b0}};

assign data1_choice={sign_in,diff_in,operand_1[OPERANDS_WIDTH-1],sew_in};
assign data2_choice={sign_in,diff_in,operand_2[OPERANDS_WIDTH-1],sew_in};

//check if 2's complement is needed for operand_1
always_comb begin
	if(data1_choice==6'b101010)
		data_1=~operand_1+1'b1;
	else
		data_1=operand_1;
end

//check if 2's complement is needed for operand_2
always_comb begin
	if(data2_choice==6'b101010 || data2_choice==6'b111010)
		data_2=~operand_2+1'b1;
	else
		data_2=operand_2;
end

//partial_products
mul_16 par1(.clk(clk),
			.rst(rst),
			.operand_1(data_1[OPERANDS_WIDTH/2-1:0]),
			.operand_2(data_2[OPERANDS_WIDTH/2-1:0]),
			.sew(sew_in),
			.sign(sign_in),
			.diff(diff_in),
			.result(partial_result_1),
			.carry(partial_carry_1));

mul_16 par2(.clk(clk),
			.rst(rst),
			.operand_1(data_1[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.operand_2(data_2[OPERANDS_WIDTH/2-1:0]),
			.sew(sew_in),
			.sign(sign_in),
			.diff(diff_in),
			.result(partial_result_2),
			.carry(partial_carry_2));
			
mul_16 par3(.clk(clk),
			.rst(rst),
			.operand_1(data_1[OPERANDS_WIDTH/2-1:0]),
			.operand_2(data_2[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.sew(sew_in),
			.sign(sign_in),
			.diff(diff_in),
			.result(partial_result_3),
			.carry(partial_carry_3));
			
mul_16 par4(.clk(clk),
			.rst(rst),
			.operand_1(data_1[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.operand_2(data_2[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.sew(sew_in),
			.sign(sign_in),
			.diff(diff_in),
			.result(partial_result_4),
			.carry(partial_carry_4));
						
logic [2:0] sew;
logic sign;
logic diff;	
logic operand_2_temp;

//pipeline inputs
always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		sew<=0;
		sign<=0;
		diff<=0;
		diff_sign_32<=0;
		operand_2_temp<=0;
	end
	else begin
		sew<=sew_in;
		sign<=sign_in;
		diff<=diff_in;
		diff_sign_32<=operand_1[OPERANDS_WIDTH-1]^operand_2[OPERANDS_WIDTH-1];
		operand_2_temp<=operand_2[OPERANDS_WIDTH-1];
	end
end


assign result_choice={sign,diff,diff_sign_32,operand_2_temp,sew};

assign temp_1={upper_temp1,partial_result_1};
assign temp_2={upper_temp2,partial_result_2,{(OPERANDS_WIDTH/2){1'b0}}};
assign temp_3={upper_temp3,partial_result_3,{OPERANDS_WIDTH/2{1'b0}}};
assign temp_4={partial_result_4,{OPERANDS_WIDTH{1'b0}}};

assign temp_carry_1={upper_temp1,partial_carry_1};
assign temp_carry_2={upper_temp2,partial_carry_2,{(OPERANDS_WIDTH/2){1'b0}}};
assign temp_carry_3={upper_temp3,partial_carry_3,{OPERANDS_WIDTH/2{1'b0}}};
assign temp_carry_4={partial_carry_4,{OPERANDS_WIDTH{1'b0}}};

//carry_save
mul_adder #(.ADD_WIDTH(2*OPERANDS_WIDTH))
		mul_32_a(.operand_1(temp_1),
			   .operand_2(temp_2),
			   .operand_3(temp_3),
			   .operand_4(temp_4),
			   .result(result_first),
			   .carry(carry_first));
			   
mul_adder #(.ADD_WIDTH(2*OPERANDS_WIDTH))
		mul_32_b(.operand_1(result_first),
			   .operand_2(carry_first),
			   .operand_3(temp_carry_1),
			   .operand_4(temp_carry_2),
			   .result(result_second),
			   .carry(carry_second));
			   
mul_adder #(.ADD_WIDTH(2*OPERANDS_WIDTH))
		mul_32_c(.operand_1(result_second),
			   .operand_2(carry_second),
			   .operand_3(temp_carry_3),
			   .operand_4(temp_carry_4),
			   .result(result_third),
			   .carry(carry_third));
			   

assign result_before_mux=result_third;
assign carry_before_mux=carry_third;
assign result_sew_8_16=temp_1^temp_4;
assign carry_sew_8_16=temp_carry_1^temp_carry_4;

//choose result and carry based on sew
assign result_temp=(sew[1])?result_before_mux:result_sew_8_16;
assign carry_temp=(sew[1])?carry_before_mux:carry_sew_8_16;

//check if 2's complement is needed for result
always_comb begin
	if(result_choice==7'b1010010 || result_choice==7'b1011010 || result_choice==7'b1101010 || result_choice==7'b1111010) begin
		result_before_cut=~result_temp+1'b1;
		carry_before_cut=~carry_temp+1'b1;
	end
	else begin
		result_before_cut=result_temp;
		carry_before_cut=carry_temp;
	end
end

//check if carry should not be passed and pipeline multiplication
always_comb begin
	result=result_before_cut;
	carry=carry_before_cut;
	if(sew==1 && result_before_cut[OPERANDS_WIDTH-1] && carry_before_cut[OPERANDS_WIDTH-1]) begin
		result[OPERANDS_WIDTH-1]=0;
		carry[OPERANDS_WIDTH-1]=0;
	end
	if(sew==1 && result_before_cut[2*OPERANDS_WIDTH-1] && carry_before_cut[2*OPERANDS_WIDTH-1]) begin
		result[2*OPERANDS_WIDTH-1]=0;
		carry[2*OPERANDS_WIDTH-1]=0;
	end
end
endmodule


//multiplication in 64 bit
module mul_64 #(parameter int OPERANDS_WIDTH=64 
			  )(input logic clk,
			  	input logic rst,
				input logic [OPERANDS_WIDTH-1:0] operand_1,
				input logic [OPERANDS_WIDTH-1:0] operand_2,
				input logic [2:0] sew_in,
				input logic sign_in,
				input logic diff_in,
				output logic [2*OPERANDS_WIDTH-1:0] result,
				output logic [2*OPERANDS_WIDTH-1:0] carry);
				
logic [OPERANDS_WIDTH-1:0] partial_result_1;
logic [OPERANDS_WIDTH-1:0] partial_result_2;
logic [OPERANDS_WIDTH-1:0] partial_result_3;
logic [OPERANDS_WIDTH-1:0] partial_result_4;

logic [OPERANDS_WIDTH-1:0] partial_carry_1;
logic [OPERANDS_WIDTH-1:0] partial_carry_2;
logic [OPERANDS_WIDTH-1:0] partial_carry_3;
logic [OPERANDS_WIDTH-1:0] partial_carry_4;

logic [2*OPERANDS_WIDTH-1:0] temp_1;
logic [2*OPERANDS_WIDTH-1:0] temp_2;
logic [2*OPERANDS_WIDTH-1:0] temp_3;
logic [2*OPERANDS_WIDTH-1:0] temp_4;

logic [2*OPERANDS_WIDTH-1:0] temp_carry_1;
logic [2*OPERANDS_WIDTH-1:0] temp_carry_2;
logic [2*OPERANDS_WIDTH-1:0] temp_carry_3;
logic [2*OPERANDS_WIDTH-1:0] temp_carry_4;

logic [2*OPERANDS_WIDTH-1:0] result_first;
logic [2*OPERANDS_WIDTH-1:0] carry_first;
logic [2*OPERANDS_WIDTH-1:0] result_second;
logic [2*OPERANDS_WIDTH-1:0] carry_second;
logic [2*OPERANDS_WIDTH-1:0] result_third;
logic [2*OPERANDS_WIDTH-1:0] carry_third;

logic [2*OPERANDS_WIDTH-1:0] result_before_mux;
logic [2*OPERANDS_WIDTH-1:0] carry_before_mux;
logic [2*OPERANDS_WIDTH-1:0] result_sew_8_16_32;
logic [2*OPERANDS_WIDTH-1:0] carry_sew_8_16_32;

logic [OPERANDS_WIDTH-1:0] upper_temp1;
logic [(OPERANDS_WIDTH/2)-1:0] upper_temp2;
logic [(OPERANDS_WIDTH/2)-1:0] upper_temp3;

logic [OPERANDS_WIDTH-1:0] data_1;
logic [OPERANDS_WIDTH-1:0] data_2;

logic [5:0] data1_choice;
logic [5:0] data2_choice;


logic diff_sign_64;

logic [6:0] result_choice;
logic [2*OPERANDS_WIDTH-1:0] result_temp;
logic [2*OPERANDS_WIDTH-1:0] carry_temp;


logic [2*OPERANDS_WIDTH-1:0] result_before_cut;
logic [2*OPERANDS_WIDTH-1:0] carry_before_cut;

logic [2*OPERANDS_WIDTH-1:0] result_final;
logic carry_final;

assign upper_temp1[OPERANDS_WIDTH-1:0]={OPERANDS_WIDTH{1'b0}};

assign upper_temp2={(OPERANDS_WIDTH/2){1'b0}};
assign upper_temp3={(OPERANDS_WIDTH/2){1'b0}};

assign data1_choice={sign_in,diff_in,operand_1[OPERANDS_WIDTH-1],sew_in};
assign data2_choice={sign_in,diff_in,operand_2[OPERANDS_WIDTH-1],sew_in};


//check if 2's complement is needed for operand_1
always_comb begin
	if(data1_choice==6'b101011)
		data_1=~operand_1+1'b1;
	else
		data_1=operand_1;
end

//check if 2's complement is needed for operand_2
always_comb begin
	if(data2_choice==6'b101011 || data2_choice==6'b111011)
		data_2=~operand_2+1'b1;
	else
		data_2=operand_2;
end

//partial_products
mul_32 par1(.clk(clk),
			.rst(rst),
			.operand_1(data_1[OPERANDS_WIDTH/2-1:0]),
			.operand_2(data_2[OPERANDS_WIDTH/2-1:0]),
			.sew_in(sew_in),
			.sign_in(sign_in),
			.diff_in(diff_in),
			.result(partial_result_1),
			.carry(partial_carry_1));

mul_32 par2(.clk(clk),
			.rst(rst),
			.operand_1(data_1[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.operand_2(data_2[OPERANDS_WIDTH/2-1:0]),
			.sew_in(sew_in),
			.sign_in(sign_in),
			.diff_in(diff_in),
			.result(partial_result_2),
			.carry(partial_carry_2));
			
mul_32 par3(.clk(clk),
			.rst(rst),
			.operand_1(data_1[OPERANDS_WIDTH/2-1:0]),
			.operand_2(data_2[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.sew_in(sew_in),
			.sign_in(sign_in),
			.diff_in(diff_in),
			.result(partial_result_3),
			.carry(partial_carry_3));
			
mul_32 par4(.clk(clk),
			.rst(rst),
			.operand_1(data_1[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.operand_2(data_2[OPERANDS_WIDTH-1:OPERANDS_WIDTH/2]),
			.sew_in(sew_in),
			.sign_in(sign_in),
			.diff_in(diff_in),
			.result(partial_result_4),
			.carry(partial_carry_4));

logic [2:0] sew;
logic sign;
logic diff;	
logic operand_2_temp;

//pipeline inputs
always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		sew<=0;
		sign<=0;
		diff<=0;
		diff_sign_64<=0;
		operand_2_temp<=0;
	end
	else begin
		sew<=sew_in;
		sign<=sign_in;
		diff<=diff_in;
		diff_sign_64<=operand_1[OPERANDS_WIDTH-1]^operand_2[OPERANDS_WIDTH-1];
		operand_2_temp<=operand_2[OPERANDS_WIDTH-1];
	end
end

assign result_choice={sign,diff,diff_sign_64,operand_2_temp,sew};
						
assign temp_1={upper_temp1,partial_result_1};
assign temp_2={upper_temp2,partial_result_2,{(OPERANDS_WIDTH/2){1'b0}}};
assign temp_3={upper_temp3,partial_result_3,{OPERANDS_WIDTH/2{1'b0}}};
assign temp_4={partial_result_4,{OPERANDS_WIDTH{1'b0}}};

assign temp_carry_1={upper_temp1,partial_carry_1};
assign temp_carry_2={upper_temp2,partial_carry_2,{(OPERANDS_WIDTH/2){1'b0}}};
assign temp_carry_3={upper_temp3,partial_carry_3,{OPERANDS_WIDTH/2{1'b0}}};
assign temp_carry_4={partial_carry_4,{OPERANDS_WIDTH{1'b0}}};


mul_adder #(.ADD_WIDTH(2*OPERANDS_WIDTH))
		mul_64_a(.operand_1(temp_1),
			   .operand_2(temp_2),
			   .operand_3(temp_3),
			   .operand_4(temp_4),
			   .result(result_first),
			   .carry(carry_first));
			   
mul_adder #(.ADD_WIDTH(2*OPERANDS_WIDTH))
		mul_64_b(.operand_1(result_first),
			   .operand_2(carry_first),
			   .operand_3(temp_carry_1),
			   .operand_4(temp_carry_2),
			   .result(result_second),
			   .carry(carry_second));
			   
mul_adder #(.ADD_WIDTH(2*OPERANDS_WIDTH))
		mul_64_c(.operand_1(result_second),
			   .operand_2(carry_second),
			   .operand_3(temp_carry_3),
			   .operand_4(temp_carry_4),
			   .result(result_third),
			   .carry(carry_third));

assign result_before_mux=result_third;
assign carry_before_mux=carry_third;

assign result_sew_8_16_32=temp_1^temp_4;
assign carry_sew_8_16_32=temp_carry_1^temp_carry_4;

//choose result based on sew
assign result_temp=(sew[0] & sew[1])?result_before_mux:result_sew_8_16_32;
assign carry_temp=(sew[0] & sew[1])?carry_before_mux:carry_sew_8_16_32;

//check if 2's complement is needed for result
always_comb begin
	if(result_choice==7'b1010011 || result_choice==7'b1011011 || result_choice==7'b1101011 || result_choice==7'b1111011) begin
		result_before_cut=~result_temp+1'b1;
		carry_before_cut=~carry_temp+1'b1;
	end
	else begin
		result_before_cut=result_temp;
		carry_before_cut=carry_temp;
	end
end

//cut the carry if it is needed
always_comb begin
	result=result_before_cut;
	carry=carry_before_cut;
	if(sew==2 && result_before_cut[OPERANDS_WIDTH-1] && carry_before_cut[OPERANDS_WIDTH-1]) begin
		result[OPERANDS_WIDTH-1]=0;
		carry[OPERANDS_WIDTH-1]=0;
	end
	if((sew==2 || sew==3) && result_before_cut[2*OPERANDS_WIDTH-1] && carry_before_cut[2*OPERANDS_WIDTH-1]) begin
		result[2*OPERANDS_WIDTH-1]=0;
		carry[2*OPERANDS_WIDTH-1]=0;
	end
end

endmodule

//multiplier module
module multiplier #( parameter int OPERANDS_WIDTH=64
				  )( input logic clk,
				  	 input logic rst,
					 input logic [2:0] sew,
					 input logic high,
					 input logic diff,
					 input logic sign,
					 input logic [OPERANDS_WIDTH-1:0] operand_1,
					 input logic [OPERANDS_WIDTH-1:0] operand_2,
					 output logic [OPERANDS_WIDTH-1:0] result);
					 

logic [OPERANDS_WIDTH-1:0] temp_operand_1;
logic [OPERANDS_WIDTH-1:0] temp_operand_2;

logic [2*OPERANDS_WIDTH-1:0] result_temp;
logic [2*OPERANDS_WIDTH-1:0] carry_temp;
logic [2*OPERANDS_WIDTH-1:0] result_final;

logic [3:0] choice;
logic zero_carry;

assign zero_carry=0;
assign temp_operand_1=operand_1;
assign temp_operand_2=operand_2;
assign choice={high,sew};

genvar k;

//choose which multiplier we need based on operands_eidth
generate					
	if(OPERANDS_WIDTH==8) begin
		mul_8 mul_8(.operand_1(temp_operand_1),
				    .operand_2(temp_operand_2),
				    .sew(sew),
				    .sign(sign),
				    .diff(diff),
				    .result(result_temp),
				    .carry(carry_temp));
	end 
	else if(OPERANDS_WIDTH==16) begin
		mul_16 mul_16(.operand_1(temp_operand_1),
				      .operand_2(temp_operand_2),
				      .sew(sew),
				      .sign(sign),
				      .diff(diff),
				      .result(result_temp),
				      .carry(carry_temp));
	end
	else if(OPERANDS_WIDTH==32) begin
		mul_32 mul_32(.clk(clk),
					  .rst(rst),
					  .operand_1(temp_operand_1),
				      .operand_2(temp_operand_2),
				      .sew_in(sew),
				      .sign_in(sign),
				      .diff_in(diff),
				      .result(result_temp),
				      .carry(carry_temp));
	end
	else begin
		for(k=0;k<OPERANDS_WIDTH/64;k++) begin
			mul_64 mul_64(.clk(clk),
						  .rst(rst),
						  .operand_1(temp_operand_1[64*k+:64]),
						  .operand_2(temp_operand_2[64*k+:64]),
						  .sew_in(sew),
						  .sign_in(sign),
						  .diff_in(diff),
						  .result(result_temp[128*k+:128]),
						  .carry(carry_temp[128*k+:128]));
		end
	end
endgenerate

//carry select addition
csmadder #(.OPERANDS_WIDTH(2*OPERANDS_WIDTH))
		final_add(.carry_in(zero_carry),
			   .operand_1(result_temp),
			   .operand_2(carry_temp),
			   .result(result_final));

//set result 	   
always_comb begin
	result=0;
	case(choice)
		4'b1000: begin
			for(int i=0;i<OPERANDS_WIDTH/8;i=i+1) begin
				result[8*i+:8]=result_final[16*i+8+:8];
			end
		end
		4'b1001: begin
			for(int i=0;i<OPERANDS_WIDTH/16;i=i+1) begin
				result[16*i+:16]=result_final[32*i+16+:16];
			end
		end
		4'b1010:begin
			for(int i=0;i<OPERANDS_WIDTH/32;i=i+1) begin
				result[32*i+:32]=result_final[64*i+32+:32];
			end
		end
		4'b1011: begin
			for(int i=0;i<OPERANDS_WIDTH/64;i=i+1) begin
				result[64*i+:64]=result_final[128*i+64+:64];
			end
		end		
		4'b0000: begin
			for(int i=0;i<OPERANDS_WIDTH/8;i=i+1) begin
				result[8*i+:8]=result_final[16*i+:8];
			end
		end
		4'b0001: begin
			for(int i=0;i<OPERANDS_WIDTH/16;i=i+1) begin
				result[16*i+:16]=result_final[32*i+:16];
			end
		end
		4'b0010:begin
			for(int i=0;i<OPERANDS_WIDTH/32;i=i+1) begin
				result[32*i+:32]=result_final[64*i+:32];
			end
		end
		4'b0011: begin
			for(int i=0;i<OPERANDS_WIDTH/64;i=i+1) begin
				result[64*i+:64]=result_final[128*i+:64];
			end
		end
		default:result=0;
	endcase		
end

endmodule	   