module fetch_stage(
    input wire clk,
    input wire reset,
    input wire [31:0] next_pc,
    input wire [31:0] prog_addr,
    input wire [31:0] prog_data,
    input wire        prog_we,

    output wire [31:0] pc,
    output wire [31:0] instr
);

    pc pc_inst (
        .clk(clk),
        .rst(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    inst_mem imem(
        .clk(clk),
        .addr(pc),
        .instruction(instr),
        .prog_addr(prog_addr),
        .prog_data(prog_data),
        .prog_we(prog_we)
    );

endmodule
