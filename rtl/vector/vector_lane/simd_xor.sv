//////////////////////////////////////////////////////////////
/////                       VXOR                         /////
/////                                                    /////        
//////////////////////////////////////////////////////////////
module vxor #(parameter int DATA_WIDTH=64)
             (input logic [DATA_WIDTH-1:0] operand_1,
  	    	  input logic [DATA_WIDTH-1:0] operand_2,
              output logic [DATA_WIDTH-1:0] result);

assign result=operand_1^operand_2;
        
endmodule