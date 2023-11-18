//////////////////////////////////////////////////////////////
/////                    comperator                      /////
/////                                                    /////        
//////////////////////////////////////////////////////////////
module comperator #(parameter int DATA_WIDTH=64)
		           (input logic [DATA_WIDTH-1:0] operand_1,
  	    		    input logic [DATA_WIDTH-1:0] operand_2,
			        input logic [2:0] sew,
					input logic sign,
					input logic greater,
					input logic smaller,
				    input logic equal,
					input logic invert,
			        output logic [DATA_WIDTH-1:0] result);

logic [DATA_WIDTH/8-1:0] eq_temp;
logic [DATA_WIDTH/8-1:0] smaller_temp;
logic [DATA_WIDTH/8-1:0] greater_temp;
logic [DATA_WIDTH/8-1:0] smaller_temp_signed;
logic [DATA_WIDTH/8-1:0] greater_temp_signed;
logic [DATA_WIDTH/8-1:0] eq;

//8 bit compares
always_comb begin
	for(int i=0;i<DATA_WIDTH/8;i++) begin
		eq[i]=(operand_1[8*i+:8]==operand_2[8*i+:8]);
		smaller_temp[i]=(operand_2[8*i+:8]<operand_1[8*i+:8]);
		greater_temp[i]=(operand_2[8*i+:8]>operand_1[8*i+:8]);
		smaller_temp_signed[i]=($signed(operand_2[8*i+:8])<$signed(operand_1[8*i+:8]));
		greater_temp_signed[i]=($signed(operand_2[8*i+:8])>$signed(operand_1[8*i+:8]));
	end
end

assign eq_temp=(invert & sew==0)?(~eq):eq;
//

//16 bit compares
logic [DATA_WIDTH/16-1:0] temp_result_eq_16;
logic [DATA_WIDTH/16-1:0] temp_result_smaller_16;
logic [DATA_WIDTH/16-1:0] temp_result_greater_16;
logic [DATA_WIDTH/16-1:0] temp_result_smaller_signed_16;
logic [DATA_WIDTH/16-1:0] temp_result_greater_signed_16;
logic [DATA_WIDTH/16-1:0] temp_result_eq_16_final;

always_comb begin
    for(int i=0;i<DATA_WIDTH/16;i++) begin
        temp_result_eq_16[i]=(eq_temp[2*i] & eq_temp[2*i+1]);
        temp_result_smaller_16[i]=(smaller_temp[2*i+1] | eq_temp[2*i+1] & smaller_temp[2*i]);
        temp_result_greater_16[i]=(greater_temp[2*i+1] | eq_temp[2*i+1] & greater_temp[2*i]);
        temp_result_smaller_signed_16[i]=(smaller_temp_signed[2*i+1] | eq_temp[2*i+1] & smaller_temp[2*i]);
        temp_result_greater_signed_16[i]=(greater_temp_signed[2*i+1] | eq_temp[2*i+1] & greater_temp[2*i]);
    end
end
//

assign temp_result_eq_16_final=(invert & sew==1)?(~temp_result_eq_16):temp_result_eq_16;

//32 bit compares
logic [DATA_WIDTH/32-1:0] temp_result_eq_32;
logic [DATA_WIDTH/32-1:0] temp_result_smaller_32;
logic [DATA_WIDTH/32-1:0] temp_result_greater_32;
logic [DATA_WIDTH/32-1:0] temp_result_smaller_signed_32;
logic [DATA_WIDTH/32-1:0] temp_result_greater_signed_32;
logic [DATA_WIDTH/32-1:0] temp_result_eq_32_final;


always_comb begin
    for(int i=0;i<DATA_WIDTH/32;i++) begin
        temp_result_eq_32[i]=(temp_result_eq_16[2*i] & temp_result_eq_16[2*i+1]);
        temp_result_smaller_32[i]=(temp_result_smaller_16[2*i+1] | temp_result_eq_16[2*i+1] & temp_result_smaller_16[2*i]);
        temp_result_greater_32[i]=(temp_result_greater_16[2*i+1] | temp_result_eq_16[2*i+1] & temp_result_greater_16[2*i]);
        temp_result_smaller_signed_32[i]=(temp_result_smaller_signed_16[2*i+1] | temp_result_eq_16[2*i+1] & temp_result_smaller_16[2*i]);
        temp_result_greater_signed_32[i]=(temp_result_greater_signed_16[2*i+1] | temp_result_eq_16[2*i+1] & temp_result_greater_16[2*i]);
    end
