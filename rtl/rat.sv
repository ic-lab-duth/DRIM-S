/*
 * @info Renaming Alias Table
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 *
 * @param P_ADDR_WIDTH : # of Preg Bits
 * @param L_ADDR_WIDTH : # of Lreg Bits
 * @param C_NUM        : # of Checkpoints
 */ 
module rat #(
	P_ADDR_WIDTH = 7,
	L_ADDR_WIDTH = 5,
	C_NUM        = 2
) (
	input  logic                     clk            ,
	input  logic                     rst_n          ,
	//Write Port #1
	input  logic [ L_ADDR_WIDTH-1:0] write_addr_1   ,
	input  logic [ P_ADDR_WIDTH-1:0] write_data_1   ,
	input  logic                     write_en_1     ,
	input  logic                     instr_1_rn     ,
	//Write Port #2
	input  logic [ L_ADDR_WIDTH-1:0] write_addr_2   ,
	input  logic [ P_ADDR_WIDTH-1:0] write_data_2   ,
	input  logic                     write_en_2     ,
	input  logic                     instr_2_rn     ,
	//Read Port #1
	input  logic [ L_ADDR_WIDTH-1:0] read_addr_1    ,
	output logic [ P_ADDR_WIDTH-1:0] read_data_1    ,
	//Read Port #2
	input  logic [ L_ADDR_WIDTH-1:0] read_addr_2    ,
	output logic [ P_ADDR_WIDTH-1:0] read_data_2    ,
	//Read Port #3
	input  logic [ L_ADDR_WIDTH-1:0] read_addr_3    ,
	output logic [ P_ADDR_WIDTH-1:0] read_data_3    ,
	//Read Port #4
	input  logic [ L_ADDR_WIDTH-1:0] read_addr_4    ,
	output logic [ P_ADDR_WIDTH-1:0] read_data_4    ,
	//Read Port #5
	input  logic [ L_ADDR_WIDTH-1:0] read_addr_5    ,
	output logic [ P_ADDR_WIDTH-1:0] read_data_5    ,
	//Read Port #6
	input  logic [ L_ADDR_WIDTH-1:0] read_addr_6    ,
	output logic [ P_ADDR_WIDTH-1:0] read_data_6    ,
	//Read Port #7
	input  logic [ L_ADDR_WIDTH-1:0] read_addr_7    ,
	output logic [ P_ADDR_WIDTH-1:0] read_data_7    ,
	//Read Port #8
	input  logic [ L_ADDR_WIDTH-1:0] read_addr_8    ,
	output logic [ P_ADDR_WIDTH-1:0] read_data_8    ,
	//Checkpoint Port
	input  logic                     take_checkpoint,
	input  logic                     instr_num      ,
	input  logic                     dual_branch    ,
	output logic [$clog2(C_NUM)-1:0] current_id     ,
	//Restore Port
	input  logic                     restore_rat    ,
	input  logic [$clog2(C_NUM)-1:0] restore_id
);

    localparam L_REGS = 2 ** L_ADDR_WIDTH;

    logic [C_NUM-1 : 0][L_REGS-1:0][P_ADDR_WIDTH-1 : 0] CheckpointedRAT;
    logic [L_REGS-1:0][P_ADDR_WIDTH-1 : 0] CurrentRAT;
    logic [$clog2(C_NUM)-1:0] next_ckp, next_ckp_plus;

    assign current_id = next_ckp;

    //Decode RAT Management
    always_ff @(posedge clk or negedge rst_n) begin : DRAT
        if(!rst_n) begin
            //Initialize all Registers paired to R8+
            for (int i = 0; i < L_REGS; i++) begin
                CurrentRAT[i] <= i;
            end
        end else begin
            //Restore the Chkp RAT
            if(restore_rat) begin
                CurrentRAT <= CheckpointedRAT[restore_id];
                //Capture this cycle's commit
            end else begin
                //Store new Allocations
                if (write_en_1) CurrentRAT[write_addr_1] <= write_data_1;
                if (write_en_2) CurrentRAT[write_addr_2] <= write_data_2;         
            end
        end
    end
    assign next_ckp_plus = next_ckp +1;
    //Checkpointed RAT Management
    always_ff @(posedge clk) begin : CkpRAT
        if(take_checkpoint) begin
            if(dual_branch) begin
                CheckpointedRAT[next_ckp]      <= CurrentRAT;
                CheckpointedRAT[next_ckp_plus] <= CurrentRAT;
                if (write_en_1) begin 
                    CheckpointedRAT[next_ckp][write_addr_1] <= write_data_1;
                    CheckpointedRAT[next_ckp_plus][write_addr_1] <= write_data_1;
                end
                if (write_en_2) CheckpointedRAT[next_ckp_plus][write_addr_2] <= write_data_2;
            end else begin
            	CheckpointedRAT[next_ckp] <= CurrentRAT;
                if(!instr_num) begin
                    if (write_en_1 && instr_1_rn) CheckpointedRAT[next_ckp][write_addr_1] <= write_data_1;
                end else begin
                    if (write_en_1) CheckpointedRAT[next_ckp][write_addr_1] <= write_data_1;
                    if (write_en_2) CheckpointedRAT[next_ckp][write_addr_2] <= write_data_2;
                end
            end
        end
    end
    //Next Checkpoint Management
    always_ff @(posedge clk or negedge rst_n) begin : NextCkp
        if(!rst_n) begin
            next_ckp <= 0;
        end else begin
            if(take_checkpoint) begin
                if(dual_branch) begin
                    next_ckp <= next_ckp +2;
                end else begin
                    next_ckp <= next_ckp +1;
                end
            end
        end
    end
    //Push Data Out
    assign read_data_1 = CurrentRAT[read_addr_1];
    assign read_data_2 = CurrentRAT[read_addr_2];
    assign read_data_3 = CurrentRAT[read_addr_3];
    assign read_data_4 = CurrentRAT[read_addr_4];
    assign read_data_5 = CurrentRAT[read_addr_5];
    assign read_data_6 = CurrentRAT[read_addr_6];
    assign read_data_7 = CurrentRAT[read_addr_7];
    assign read_data_8 = CurrentRAT[read_addr_8];
    
endmodule