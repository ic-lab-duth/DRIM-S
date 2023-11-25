/*
* @info Decoder for Full-Length Instructions (32-bit instr)
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @note Functional Units:
* 00 : Load/Store Unit
* 01 : Floating Point Unit
* 10 : Integer Unit
* 11 : Branches
*
* @param INSTR_BITS: # of Instruction Bits (default 32 bits)
* @param PC_BITS   : # of PC Bits (default 32 bits)
*/
`include "enum.sv"
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
//---------------------------------------------------------------------------------------
module decoder_full #(INSTR_BITS=32, PC_BITS=32) (
    input  logic                  clk             ,
    input  logic                  rst_n           ,
    //Input Port
    input  logic                  valid           ,
    input  logic [   PC_BITS-1:0] PC_in           ,
    input  logic [INSTR_BITS-1:0] instruction_in  ,
    //Output Port
    output decoded_instr          outputs         ,
    output logic                  valid_branch    ,
    output logic                  is_jumpl        ,
    output logic                  is_return       ,
    //Benchmarking Ports
    input  logic                  second_port_free
);

    // #Internal Signals#
    logic                   valid_map, is_branch;
    logic          [ 1 : 0] fmt           ;
    logic          [ 2 : 0] funct3, rd;
    logic          [ 4 : 0] opcode, funct5, source1, source2, shamt, destination;
    logic          [ 6 : 0] funct7        ;
    logic          [11 : 0] immediate_i, immediate_s, immediate_sb;
    logic          [19 : 0] immediate_u   ;
    logic          [19 : 0] immediate_uj  ;
    detected_instr          detected_instr;

    assign valid_branch    = is_branch & valid;
    assign outputs.pc      = PC_in;
    assign outputs.is_valid= valid_map & valid;

    //Grab Fields from the Instruction
    assign opcode          = instruction_in[6:2];
    assign source1         = instruction_in[19:15];
    assign source2         = instruction_in[24:20];
    assign outputs.source3 = {1'b1,instruction_in[31:27]};
    assign outputs.rm      = instruction_in[14:12];
    assign destination     = instruction_in[11:7];

    assign funct3 = instruction_in[14:12];
    assign funct5 = instruction_in[31:27];
    assign funct7 = instruction_in[31:25];

    assign rd    = instruction_in[14:12];
    assign fmt   = instruction_in[26:25];
    assign shamt = instruction_in[24:20];
    //imm[11:0]
    assign immediate_i = instruction_in[31:20];
    //imm[11:0]
    assign immediate_s = {instruction_in[31:25],instruction_in[11:7]};
    //imm[12:1]
    assign immediate_sb = {instruction_in[31],instruction_in[7],instruction_in[30:25],instruction_in[11:8]};
    //imm[31:12]
    assign immediate_u = instruction_in[31:12];
    //imm[20:1]
    assign immediate_uj = {instruction_in[31],instruction_in[19:12],instruction_in[20],instruction_in[30:21]};

    //Create the  Fuction Call/Return signals
    assign is_jumpl  = ((opcode==5'b11001) & (destination==1)) | (opcode==5'b11011) & (destination==1);
    assign is_return = (opcode==5'b11001) & (destination==0) & (source1==1);
    //Decode the Instruction
    assign outputs.is_branch = is_branch;
    always_comb begin : OPCcheck
        valid_map                 = 1'b0;
        outputs.is_vector         = 1'b0;
        outputs.source1           = 'b0;
        outputs.source1_pc        = 'b0;
        outputs.source2           = 'b0;
        outputs.source2_immediate = 'b0;
        outputs.destination       = 'b0;
        outputs.immediate         = 'b0;
        outputs.functional_unit   = 'b0;
        outputs.microoperation    = 'b0;
        outputs.source3_valid     = 0;
        is_branch                 = 1'b0;
        unique case (opcode)
            //00xxx----------------------------
            //LOAD ->
            5'b00000 : begin
                unique case (funct3)
                    3'b000 : begin
                        //LB
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00100;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = LB;
                    end
                    3'b001 : begin
                        //LH
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00010;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = LH;
                    end
                    3'b010 : begin
                        //LW
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00001;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = LW;
                    end
                    3'b100 : begin
                        //LBU
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00101;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = LBU;
                    end
                    3'b101 : begin
                        //LHU
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00011;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = LHU;
                    end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            // // * VECTOR ->
            5'b00001 : begin
            //     outputs.source1           = {1'b0,source1};
            //     outputs.source1_pc        = 1'b0;
            //     outputs.immediate         = instruction_in;
            //     outputs.source2           = {1'b0,source2};
            //     outputs.source2_immediate = 1'b0;
            //     outputs.functional_unit   = 2'b00;
            //     is_branch                 = 1'b0;
            //     outputs.microoperation    = 5'b00000;
            //     outputs.destination       = 'b0;
            //     valid_map                 = 1'b1;
            //     outputs.is_vector         = 1'b1;
            //     detected_instr            = FSW;
            // end

                unique case (funct3)
                    3'b010 : begin
                        //FLW
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00001;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FLW;
                    end
                    // 3'b011: begin
                    //     //FLD
                    // end
                    default : begin
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = instruction_in;
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00000;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b1;
                        detected_instr            = FSW;
                    end
                endcase
            end
            // * VECTOR ->
            5'b10101 : begin
                outputs.source1           = {1'b0,source1};
                outputs.source1_pc        = 1'b0;
                outputs.immediate         = instruction_in;
                outputs.source2           = {1'b0,source2};
                outputs.source2_immediate = 1'b0;
                outputs.functional_unit   = 2'b00;
                is_branch                 = 1'b0;
                outputs.microoperation    = 5'b00000;
                outputs.destination       = 'b0;
                valid_map                 = 1'b1;
                outputs.is_vector         = 1'b1;
                detected_instr            = FSW;
            end
            //LOAD -> custom-0
            // 5'b00010:begin
            // end
            //MISC-MEM ->
            5'b00011 : begin
                unique case (funct3)
                    3'b000 : begin
                        //FENCE
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = FENCE;
                    end
                    3'b001 : begin
                        //FENCE.I
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = FENCEI;
                    end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //OP-IMM ->
            5'b00100 : begin
                unique case (funct3)
                    3'b000 : begin
                        //ADDI
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};        //sign extend
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b10;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00000;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = ADDI;
                    end
                    3'b001 : begin
                        //SLLI
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{27{1'b0}},shamt};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00111;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = SLLI;
                    end
                    3'b010 : begin
                        //SLTI
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};        //sign extend
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00010;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = SLTI;
                    end
                    3'b011 : begin
                        //SLTIU
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};        //sign extend
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00011;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = SLTIU;
                    end
                    3'b100 : begin
                        //XORI
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};    //sign extend
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b10;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b01100;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = XORI;
                    end
                    3'b101 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //SRLI
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = {{27{1'b0}},shamt};
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 1'b1;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01000;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = SRLI;
                            end
                            7'b0100000 : begin
                                //SRAI
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = {{27{1'b0}},shamt};
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 1'b1;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01001;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = SRAI;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b110 : begin
                        //ORI
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};    //sign extend
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b10;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b01011;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = ORI;
                    end
                    3'b111 : begin
                        //ANDI
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};    //sign extend
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b1;
                        outputs.functional_unit   = 2'b10;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b01010;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = ANDI;
                    end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //AUIPC ->
            5'b00101 : begin
                outputs.source1           = 'b0;
                outputs.source1_pc        = 1'b1;
                outputs.immediate         = {immediate_u,{12{1'b0}}};
                outputs.source2           = 'b0;
                outputs.source2_immediate = 1'b1;
                outputs.functional_unit   = 2'b10;
                is_branch                 = 1'b0;
                outputs.microoperation    = 5'b00000;
                outputs.destination       = {1'b0,destination};
                valid_map                 = 1'b1;
                outputs.is_vector         = 1'b0;
                detected_instr            = AUIPC;
            end
            //OP-IMM-32 ->
            // 5'b00110:begin
            // end
            //01xxx----------------------------
            //STORE ->
            5'b01000 : begin
                unique case (funct3)
                    3'b000 : begin
                        //SB
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_s[11]}},immediate_s};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b01000;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = SB;
                    end
                    3'b001 : begin
                        //SH
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_s[11]}},immediate_s};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00111;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = SH;
                    end
                    3'b010 : begin
                        //SW
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_s[11]}},immediate_s};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00110;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = SW;
                    end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            // * VECTOR ->
            5'b01001 : begin
            //         //FSW
            //         outputs.source1           = {1'b0,source1};
            //         outputs.source1_pc        = 1'b0;
            //         outputs.immediate         = instruction_in;
            //         outputs.source2           = {1'b0,source2};
            //         outputs.source2_immediate = 1'b0;
            //         outputs.functional_unit   = 2'b00;
            //         is_branch                 = 1'b0;
            //         outputs.microoperation    = 5'b00000;
            //         outputs.destination       = 'b0;
            //         valid_map                 = 1'b1;
            //         outputs.is_vector         = 1'b1;
            //         detected_instr            = FSW;
            // end
            unique case (funct3)
                    3'b010 : begin
                        //FSW
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = {1'b1,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00110;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FSW;
                    end
                    // 3'b011: begin
                    //     //FSD
                    // end
                    default : begin
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = instruction_in;
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b00;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00000;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b1;
                        detected_instr            = FSW;
                    end
                endcase
            end
            //LOAD -> custom-1
            // 5'b01010:begin
            // end
            //AMO ->
            // 5'b01011:begin
            //  if(funct3==3'b010) begin
            //      if(funct5==5'b00010) begin
            //          //LR.W
            //      end
            //      else if(funct5==5'b00011) begin
            //          //SC.W
            //      end
            //      else if(funct5==5'b00001) begin
            //          //AMOSWAP.W
            //      end
            //      else if(funct5==5'b00000) begin
            //          //AMOADD.W
            //      end
            //      else if(funct5==5'b00100) begin
            //          //AMOXOR.W
            //      end
            //      else if(funct5==5'b01100) begin
            //          //AMOAND.W
            //      end
            //      else if(funct5==5'b01000) begin
            //          //AMOOR.W
            //      end
            //      else if(funct5==5'b10100) begin
            //          //AMOMAX.W
            //      end
            //      else if(funct5==5'b11000) begin
            //          //AMOMINU.W
            //      end
            //      else if(funct5==5'b11100) begin
            //          //AMOMAXU.W
            //      end
            //  end
            // end
            //OP ->
            5'b01100 : begin
                unique case (funct3)
                    3'b000 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //ADD
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00000;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = ADD;
                            end
                            7'b0100000 : begin
                                //SUB
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00001;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = SUB;
                            end
                            7'b0000001 : begin
                                //MUL
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00010;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = MUL;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b001 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //SLL
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00100;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = SLL;
                            end
                            7'b0000001 : begin
                                //MULH
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00011;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = MULH;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b010 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //SLT
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00000;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = SLT;
                            end
                            7'b0000001 : begin
                                //MULHSU
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00101;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = MULHSU;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b011 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //SLTU
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00001;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = SLTU;
                            end
                            7'b0000001 : begin
                                //MULHU
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00100;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = MULHU;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b100 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //XOR
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01100;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = XOR;
                            end
                            7'b0000001 : begin
                                //DIV
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00110;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = DIV;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b101 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //SRL
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00101;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = SRL;
                            end
                            7'b0000001 : begin
                                //DIVU
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00111;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = DIVU;
                            end
                            7'b0100000 : begin
                                //SRA
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00110;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = SRA;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b110 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //OR
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01011;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = OR;
                            end
                            7'b0000001 : begin
                                //REM
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01000;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = REM;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b111 : begin
                        unique case (funct7)
                            7'b0000000 : begin
                                //AND
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01010;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = AND;
                            end
                            7'b0000001 : begin
                                //REMU
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.source2           = {1'b0,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 2'b10;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01001;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = REMU;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //LUI
            5'b01101 : begin
                outputs.source1           = 'b0;
                outputs.source1_pc        = 1'b0;
                outputs.immediate         = {immediate_u,{12{1'b0}}};
                outputs.source2           = 'b0;
                outputs.source2_immediate = 1'b1;
                outputs.functional_unit   = 2'b10;
                is_branch                 = 1'b0;
                outputs.microoperation    = 5'b00000;
                outputs.destination       = {1'b0,destination};
                valid_map                 = 1'b1;
                outputs.is_vector         = 1'b0;
                detected_instr            = LUI;
            end
            //OP-32 ->
            // 5'b01110:begin
            // end
            //10xxx----------------------------
            //MADD ->
            5'b10000 : begin
                unique case (fmt)
                    2'b00 : begin
                        //FMADD.S
                        outputs.source1           = {1'b1,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = 'b0;
                        outputs.source2           = {1'b1,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b01;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00011;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FMADDS;

                        outputs.source3_valid = 1'b1;

                    end
                    // 2'b01:begin
                    //     //FMADD.D
                    // end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //MSUB ->
            5'b10001 : begin
                unique case (fmt)
                    2'b00 : begin
                        //FMSUB.S
                        outputs.source1           = {1'b1,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = 'b0;
                        outputs.source2           = {1'b1,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b01;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b01011;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FMSUBS;

                        outputs.source3_valid = 1'b1;
                    end
                    // 2'b01: begin
                    //     //FMSUB.D
                    // end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //NMSUB ->
            5'b10010 : begin
                unique case (fmt)
                    2'b00 : begin
                        //FNMSUB.S
                        outputs.source1           = {1'b1,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = 'b0;
                        outputs.source2           = {1'b1,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b01;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b01111;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FNMSUBS;

                        outputs.source3_valid = 1'b1;
                    end
                    // 2'b01: begin
                    //     //FNMSUB.D
                    // end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //NMADD ->
            5'b10011 : begin
                unique case (fmt)
                    2'b00 : begin
                        //FNMADD.S
                        outputs.source1           = {1'b1,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = 'b0;
                        outputs.source2           = {1'b1,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b01;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00111;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FNMADDS;

                        outputs.source3_valid = 1'b1;
                    end
                    // 2'b01: begin
                    //     //FNMADD.D
                    // end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //OP-FP ->
            5'b10100 : begin
                unique case (funct7)
                    7'b0000000 : begin
                        //FADD.S
                        outputs.source1           = {1'b1,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = 'b0;
                        outputs.source2           = {1'b1,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b01;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00010;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FADDS;
                    end
                    // 7'b0000001: begin
                    //     //FADD.D
                    // end
                    7'b0000100 : begin
                        //FSUB.S
                        outputs.source1           = {1'b1,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = 'b0;
                        outputs.source2           = {1'b1,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b01;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b01010;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FSUBS;
                    end
                    // 7'b0000101: begin
                    //     //FSUB.D
                    // end
                    7'b0001000 : begin
                        //FMUL.S
                        outputs.source1           = {1'b1,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = 'b0;
                        outputs.source2           = {1'b1,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b01;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00001;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FMULS;
                    end
                    // 7'b0001001: begin
                    //     //FMUL.D
                    // end
                    7'b0001100 : begin
                        //FDIV.S
                        outputs.source1           = {1'b1,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = 'b0;
                        outputs.source2           = {1'b1,source1};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b01;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b00011;
                        outputs.destination       = {1'b1,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = FDIVS;
                    end
                    // 7'b0001101: begin
                    //     //FDIV.D
                    // end
                    7'b0101100 : begin
                        if (source2==5'b00000) begin
                            //FSQRT.S
                            outputs.source1           = {1'b1,source1};
                            outputs.source1_pc        = 1'b0;
                            outputs.immediate         = 'b0;
                            outputs.source2           = {1'b1,source2};
                            outputs.source2_immediate = 1'b0;
                            outputs.functional_unit   = 2'b01;
                            is_branch                 = 1'b0;
                            outputs.microoperation    = 5'b00110;
                            outputs.destination       = {1'b1,destination};
                            valid_map                 = 1'b1;
                            outputs.is_vector         = 1'b0;
                            detected_instr            = FSQRTS;
                        end else begin
                            outputs.source1           = 'b0;
                            outputs.source1_pc        = 'b0;
                            outputs.source2           = 'b0;
                            outputs.source2_immediate = 'b0;
                            outputs.destination       = 'b0;
                            outputs.immediate         = 'b0;
                            outputs.functional_unit   = 'b0;
                            outputs.microoperation    = 'b0;
                            valid_map                 = 1'b0;
                            outputs.is_vector         = 1'b0;
                            is_branch                 = 1'b0;
                            detected_instr            = IDLE;
                        end
                    end
                    7'b0010000 : begin
                        unique case (funct3)
                            3'b000 : begin
                                //FSGNJ.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b1,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b01;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01011;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FSGNJS;
                            end
                            3'b001 : begin
                                //FSGNJN.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b1,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b01;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01100;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                            end
                            3'b010 : begin
                                //FSGNJX.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b1,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b01;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01101;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FSGNJXS;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    7'b0010100 : begin
                        unique case (funct3)
                            3'b000 : begin
                                //FMIN.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b1,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b01;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00100;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FMINS;
                            end
                            3'b001 : begin
                                //FMAX.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b1,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b01;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b00101;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FMAXS;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    // 7'b0100000: begin
                    //     if(source2==5'b00001) begin
                    //         //FCVT.S.D
                    //     end
                    // end
                    // 7'b0100001: begin
                    //     if(source2==5'b00000) begin
                    //         //FCVT.D.S
                    //     end
                    // end
                    7'b1100000 : begin
                        unique case (source2)
                            5'b00000 : begin
                                //FCVT.W.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b00;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01011;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FCVTWS;
                            end
                            5'b00001 : begin
                                //FCVT.WU.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b00;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01100;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FCVTWUS;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    // 7'b1110001: begin
                    //     if (source2==5'b00000 && funct3==3'b001) begin
                    //         //FCLASS.D
                    //     end
                    // end
                    7'b1110000 : begin
                        if(source2==5'b00000) begin
                            unique case (funct3)
                                3'b000 : begin
                                    //FMV.X.S
                                    outputs.source1           = {1'b1,source1};
                                    outputs.source1_pc        = 1'b0;
                                    outputs.immediate         = 'b0;
                                    outputs.source2           = 'b0;
                                    outputs.source2_immediate = 1'b0;
                                    outputs.functional_unit   = 2'b01;
                                    is_branch                 = 1'b0;
                                    outputs.microoperation    = 5'b01110;
                                    outputs.destination       = {1'b1,destination};
                                    valid_map                 = 1'b1;
                                    outputs.is_vector         = 1'b0;
                                    detected_instr            = FMVXS;
                                end
                                3'b001 : begin
                                    //FCLASS.S
                                    outputs.source1           = {1'b1,source1};
                                    outputs.source1_pc        = 1'b0;
                                    outputs.immediate         = 'b0;
                                    outputs.source2           = {1'b1,source2};
                                    outputs.source2_immediate = 1'b0;
                                    outputs.functional_unit   = 2'b01;
                                    is_branch                 = 1'b0;
                                    outputs.microoperation    = 5'b10011;
                                    outputs.destination       = {1'b1,destination};
                                    valid_map                 = 1'b1;
                                    outputs.is_vector         = 1'b0;
                                    detected_instr            = FCLASS;
                                end
                                default : begin
                                    outputs.source1           = 'b0;
                                    outputs.source1_pc        = 'b0;
                                    outputs.source2           = 'b0;
                                    outputs.source2_immediate = 'b0;
                                    outputs.destination       = 'b0;
                                    outputs.immediate         = 'b0;
                                    outputs.functional_unit   = 'b0;
                                    outputs.microoperation    = 'b0;
                                    valid_map                 = 1'b0;
                                    outputs.is_vector         = 1'b0;
                                    is_branch                 = 1'b0;
                                    detected_instr            = IDLE;
                                end
                            endcase
                        end
                    end
                    7'b1010000 : begin
                        unique case (funct3)
                            3'b000 : begin
                                //FLE.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b1,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b01;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b10001;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FLES;
                            end
                            3'b001 : begin
                                //FLT.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b1,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b01;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b10000;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FLTS;
                            end
                            3'b010 : begin
                                //FEQ.S
                                outputs.source1           = {1'b1,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = {1'b1,source2};
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b01;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b10010;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FEQS;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    // 7'b1010001: begin
                    //     unique case (funct3)
                    //         3'b000: begin
                    //             //FLE.D
                    //         end
                    //         3'b001: begin
                    //             //FLT.D
                    //         end
                    //         3'b010: begin
                    //             //FEQ.D
                    //         end
                    //     endcase
                    // end
                    7'b1101000 : begin
                        unique case (source2)
                            5'b00000 : begin
                                //FCVT.S.W
                                outputs.source1           = {1'b0,source1};
                                outputs.immediate         = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b00;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01001;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FCVTSW;
                            end
                            5'b00001 : begin
                                //FCVT.S.WU
                                outputs.source1           = {1'b0,source1};
                                outputs.source1_pc        = 1'b0;
                                outputs.immediate         = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 1'b0;
                                outputs.functional_unit   = 2'b00;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01010;
                                outputs.destination       = {1'b1,destination};
                                valid_map                 = 1'b1;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = FCVTSWU;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    7'b1111000 : begin
                        if(source2==5'b00000 && funct3==3'b000) begin
                            //FMV.S.X
                            outputs.source1           = {1'b0,source1};
                            outputs.source1_pc        = 1'b0;
                            outputs.immediate         = 'b0;
                            outputs.source2           = 'b0;
                            outputs.source2_immediate = 1'b0;
                            outputs.functional_unit   = 2'b01;
                            is_branch                 = 1'b0;
                            outputs.microoperation    = 5'b01111;
                            outputs.destination       = {1'b1,destination};
                            valid_map                 = 1'b1;
                            outputs.is_vector         = 1'b0;
                            detected_instr            = FMVSX;
                        end else begin
                            outputs.source1           = 'b0;
                            outputs.source1_pc        = 'b0;
                            outputs.source2           = 'b0;
                            outputs.source2_immediate = 'b0;
                            outputs.destination       = 'b0;
                            outputs.immediate         = 'b0;
                            outputs.functional_unit   = 'b0;
                            outputs.microoperation    = 'b0;
                            valid_map                 = 1'b0;
                            outputs.is_vector         = 1'b0;
                            is_branch                 = 1'b0;
                            detected_instr            = IDLE;
                        end
                    end
                    // 7'b0101101: begin
                    //     if(source2==5'b00000) begin
                    //         //FSQRT.D
                    //     end
                    // end
                    // 7'b0010001: begin
                    //     unique case (funct3)
                    //         3'b000: begin
                    //             //FSGNJ.D
                    //         end
                    //         3'b001: begin
                    //             //FSGNJN.D
                    //         end
                    //         3'b010: begin
                    //             //FSGNJX.D
                    //         end
                    //     endcase
                    // end
                    // 7'b0010101: begin
                    //     unique case (funct3)
                    //         3'b000: begin
                    //             //FMIN.D
                    //         end
                    //         3'b001: begin
                    //             //MAX.D
                    //         end
                    //     endcase
                    // end
                    // 7'b1100001: begin
                    //     unique case (source2)
                    //         5'b00000: begin
                    //             //FCVT.W.D
                    //         end
                    //         5'b00001: begin
                    //             //FCVT.WU.D
                    //         end
                    //     endcase
                    // end
                    // 7'b1101001: begin
                    //     unique case (source2)
                    //         5'b00000: begin
                    //             //FCVT.D.W
                    //         end
                    //         5'b00001: begin
                    //             //FCVT.D.WU
                    //         end
                    //     endcase
                    // end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //reserved ->
            // 5'b10101:begin
            // end
            //custom-2/rv128 ->
            // 5'b10110:begin
            // end
            //11xxx----------------------------
            //BRANCH ->
            5'b11000 : begin
                unique case (funct3)
                    3'b000 : begin
                        //BEQ
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{19{immediate_sb[11]}},immediate_sb,1'b0};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b1;
                        outputs.microoperation    = 5'b01100;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = BEQ;
                    end
                    3'b001 : begin
                        //BNE
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{19{immediate_sb[11]}},immediate_sb,1'b0};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b1;
                        outputs.microoperation    = 5'b01101;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = BNE;
                    end
                    3'b100 : begin
                        //BLT
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{19{immediate_sb[11]}},immediate_sb,1'b0};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b1;
                        outputs.microoperation    = 5'b01110;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = BLT;
                    end
                    3'b101 : begin
                        //BGE
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{19{immediate_sb[11]}},immediate_sb,1'b0};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b1;
                        outputs.microoperation    = 5'b10000;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = BGE;
                    end
                    3'b110 : begin
                        //BLTU
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{19{immediate_sb[11]}},immediate_sb,1'b0};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b1;
                        outputs.microoperation    = 5'b01111;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = BLTU;
                    end
                    3'b111 : begin
                        //BGEU
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{19{immediate_sb[11]}},immediate_sb,1'b0};
                        outputs.source2           = {1'b0,source2};
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b1;
                        outputs.microoperation    = 5'b10001;
                        outputs.destination       = 'b0;
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = BGEU;
                    end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //JALR ->
            5'b11001 : begin
                outputs.source1           = {1'b0,source1};
                outputs.source1_pc        = 1'b0;
                outputs.immediate         = {{20{immediate_i[11]}},immediate_i};            //sign extend
                outputs.source2           = 'b0;
                outputs.source2_immediate = 1'b1;
                outputs.functional_unit   = 2'b11;
                is_branch                 = 1'b1;
                outputs.microoperation    = 5'b01011;
                outputs.destination       = {1'b0,destination};
                valid_map                 = 1'b1;
                outputs.is_vector         = 1'b0;
                detected_instr            = JALR;
            end
            //reserved
            // 5'b11010:begin
            // end
            //JAL ->
            5'b11011 : begin
                outputs.source1           = 'b0;
                outputs.source1_pc        = 1'b1;
                outputs.immediate         = {{11{immediate_uj[18]}},immediate_uj,1'b0};
                outputs.source2           = 'b0;
                outputs.source2_immediate = 1'b1;
                outputs.functional_unit   = 2'b11;
                is_branch                 = 1'b1;
                outputs.microoperation    = 5'b01010;
                outputs.destination       = {1'b0,destination};
                valid_map                 = 1'b1;
                outputs.is_vector         = 1'b0;
                detected_instr            = JAL;
            end
            //SYSTEM ->
            5'b11100 : begin
                unique case (funct3)
                    3'b000 : begin
                        unique case (immediate_i)
                            12'b000000000000 : begin
                                //ECALL
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 1'b1;
                                outputs.immediate         = {{11{immediate_uj[18]}},immediate_uj,1'b0};
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 1'b1;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01010;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = ECALL;
                            end
                            12'b000000000001 : begin
                                //EBREAK
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 1'b1;
                                outputs.immediate         = {{11{immediate_uj[18]}},immediate_uj,1'b0};
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 1'b1;
                                outputs.functional_unit   = 2'b11;
                                is_branch                 = 1'b0;
                                outputs.microoperation    = 5'b01010;
                                outputs.destination       = {1'b0,destination};
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                detected_instr            = EBREAK;
                            end
                            default : begin
                                outputs.source1           = 'b0;
                                outputs.source1_pc        = 'b0;
                                outputs.source2           = 'b0;
                                outputs.source2_immediate = 'b0;
                                outputs.destination       = 'b0;
                                outputs.immediate         = 'b0;
                                outputs.functional_unit   = 'b0;
                                outputs.microoperation    = 'b0;
                                valid_map                 = 1'b0;
                                outputs.is_vector         = 1'b0;
                                is_branch                 = 1'b0;
                                detected_instr            = IDLE;
                            end
                        endcase
                    end
                    3'b001 : begin
                        //CSRRW
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b11000;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = CSRRW;
                    end
                    3'b010 : begin
                        //CSRRS (pseudo rdcycle/rdinstr map here)
                        //RDCYCLEH  :immediate == -896  | immediate == 12'hC80
                        //RDCYCLE   :immediate == -1024 | immediate == 12'hC00
                        //RDTIMEH   :immediate == -895  | immediate == 12'hC81
                        //RDTIME    :immediate == -1023 | immediate == 12'hC01
                        //RDINSTRET :immediate == -894  | immediate == 12'hC82
                        //RDINSTRETH:immediate == -1022 | immediate == 12'hC02
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b11001;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        detected_instr            = CSRRS;
                    end
                    3'b011 : begin
                        //CSRRC
                        outputs.source1           = {1'b0,source1};
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b11010;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = CSRRC;
                    end
                    3'b101 : begin
                        //CSRRWI
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b11011;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = CSRRWI;
                    end
                    3'b110 : begin
                        //CSRRSI
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b11100;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = CSRRSI;
                    end
                    3'b111 : begin
                        //CSRRCI
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 1'b0;
                        outputs.immediate         = {{20{immediate_i[11]}},immediate_i};
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 1'b0;
                        outputs.functional_unit   = 2'b11;
                        is_branch                 = 1'b0;
                        outputs.microoperation    = 5'b11101;
                        outputs.destination       = {1'b0,destination};
                        valid_map                 = 1'b1;
                        outputs.is_vector         = 1'b0;
                        detected_instr            = CSRRCI;
                    end
                    default : begin
                        outputs.source1           = 'b0;
                        outputs.source1_pc        = 'b0;
                        outputs.source2           = 'b0;
                        outputs.source2_immediate = 'b0;
                        outputs.destination       = 'b0;
                        outputs.immediate         = 'b0;
                        outputs.functional_unit   = 'b0;
                        outputs.microoperation    = 'b0;
                        valid_map                 = 1'b0;
                        outputs.is_vector         = 1'b0;
                        is_branch                 = 1'b0;
                        detected_instr            = IDLE;
                    end
                endcase
            end
            //reserved ->
            // 5'b11101:begin
            // end
            //custom-3/rv128 ->
            // 5'b11110:begin
            // end
            default : begin
                outputs.source1           = 'b0;
                outputs.source1_pc        = 'b0;
                outputs.source2           = 'b0;
                outputs.source2_immediate = 'b0;
                outputs.destination       = 'b0;
                outputs.immediate         = 'b0;
                outputs.functional_unit   = 'b0;
                outputs.microoperation    = 'b0;
                valid_map                 = 1'b0;
                outputs.is_vector         = 1'b0;
                is_branch                 = 1'b0;
                detected_instr            = IDLE;
            end
        endcase
    end

`ifdef INCLUDE_SVAS
    `include "decoder_full_sva.sv"
`endif

endmodule