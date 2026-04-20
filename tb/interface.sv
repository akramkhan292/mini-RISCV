interface riscv_intf(input logic clk, input logic rst);

    wire [31:0] prog_addr;
    wire [31:0] prog_data;
    wire prog_we;

endinterface