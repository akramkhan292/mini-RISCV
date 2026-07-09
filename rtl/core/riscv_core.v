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

    //----------------------PC + Fetch-----------------------
    wire [31:0] pc, next_pc;
    wire [31:0] instr;

    fetch_stage fetch_inst (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .prog_addr(prog_addr),
        .prog_data(prog_data),
        .prog_we(prog_we),
        .pc(pc),
        .instr(instr)
    );

    //-----------------DECODE-----------------------
    wire [31:0] rd1, rd2, imm, write_data;
    wire [4:0] rs1, rs2, rd;
    wire [6:0] opcode;
    wire [2:0] func3;
    wire [6:0] func7;

    decode_stage decode_inst (
        .clk(clk),
        .instr(instr),
        .write_data(write_data),
        .reg_write(reg_write),
        .rd1(rd1),
        .rd2(rd2),
        .imm(imm),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode),
        .func3(func3),
        .func7(func7)
    );

    //----------------Control Unit-----------------
    wire reg_write, mem_read, mem_write, alu_src, branch, jump, jalr;
    wire [2:0] branch_type;
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
        .branch_type(branch_type),
        .alu_ctrl(alu_ctrl),
        .jump(jump),
        .jalr(jalr)
    );

    //-------------------- Execute --------------------
    wire [31:0] alu_result;
    wire branch_taken;

    execute_stage execute_inst (
        .rd1(rd1),
        .rd2(rd2),
        .imm(imm),
        .pc(pc),
        .alu_src(alu_src),
        .alu_ctrl(alu_ctrl),
        .branch(branch),
        .branch_type(branch_type),
        .jump(jump),
        .jalr(jalr),
        .alu_result(alu_result),
        .branch_taken(branch_taken),
        .next_pc(next_pc)
    );

    //-------------------- Memory --------------------
    wire [31:0] load_data;

    memory_stage memory_inst (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .store_type(store_type),
        .addr(alu_result),
        .data_in(rd2),
        .func3(func3),
        .load_data(load_data)
    );

    // -------------------- Write Back --------------------
    assign write_data = ((jump || jalr) ? pc + 4 :
                        (mem_read) ? load_data :
                                     alu_result);

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
