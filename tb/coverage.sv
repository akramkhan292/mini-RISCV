class riscv_coverage extends uvm_subscriber#(instr_item);
  `uvm_component_utils(riscv_coverage)

  bit [6:0] opcode;
  bit [2:0] funct3;
  bit branch_seen;
  bit reg_write;
  bit mem_write;
  bit [4:0] rd;

  covergroup cg;
    option.per_instance = 1;

    cp_opcode: coverpoint opcode {
      bins r_type = {7'b0110011};
      bins i_type = {7'b0010011};
      bins load   = {7'b0000011};
      bins store  = {7'b0100011};
      bins branch = {7'b1100011};
    }

    cp_funct3: coverpoint funct3 {
      bins add_sub_beq = {3'b000};
      bins lw_sw       = {3'b010};
      bins or_op       = {3'b110};
      bins and_op      = {3'b111};
    }

    cp_rd: coverpoint rd {
      bins x0 = {0};
      bins low_regs = {[1:7]};
      bins mid_regs = {[8:23]};
      bins high_regs = {[24:31]};
    }

    cp_reg_write: coverpoint reg_write;
    cp_mem_write: coverpoint mem_write;
    cp_branch_seen: coverpoint branch_seen;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function void write(instr_item t);
    opcode = t.opcode;
    funct3 = t.funct3;
    rd = t.wb_rd;
    reg_write = t.reg_write;
    mem_write = t.mem_write;
    branch_seen = (t.opcode == 7'b1100011);
    cg.sample();
  endfunction
endclass
