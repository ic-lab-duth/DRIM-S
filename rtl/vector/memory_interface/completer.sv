module completer #(parameter int ADDR_RANGE=32768,
				   parameter int LENGTH_RANGE=32,
				   parameter int BUS_WIDTH=32,
                   parameter int MEMORY_BITS=32,
                   parameter int LANES_DATA_WIDTH=64,
                   parameter int VREG_BITS=256,
                   parameter int NUMBER_VECTOR_LANES=4
                )( input logic clk,
                   input logic rst,
                   //inputs from requestor
                   input logic [BUS_WIDTH-1:0] wrdata,
                   input logic [$clog2(ADDR_RANGE)-1:0] addr,
                   input logic [$clog2(LENGTH_RANGE):0] length,
                   input logic [1:0] mode_in,
                   input logic wr,
                   input logic rd,
                   input logic rddataready,
                   //outputs from completer
                   output logic ready,
                   output logic rddatavalid,
                   output logic [BUS_WIDTH-1:0] rddata,

                   // Vector memory interface
                    output  logic mem_valid_rd,
                    output  logic mem_valid_wr,
                    output  logic [31 : 0] mem_address,
                    output  logic [31 : 0] mem_data_wr,
                    input   logic mem_valid_o,
                    input   logic [31 : 0] mem_data_o,

                    input logic mem_ready);

typedef enum logic [2:0] {IDLE=3'b001,
                          READ=3'b010,
                          WRITE=3'b100} fsm_state;

fsm_state state;

//counter
logic [$clog2(LENGTH_RANGE)-1:0] counter;

logic [1:0] counter_choice;
logic comp;
logic increase;
logic [$clog2(ADDR_RANGE)-1:0] address;

assign increase=((wr & ready) | (rddataready & rddatavalid));
assign comp=(counter==length-1);
assign counter_choice={comp,increase};

always_ff @(posedge clk or posedge rst) begin
	if(rst)
		counter<=0;
	else begin
		case(counter_choice)
			2'b01:counter<=counter+1'b1;
			2'b11:counter<=0;
			default:counter<=counter;
		endcase
	end
end
//


//delay
logic [3:0] back_counter;

logic not_zero;

assign not_zero=(back_counter!=0);

always_ff @(posedge clk or posedge rst)  begin
    if(rst)
        back_counter<=$urandom();
    else begin
        if(not_zero)
            back_counter<=back_counter-1;
        else
            back_counter<=$urandom();
    end
end
//
logic unavailable;

assign unavailable=not_zero;

//fsm
logic [1:0] input_choice;
logic [2:0] write_choice;
logic valid_write;
logic one_length;
logic valid_read;

assign input_choice={rddataready,wr};
assign valid_read=(rddataready & rddatavalid);
assign one_length=(length==1);
assign valid_write=(wr & ready);
assign write_choice={comp,valid_write,one_length};

always_ff @(posedge clk or posedge rst) begin
    if(rst)
        state<=IDLE;
    else begin
        case(state)
            IDLE: begin
                casez(input_choice)
                    2'b10:state<=READ;
                    2'b01:state<=WRITE;
                    default:state<=IDLE;
                endcase
            end
            READ: begin
                if(comp && valid_read)
                    state<=IDLE;
            end
            WRITE: begin
                casez(write_choice)
                    3'b110:state<=IDLE;
                    3'b??1:state<=IDLE;
                    default:state<=WRITE;
                endcase
            end
        endcase
    end
end
//
assign address=(mode_in==1)?addr+counter:addr;

//////////////////////////////////////////////////////////////
/////     Setting outputs to requestor/memory module     /////
/////                                                    /////
//////////////////////////////////////////////////////////////

//memory_module
// vmemory #(.MEMORY_BITS(MEMORY_BITS),
//          .ADDR_RANGE(ADDR_RANGE))
//      mem(.clk(clk),
//          .we(valid_write),
//          .data_in(wrdata),
//          .address(address),
//          .rddata(rddata));
// logic read_force;
// assign mem_valid_rd = valid_read || read_force;
assign mem_valid_wr = valid_write;
assign mem_address = address << 2;
assign mem_data_wr = wrdata;
assign rddatavalid = mem_valid_o;
assign rddata = mem_data_o;


assign ready=(state==IDLE || state==WRITE) && mem_ready;

always_ff @(posedge clk or posedge rst) begin
    if(rst)
        mem_valid_rd <=0;
    else begin
        mem_valid_rd <= valid_read || (state == IDLE && rddataready);
    end
end

endmodule