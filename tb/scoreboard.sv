class riscv_scoreboard extends uvm_component;
  `uvm_component_utils(riscv_scoreboard)

  uvm_analysis_imp#(instr_item, riscv_scoreboard) item_export;

  bit [31:0] regs[32];
  bit [31:0] mem[256];
  bit [31:0] exp_pc;
  int commit_count;

  localparam R_TYPE = 7'b0110011;
  localparam I_TYPE = 7'b0010011;
  localparam LOAD   = 7'b0000011;
  localparam STORE  = 7'b0100011;
  localparam BRANCH = 7'b1100011;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    foreach (regs[i]) regs[i] = 32'd0;
    foreach (mem[i]) mem[i] = 32'd0;
    exp_pc = 32'd0;
    commit_count = 0;
  endfunction

  function void write(instr_item item);
    bit [31:0] exp_wb;
    bit exp_reg_write;
    bit exp_mem_write;
    bit [4:0] exp_rd;
    bit [31:0] exp_mem_addr;
    bit [31:0] exp_mem_wdata;
    bit [31:0] next_pc;

    exp_wb = 32'd0;
    exp_reg_write = 1'b0;
    exp_mem_write = 1'b0;
    exp_rd = item.rd;
    exp_mem_addr = 32'd0;
    exp_mem_wdata = 32'd0;
    next_pc = exp_pc + 32'd4;

    if (item.pc !== exp_pc)
      `uvm_error("PC_MISMATCH", $sformatf("Expected PC %08h, got %08h", exp_pc, item.pc))

    case (item.opcode)
      R_TYPE: begin
        exp_reg_write = 1'b1;
        case ({item.funct7, item.funct3})
          {7'b0000000, 3'b000}: exp_wb = regs[item.rs1] + regs[item.rs2];
          {7'b0100000, 3'b000}: exp_wb = regs[item.rs1] - regs[item.rs2];
          {7'b0000000, 3'b111}: exp_wb = regs[item.rs1] & regs[item.rs2];
          {7'b0000000, 3'b110}: exp_wb = regs[item.rs1] | regs[item.rs2];
          default: `uvm_error("UNSUPPORTED_RTYPE", $sformatf("instr=%08h", item.instr))
        endcase
      end

      I_TYPE: begin
        exp_reg_write = 1'b1;
        exp_wb = regs[item.rs1] + {{20{item.imm[11]}}, item.imm[11:0]};
      end

      LOAD: begin
        exp_reg_write = 1'b1;
        exp_mem_addr = regs[item.rs1] + {{20{item.imm[11]}}, item.imm[11:0]};
        exp_wb = mem[exp_mem_addr[9:2]];
      end

      STORE: begin
        exp_mem_write = 1'b1;
        exp_mem_addr = regs[item.rs1] + {{20{item.imm[11]}}, item.imm[11:0]};
        exp_mem_wdata = regs[item.rs2];
      end

      BRANCH: begin
        if (regs[item.rs1] == regs[item.rs2])
          next_pc = exp_pc + {{19{item.imm[12]}}, item.imm[12:0]};
      end

      default:
        `uvm_error("UNSUPPORTED_OPCODE", $sformatf("opcode=%02h instr=%08h", item.opcode, item.instr))
    endcase

    if (item.reg_write !== exp_reg_write)
      `uvm_error("REGWRITE_MISMATCH", $sformatf("PC %08h expected %0b got %0b",
                 item.pc, exp_reg_write, item.reg_write))

    if (exp_reg_write && item.wb_rd != 5'd0) begin
      if (item.wb_rd !== exp_rd)
        `uvm_error("RD_MISMATCH", $sformatf("PC %08h expected x%0d got x%0d",
                   item.pc, exp_rd, item.wb_rd))
      if (item.wb_data !== exp_wb)
        `uvm_error("WB_MISMATCH", $sformatf("PC %08h rd x%0d expected %08h got %08h",
                   item.pc, exp_rd, exp_wb, item.wb_data))
      regs[item.wb_rd] = item.wb_data;
    end

    if (item.mem_write !== exp_mem_write)
      `uvm_error("MEMWRITE_MISMATCH", $sformatf("PC %08h expected %0b got %0b",
                 item.pc, exp_mem_write, item.mem_write))

    if (exp_mem_write) begin
      if (item.mem_addr !== exp_mem_addr)
        `uvm_error("MEMADDR_MISMATCH", $sformatf("PC %08h expected %08h got %08h",
                   item.pc, exp_mem_addr, item.mem_addr))
      if (item.mem_wdata !== exp_mem_wdata)
        `uvm_error("MEMDATA_MISMATCH", $sformatf("PC %08h expected %08h got %08h",
                   item.pc, exp_mem_wdata, item.mem_wdata))
      mem[exp_mem_addr[9:2]] = exp_mem_wdata;
    end

    regs[0] = 32'd0;
    exp_pc = next_pc;
    commit_count++;
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("Checked %0d committed instructions", commit_count), UVM_LOW)
  endfunction
endclass
