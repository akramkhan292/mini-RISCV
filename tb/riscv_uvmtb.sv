`timescale 1ns/1ps

`include "interface.sv"
`include "riscv_pkg.sv"
`include "riscv_assertions.sv"

module tb_riscv;
  import uvm_pkg::*;
  import riscv_pkg::*;
  
  logic clk;

  riscv_intf intf_inst(clk);
  
  riscv_core dut(
    .clk(clk),
    .reset(intf_inst.rst),
    .prog_addr(intf_inst.prog_addr),
    .prog_data(intf_inst.prog_data),
    .prog_we(intf_inst.prog_we),
    .dbg_pc(intf_inst.dbg_pc),
    .dbg_instr(intf_inst.dbg_instr),
    .dbg_reg_write(intf_inst.dbg_reg_write),
    .dbg_rd(intf_inst.dbg_rd),
    .dbg_writeback_data(intf_inst.dbg_writeback_data),
    .dbg_mem_write(intf_inst.dbg_mem_write),
    .dbg_mem_addr(intf_inst.dbg_mem_addr),
    .dbg_mem_wdata(intf_inst.dbg_mem_wdata),
    .dbg_commit_valid(intf_inst.dbg_commit_valid)
  );

  riscv_assertions assertions_inst(intf_inst);
  
  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin
    uvm_config_db#(virtual riscv_intf)::set(null, "*", "vif", intf_inst);
    run_test("riscv_smoke_test");
  end
   
endmodule
