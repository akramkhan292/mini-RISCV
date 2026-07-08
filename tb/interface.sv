interface riscv_intf(input logic clk);

    logic rst;
    logic [31:0] prog_addr;
    logic [31:0] prog_data;
    logic prog_we;
    logic [31:0] dbg_pc;
    logic [31:0] dbg_instr;
    logic dbg_reg_write;
    logic [4:0] dbg_rd;
    logic [31:0] dbg_writeback_data;
    logic dbg_mem_write;
    logic [31:0] dbg_mem_addr;
    logic [31:0] dbg_mem_wdata;
    logic dbg_commit_valid;

endinterface
