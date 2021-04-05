package type_definitions_pkg;

typedef struct packed {
	logic [6:0] funct7;
	logic [4:0] rs2;
	logic [4:0] rs1;
	logic [2:0] funct3;
	logic [4:0] rd;
	logic [6:0] opcode;
} R_type_instruction;

typedef struct packed {
	logic [11:0] imm_11to0;
	logic [4:0] rs1;
	logic [2:0] funct3;
	logic [4:0] rd;
	logic [6:0] opcode;
} I_type_instruction;

typedef struct packed {
	logic [6:0] imm_11to5;
	logic [4:0] rs2;
	logic [4:0] rs1;
	logic [2:0] funct3;
	logic [4:0] imm_4to0;
	logic [6:0] opcode;
} S_type_instruction;

typedef struct packed {
	logic imm_12;
	logic [5:0] imm_10to5;
	logic [4:0] rs2;
	logic [4:0] rs1;
	logic [2:0] funct3;
	logic [3:0] imm_4to1;
	logic imm_11;
	logic [6:0] opcode;
} SB_type_instruction;

typedef struct packed {
	logic [19:0] imm_31to12;
	logic [4:0] rd;
	logic [6:0] opcode;
} U_type_instruction;

typedef struct packed {
	logic imm_20;
	logic [9:0] imm_10to1;
	logic imm_11;
	logic [7:0] imm_19to12;
	logic [4:0] rd;
	logic [6:0] opcode;
} UJ_type_instruction;

typedef enum {SLL,SRL,SRA,ADD,SUB,XOR,OR,AND,SLT,SLTU,MUL,MULH,MULHU,MULHSU,DIV,DIVU,REM,REMU,ADDI,XORI,ORI,ANDI,JALR,SLLI,SRLI,SRAI,SLTI,SLTIU,LB,LH,LW,LBU,LHU,SB,SH,SW,BEQ,BNE,BLT,BGE,BLTU,BGEU,LUI,AUIPC,JAL} instructions;

endpackage : type_definitions_pkg