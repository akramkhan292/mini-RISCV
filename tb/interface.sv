interface riscv_intf(input logic clk, input logic rst);

    logic [31:0] prog_addr;
    logic [31:0] prog_data;
    logic prog_we;

endinterface