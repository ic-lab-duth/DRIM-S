//////////////////////////////////////////////////////////////
/////                       VSRL                         /////
/////                                                    /////        
//////////////////////////////////////////////////////////////
module vsrl #(parameter int DATA_WIDTH=64)
             (input logic [DATA_WIDTH-1:0] operand_1,
  	    	  input logic [DATA_WIDTH-1:0] operand_2,
              input logic [2:0] sew,
              output logic [DATA_WIDTH-1:0] result);

always_comb begin
    case(sew)
        3'b000: begin
            for(int i=0;i<DATA_WIDTH;i=i+8) begin
                result[i+:8]=operand_2[i+:8] >> operand_1[i+:3];
            end
        end
        3'b001: begin
            for(int i=0;i<DATA_WIDTH;i=i+16) begin
                result[i+:16]=operand_2[i+:16] >> operand_1[i+:4];
            end
        end
        3'b010: begin
            for(int i=0;i<DATA_WIDTH;i=i+32) begin
                result[i+:32]=operand_2[i+:32] >> operand_1[i+:5];
            end				
        end
        3'b011:result=operand_2 >> operand_1[5:0];
        default:result=0;
    endcase
end
        
endmodule

//////////////////////////////////////////////////////////////
/////                       VSLL                         /////
/////                                                    /////        
//////////////////////////////////////////////////////////////
module vsll #(parameter int DATA_WIDTH=64)
             (input logic [DATA_WIDTH-1:0] operand_1,
  	    	  input logic [DATA_WIDTH-1:0] operand_2,
              input logic [2:0] sew,
              output logic [DATA_WIDTH-1:0] result);

always_comb begin
    case(sew)
        3'b000: begin
            for(int i=0;i<DATA_WIDTH;i=i+8) begin
                result[i+:8]=operand_2[i+:8] << operand_1[i+:3];
            end
        end
        3'b001: begin
            for(int i=0;i<DATA_WIDTH;i=i+16) begin
                result[i+:16]=operand_2[i+:16] << operand_1[i+:4];
            end
        end
        3'b010: begin
            for(int i=0;i<DATA_WIDTH;i=i+32) begin
                result[i+:32]=operand_2[i+:32] << operand_1[i+:5];
            end				
        end
        3'b011:result=operand_2 << operand_1[5:0];
        default:result=0;
    endcase
end
        
endmodule

//////////////////////////////////////////////////////////////
/////                       VSRA                         /////
/////                                                    /////        
//////////////////////////////////////////////////////////////
module vsra #(parameter int DATA_WIDTH=64)
             (input logic [DATA_WIDTH-1:0] operand_1,
  	    	  input logic [DATA_WIDTH-1:0] operand_2,
              input logic [2:0] sew,
              output logic [DATA_WIDTH-1:0] result);

always_comb begin
    case(sew)
        3'b000: begin
            for(int i=0;i<DATA_WIDTH;i=i+8) begin
                result[i+:8]=$signed(operand_2[i+:8]) >>> operand_1[i+:3];
            end
        end
        3'b001: begin
            for(int i=0;i<DATA_WIDTH;i=i+16) begin
                result[i+:16]=$signed(operand_2[i+:16]) >>> operand_1[i+:4];
            end
        end
        3'b010: begin
            for(int i=0;i<DATA_WIDTH;i=i+32) begin
                result[i+:32]=$signed(operand_2[i+:32]) >>> operand_1[i+:5];
            end				
        end
        3'b011:result=$signed(operand_2) >>> operand_1[5:0];
        default:result=0;
    endcase
end

endmodule