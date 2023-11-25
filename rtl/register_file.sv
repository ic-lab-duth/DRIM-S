/*
* @info Register File Module
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief The size and read ports can be parameterized.
*		 Only one write port
*        Regiter R0 is hardwired to value==0
*
* @param DATA_WIDTH : # of Data Bits
* @param ADDR_WIDTH : # of Address Bits
* @param SIZE       : # of Entries in the Register File
* @param READ_PORTS : # of Read Ports
*/
module register_file #(DATA_WIDTH=32, ADDR_WIDTH=6, SIZE=64, READ_PORTS=2) (
	input  logic                                  clk         ,
	input  logic                                  rst_n       ,
	// Write Port
	input  logic                                  write_En    ,
	input  logic [ADDR_WIDTH-1:0]                 write_Addr  ,
	input  logic [DATA_WIDTH-1:0]                 write_Data  ,
	// Write Port
	input  logic                                  write_En_2  ,
	input  logic [ADDR_WIDTH-1:0]                 write_Addr_2,
	input  logic [DATA_WIDTH-1:0]                 write_Data_2,
	// Read Port
	input  logic [READ_PORTS-1:0][ADDR_WIDTH-1:0] read_Addr   ,
	output logic [READ_PORTS-1:0][DATA_WIDTH-1:0] data_Out
);
	// #Internal Signals#
	logic [SIZE-1:0][DATA_WIDTH-1 : 0] RegFile;
	logic not_zero, not_zero_2;

	//Create OH signals
	logic [SIZE-1:0] address_1, address_2;
	assign address_1 = 1 << write_Addr;
	assign address_2 = 1 << write_Addr_2;
	//do not write on slot 0
	assign not_zero   = |write_Addr;
	assign not_zero_2 = |write_Addr_2;
	//Write Data
	always_ff @(posedge clk or negedge rst_n) begin : WriteData
		if(!rst_n) begin
			RegFile[0] <= 'b0;
		end else begin
			// if(write_En && not_zero) begin
			// 	RegFile[write_Addr] <= write_Data;
			// end
			for (int i = 0; i < SIZE; i++) begin
				if(write_En_2 && not_zero_2 && address_2[i]) begin
					RegFile[i] <= write_Data_2;
				end else if(write_En && not_zero && address_1[i]) begin
					RegFile[i] <= write_Data;
				end
			end
		end
	end
	//Output Data
	always_comb begin : ReadData
		for (int i = 0; i < READ_PORTS; i++) begin
			data_Out[i] = RegFile[read_Addr[i]];
		end
	end

endmodule