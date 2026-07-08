module riscv_core(
    input wire clk,
    input wire reset,
    // Add programing Interface
    input wire [31:0] prog_addr,
    input wire [31:0] prog_data,
    input wire        prog_we,

    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire        dbg_reg_write,
    output wire [4:0]  dbg_rd,
    output wire [31:0] dbg_writeback_data,
    output wire        dbg_mem_write,
    output wire [31:0] dbg_mem_addr,
    output wire [31:0] dbg_mem_wdata,
    output wire        dbg_commit_valid
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
        .clk(clk),
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
    wire [2:0] store_type;

    control_unit cu (
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .store_type(store_type),
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

    // -------------------- Immediate Generator --------------------
    wire [31:0] imm;

    imm_gen imm_gen_inst (
        .instr(instr),
        .imm(imm)
    );

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
        .store_type(store_type),
        .addr(alu_result),
        .data_in(rd2),
        .data_out(data_out)
    );

// -------------------- Load Data Extraction & Sign Extension --------------------
wire [31:0] load_data;

assign load_data = 
    (func3 == 3'b000) ? {{24{data_out[7]}},   data_out[7:0]}    : // LB  (sign-extend byte)
    (func3 == 3'b001) ? {{16{data_out[15]}},  data_out[15:0]}   : // LH  (sign-extend halfword)
    (func3 == 3'b100) ? {24'b0,               data_out[7:0]}    : // LBU (zero-extend byte)
    (func3 == 3'b101) ? {16'b0,               data_out[15:0]}   : // LHU (zero-extend halfword)
                        data_out;                                   // LW (full 32-bit word)

// -------------------- Write Back --------------------
assign write_data = (mem_read) ? load_data : alu_result;      //for LOAD write_data = load_data (with sign/zero extension) and for arithmetic operation write_data = alu_result

// -------------------- PC Update --------------------
assign next_pc = (branch && zero) ? pc + imm : pc + 4;       // branch is output of cu

// -------------------- Debug/Verification Interface --------------------
assign dbg_pc = pc;
assign dbg_instr = instr;
assign dbg_reg_write = reg_write;
assign dbg_rd = rd;
assign dbg_writeback_data = write_data;
assign dbg_mem_write = mem_write;
assign dbg_mem_addr = alu_result;
assign dbg_mem_wdata = rd2;
assign dbg_commit_valid = !reset && !prog_we;
    
endmodule
