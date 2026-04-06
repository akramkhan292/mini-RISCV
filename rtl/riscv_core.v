module riscv_core(
    input wire clk,
    input wire reset,
    // Add programing Interface
    input wire [31:0] prog_addr,
    input wire [31:0] prog_data,
    input wire        prog_we
);

    //----------------------PC-----------------------
    wire [31:0] pc, next_pc;

    pc pc_inst (
        .clk(clk),
        .rst(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    //-------------------Instruction Memory----------
    wire [31:0] instr;
    inst_mem imem(
        .addr(pc),
        .instruction(instr),
        .prog_addr(prog_addr),
        .prog_data(prog_data),
        .prog_we(prog_we)
    );

    //-----------------DECODE-----------------------
    wire [6:0] opcode;
    wire [2:0] func3;
    wire [6:0] func7;

    assign opcode = instr[6:0];
    assign func3 = instr[14:12];
    assign func7 = instr[31:25];

    //----------------Control Unit-----------------
    wire reg_write, mem_read, mem_write, alu_src, branch;
    wire [3:0] alu_ctrl;

    control_unit cu (
    .opcode(opcode),
    .func3(func3),
    .func7(func7),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .alu_src(alu_src),
    .branch(branch),
    .alu_ctrl(alu_ctrl)
);

// -------------------- Register File --------------------
wire [4:0] rs1, rs2, rd;
wire [31:0] rd1, rd2, write_data;

assign rs1 = instr[19:15];
assign rs2 = instr[24:20];
assign rd  = instr[11:7];

register_file rf (
    .clk(clk),
    .we(reg_write),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .wd(write_data),
    .rd1(rd1),
    .rd2(rd2)
);

// -------------------- Immediate Generator (basic) --------------------
reg [31:0] imm;

// only I-type for now 20{instr[31]} because it is for sign bit.
always @(*) begin
    case(opcode)
        7'b0010011, // ADDI
        7'b0000011: // LW
            imm = {{20{instr[31]}}, instr[31:20]};

        7'b0100011: // SW (S-type)
            imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

        7'b1100011: // BEQ (B-type)
            imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

        default:
            imm = 32'd0;
    endcase
end

// -------------------- ALU --------------------
wire [31:0] alu_in2, alu_result;
wire zero;

assign alu_in2 = (alu_src) ? imm : rd2;

alu alu_inst (
    .a(rd1),
    .b(alu_in2),
    .alu_ctrl(alu_ctrl),
    .result(alu_result),
    .zero(zero)
);

// -------------------- Data Memory --------------------
wire [31:0] data_out;

data_mem dmem (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .addr(alu_result),
    .data_in(rd2),
    .data_out(data_out)
);

// -------------------- Write Back --------------------
assign write_data = (mem_read) ? data_out : alu_result;      //for LOAD write_data = data_out and for add sub and other arthmatic operation write_data = alu_result

// -------------------- PC Update --------------------
assign next_pc = (branch && zero) ? pc + imm : pc + 4;       // branch is output of cu
    
endmodule