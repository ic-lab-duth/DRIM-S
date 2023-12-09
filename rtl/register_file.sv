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
module register_file #(DATA_WIDTH=32, ADDR_WIDTH=6, SIZE=64, READ_PORTS=2, WRITE_PORTS = 2) (
	input  logic                                  clk         ,
	input  logic                                  rst_n       ,
	// Write Port
	input  logic [WRITE_PORTS-1:0]                 write_En  ,
	input  logic [WRITE_PORTS-1:0][ADDR_WIDTH-1:0] write_Addr,
	input  logic [WRITE_PORTS-1:0][DATA_WIDTH-1:0] write_Data,
	// Read Port
	input  logic [READ_PORTS-1:0][ADDR_WIDTH-1:0] read_Addr   ,
	output logic [READ_PORTS-1:0][DATA_WIDTH-1:0] data_Out
);
	// #Internal Signals#
	logic [SIZE-1:0][DATA_WIDTH-1 : 0] RegFile;
	logic [WRITE_PORTS - 1 : 0] not_zero;


	logic [WRITE_PORTS - 1 : 0][SIZE-1:0] address;
	always_comb for (int i = 0; i < WRITE_PORTS; ++i) begin
		address[i] = 1 << write_Addr[i];
		not_zero[i] = |write_Addr[i];
	end

	//Write Data
	always_ff @(posedge clk or negedge rst_n) begin : WriteData
		if(!rst_n) begin
			RegFile[0] <= 'b0;
		end else begin
			// if(write_En && not_zero) begin
			// 	RegFile[write_Addr] <= write_Data;
			// end
			for (int i = 0; i < SIZE; i++) begin
				for (int j = 0; j < WRITE_PORTS; ++j) begin
					if (write_En[j] && not_zero[j] && address[j][i]) RegFile[i] <= write_Data[j];
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