end

assign temp_result_eq_32_final=(invert & sew==2)?(~temp_result_eq_32):temp_result_eq_32;
//

//64 bit_compares
logic [DATA_WIDTH/64-1:0] temp_result_eq_64;
logic [DATA_WIDTH/64-1:0] temp_result_smaller_64;
logic [DATA_WIDTH/64-1:0] temp_result_greater_64;
logic [DATA_WIDTH/64-1:0] temp_result_smaller_signed_64;
logic [DATA_WIDTH/64-1:0] temp_result_greater_signed_64;
logic [DATA_WIDTH/64-1:0] temp_result_eq_64_final;

always_comb begin
    for(int i=0;i<DATA_WIDTH/64;i++) begin
        temp_result_eq_64[i]=(temp_result_eq_32[2*i] & temp_result_eq_32[2*i+1]);
        temp_result_smaller_64[i]=(temp_result_smaller_32[2*i+1] | temp_result_eq_32[2*i+1] & temp_result_smaller_32[2*i]);
        temp_result_greater_64[i]=(temp_result_greater_32[2*i+1] | temp_result_eq_32[2*i+1] & temp_result_greater_32[2*i]);
        temp_result_smaller_signed_64[i]=(temp_result_smaller_signed_32[2*i+1] | temp_result_eq_32[2*i+1] & temp_result_smaller_32[2*i]);
        temp_result_greater_signed_64[i]=(temp_result_greater_signed_32[2*i+1] | temp_result_eq_32[2*i+1] & temp_result_greater_32[2*i]);
    end
end

assign temp_result_eq_64_final=(invert & sew==3)?(~temp_result_eq_64):temp_result_eq_64;
//

logic [6:0] choice;

assign choice={sew,smaller,equal,greater,sign};

//take result based on sew and the type of operation we have
always_comb begin
    result=0;
    casez(choice)
        //sew 0
        7'b0001000:result=smaller_temp;
        7'b0001100:result=smaller_temp | eq_temp;
        7'b0000100:result=eq_temp;
        7'b0000010:result=greater_temp;
        7'b0001001:result=smaller_temp_signed;
        7'b0000011:result=greater_temp_signed;
        7'b0001101:result=smaller_temp_signed | eq_temp;
        //sew 1
        7'b0011000:result=temp_result_smaller_16;
        7'b0011100:result=temp_result_smaller_16 | temp_result_eq_16;
        7'b0010100:result=temp_result_eq_16_final;
        7'b0010010:result=temp_result_greater_16;
        7'b0011001:result=temp_result_smaller_signed_16;
        7'b0010011:result=temp_result_greater_signed_16;
        7'b0011101:result=temp_result_smaller_signed_16 | temp_result_eq_16;
        //sew 2
        7'b0101000:result=temp_result_smaller_32;
        7'b0101100:result=temp_result_smaller_32 | temp_result_eq_32;
        7'b0100100:result=temp_result_eq_32_final;
        7'b0100010:result=temp_result_greater_32;
        7'b0101001:result=temp_result_smaller_signed_32;
        7'b0100011:result=temp_result_greater_signed_32;
        7'b0101101:result=temp_result_smaller_signed_32 | temp_result_eq_32;
        //sew 3
        7'b0111000:result=temp_result_smaller_64;
        7'b0111100:result=temp_result_smaller_64 | temp_result_eq_64;
        7'b0110100:result=temp_result_eq_64_final;
        7'b0110010:result=temp_result_greater_64;
        7'b0111001:result=temp_result_smaller_signed_64;
        7'b0110011:result=temp_result_greater_signed_64;
        7'b0111101:result=temp_result_smaller_signed_64 | temp_result_eq_64;
        default:result=0;
    endcase
end

endmodule