module decode_stage(
    input wire clk,
    input wire [31:0] instr,
    input wire [31:0] write_data,
    input wire        reg_write,

    output wire [31:0] rd1,
    output wire [31:0] rd2,
    output wire [31:0] imm,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [4:0]  rd,
    output wire [6:0]  opcode,
    output wire [2:0]  func3,
    output wire [6:0]  func7
);

    assign opcode = instr[6:0];
    assign func3 = instr[14:12];
    assign func7 = instr[31:25];
    assign rs1   = instr[19:15];
    assign rs2   = instr[24:20];
    assign rd    = instr[11:7];

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

    imm_gen imm_gen_inst (
        .instr(instr),
        .imm(imm)
    );

endmodule
