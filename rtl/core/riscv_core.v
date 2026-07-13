module riscv_core(
    input wire clk,
    input wire reset,

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

    localparam R_TYPE = 7'b0110011;
    localparam I_TYPE = 7'b0010011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;
    localparam JALR   = 7'b1100111;

    // -------------------- IF stage --------------------
    wire [31:0] pc;
    wire [31:0] if_instr;
    wire [31:0] fetch_next_pc;
    wire        pc_en;

    // -------------------- ID stage --------------------
    wire [31:0] id_instr;
    wire [31:0] id_pc;
    wire        id_valid;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] imm;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [4:0]  rd;
    wire [6:0]  opcode;
    wire [2:0]  func3;
    wire [6:0]  func7;
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        alu_src;
    wire        branch;
    wire        jump;
    wire        jalr;
    wire        instr_valid;
    wire [2:0]  branch_type;
    wire [3:0]  alu_ctrl;
    wire [2:0]  store_type;

    // -------------------- EX stage --------------------
    wire [31:0] ex_rd1;
    wire [31:0] ex_rd2;
    wire [31:0] ex_imm;
    wire [4:0]  ex_rs1;
    wire [4:0]  ex_rs2;
    wire [4:0]  ex_rd;
    wire [2:0]  ex_func3;
    wire        ex_reg_write;
    wire        ex_mem_read;
    wire        ex_mem_write;
    wire        ex_alu_src;
    wire [3:0]  ex_alu_ctrl;
    wire        ex_branch;
    wire [2:0]  ex_branch_type;
    wire        ex_jump;
    wire        ex_jalr;
    wire [2:0]  ex_store_type;
    wire [31:0] ex_pc;
    wire [31:0] ex_instr;
    wire        ex_valid;
    wire [31:0] ex_forwarded_rd1;
    wire [31:0] ex_forwarded_rd2;
    wire [31:0] alu_result;
    wire [31:0] next_pc_from_ex;
    wire        branch_taken;
    wire        ex_redirect;

    // -------------------- MEM stage --------------------
    wire [31:0] mem_alu_result;
    wire [4:0]  mem_rd;
    wire [31:0] mem_rd2;
    wire        mem_reg_write;
    wire        mem_mem_read;
    wire        mem_mem_write;
    wire [2:0]  mem_func3;
    wire [2:0]  mem_store_type;
    wire [31:0] mem_pc;
    wire [31:0] mem_instr;
    wire        mem_jump;
    wire        mem_jalr;
    wire        mem_valid;
    wire [31:0] load_data;
    wire [31:0] mem_forward_data;

    // -------------------- WB stage --------------------
    wire [31:0] wb_load_data;
    wire [31:0] wb_alu_result;
    wire [4:0]  wb_rd;
    wire        wb_reg_write;
    wire        wb_mem_read;
    wire        wb_mem_write;
    wire [31:0] wb_mem_addr;
    wire [31:0] wb_mem_wdata;
    wire        wb_jump;
    wire        wb_jalr;
    wire [31:0] wb_pc;
    wire [31:0] wb_instr;
    wire        wb_valid;
    wire [31:0] write_data;

    // -------------------- Hazard control --------------------
    wire id_uses_rs1;
    wire id_uses_rs2;
    wire load_use_hazard;
    wire stall_if_id;
    wire flush_if_id;
    wire flush_id_ex;
    wire mem_can_forward;
    wire wb_can_forward;

    // The normal sequential path belongs to IF: advance the current fetch PC.
    // Only a resolved EX control transfer overrides it.
    assign fetch_next_pc = ex_redirect ? next_pc_from_ex : (pc + 32'd4);
    assign pc_en = ex_redirect || !load_use_hazard;

    fetch_stage fetch_inst (
        .clk(clk),
        .reset(reset),
        .pc_en(pc_en),
        .next_pc(fetch_next_pc),
        .prog_addr(prog_addr),
        .prog_data(prog_data),
        .prog_we(prog_we),
        .pc(pc),
        .instr(if_instr)
    );

    decode_stage decode_inst (
        .clk(clk),
        .instr(id_instr),
        .write_data(write_data),
        .reg_write(wb_valid && wb_reg_write && !reset),
        .write_rd(wb_rd),
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
        .jalr(jalr),
        .instr_valid(instr_valid)
    );

    // EX/MEM has priority because it contains the newest older producer.
    // Loads are not forwarded from EX/MEM: a one-cycle load-use stall lets
    // the consumer receive the value from MEM/WB instead.
    assign mem_can_forward = mem_valid && mem_reg_write && !mem_mem_read &&
                             (mem_rd != 5'd0);
    assign wb_can_forward = wb_valid && wb_reg_write && (wb_rd != 5'd0);
    assign mem_forward_data = (mem_jump || mem_jalr) ? (mem_pc + 32'd4) :
                                                      mem_alu_result;

    assign ex_forwarded_rd1 =
        (mem_can_forward && mem_rd == ex_rs1) ? mem_forward_data :
        (wb_can_forward && wb_rd == ex_rs1)   ? write_data :
                                                ex_rd1;

    assign ex_forwarded_rd2 =
        (mem_can_forward && mem_rd == ex_rs2) ? mem_forward_data :
        (wb_can_forward && wb_rd == ex_rs2)   ? write_data :
                                                ex_rd2;

    execute_stage execute_inst (
        .rd1(ex_forwarded_rd1),
        .rd2(ex_forwarded_rd2),
        .imm(ex_imm),
        .pc(ex_pc),
        .alu_src(ex_alu_src),
        .alu_ctrl(ex_alu_ctrl),
        .branch(ex_branch),
        .branch_type(ex_branch_type),
        .jump(ex_jump),
        .jalr(ex_jalr),
        .alu_result(alu_result),
        .branch_taken(branch_taken),
        .next_pc(next_pc_from_ex)
    );

    assign ex_redirect = ex_valid && (branch_taken || ex_jump || ex_jalr);

    memory_stage memory_inst (
        .clk(clk),
        .mem_read(mem_valid && mem_mem_read && !reset),
        .mem_write(mem_valid && mem_mem_write && !reset),
        .store_type(mem_store_type),
        .addr(mem_alu_result),
        .data_in(mem_rd2),
        .func3(mem_func3),
        .load_data(load_data)
    );

    // Decode-aware source usage avoids false stalls on immediate fields that
    // occupy the same instruction bits as rs2.
    assign id_uses_rs1 = id_valid && instr_valid &&
                         ((opcode == R_TYPE) || (opcode == I_TYPE) ||
                          (opcode == LOAD) || (opcode == STORE) ||
                          (opcode == BRANCH) || (opcode == JALR));
    assign id_uses_rs2 = id_valid && instr_valid &&
                         ((opcode == R_TYPE) || (opcode == STORE) ||
                          (opcode == BRANCH));

    assign load_use_hazard = ex_valid && ex_mem_read && (ex_rd != 5'd0) &&
                             ((id_uses_rs1 && ex_rd == rs1) ||
                              (id_uses_rs2 && ex_rd == rs2));

    // Redirect wins over a stall. The redirecting EX instruction still moves
    // into EX/MEM; only the two younger instructions are killed.
    assign stall_if_id = load_use_hazard && !ex_redirect;
    assign flush_if_id = ex_redirect;
    assign flush_id_ex = ex_redirect || load_use_hazard;

    pipeline_regs pipe_regs (
        .clk(clk),
        .reset(reset),
        .stall_if_id(stall_if_id),
        .flush_if_id(flush_if_id),
        .flush_id_ex(flush_id_ex),

        .if_instr(if_instr),
        .if_pc(pc),
        .if_valid(!prog_we),
        .id_instr(id_instr),
        .id_pc(id_pc),
        .id_valid(id_valid),

        .id_rd1(rd1),
        .id_rd2(rd2),
        .id_imm(imm),
        .id_rs1(rs1),
        .id_rs2(rs2),
        .id_rd(rd),
        .id_func3(func3),
        .id_reg_write(reg_write),
        .id_mem_read(mem_read),
        .id_mem_write(mem_write),
        .id_alu_src(alu_src),
        .id_alu_ctrl(alu_ctrl),
        .id_branch(branch),
        .id_branch_type(branch_type),
        .id_jump(jump),
        .id_jalr(jalr),
        .id_store_type(store_type),
        .id_pc_for_ex(id_pc),
        .id_instr_for_ex(id_instr),
        .id_valid_for_ex(id_valid && instr_valid),

        .ex_rd1(ex_rd1),
        .ex_rd2(ex_rd2),
        .ex_imm(ex_imm),
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .ex_rd(ex_rd),
        .ex_func3(ex_func3),
        .ex_reg_write(ex_reg_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_alu_src(ex_alu_src),
        .ex_alu_ctrl(ex_alu_ctrl),
        .ex_branch(ex_branch),
        .ex_branch_type(ex_branch_type),
        .ex_jump(ex_jump),
        .ex_jalr(ex_jalr),
        .ex_store_type(ex_store_type),
        .ex_pc(ex_pc),
        .ex_instr(ex_instr),
        .ex_valid(ex_valid),

        .ex_alu_result(alu_result),
        .ex_store_data(ex_forwarded_rd2),
        .mem_alu_result(mem_alu_result),
        .mem_rd(mem_rd),
        .mem_rd2(mem_rd2),
        .mem_reg_write(mem_reg_write),
        .mem_mem_read(mem_mem_read),
        .mem_mem_write(mem_mem_write),
        .mem_func3(mem_func3),
        .mem_store_type(mem_store_type),
        .mem_pc(mem_pc),
        .mem_instr(mem_instr),
        .mem_jump(mem_jump),
        .mem_jalr(mem_jalr),
        .mem_valid(mem_valid),

        .mem_load_data(load_data),
        .wb_load_data(wb_load_data),
        .wb_alu_result(wb_alu_result),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write),
        .wb_mem_read(wb_mem_read),
        .wb_mem_write(wb_mem_write),
        .wb_mem_addr(wb_mem_addr),
        .wb_mem_wdata(wb_mem_wdata),
        .wb_jump(wb_jump),
        .wb_jalr(wb_jalr),
        .wb_pc(wb_pc),
        .wb_instr(wb_instr),
        .wb_valid(wb_valid)
    );

    assign write_data = (wb_jump || wb_jalr) ? (wb_pc + 32'd4) :
                        wb_mem_read           ? wb_load_data :
                                                wb_alu_result;

    // All debug fields describe the same instruction in WB.
    assign dbg_pc = wb_pc;
    assign dbg_instr = wb_instr;
    assign dbg_reg_write = wb_valid && wb_reg_write;
    assign dbg_rd = wb_rd;
    assign dbg_writeback_data = write_data;
    assign dbg_mem_write = wb_valid && wb_mem_write;
    assign dbg_mem_addr = wb_mem_addr;
    assign dbg_mem_wdata = wb_mem_wdata;
    assign dbg_commit_valid = wb_valid && !reset && !prog_we;

endmodule
