module execute_stage(
    input wire [31:0] rd1,
    input wire [31:0] rd2,
    input wire [31:0] imm,
    input wire [31:0] pc,
    input wire        alu_src,
    input wire [3:0]  alu_ctrl,
    input wire        branch,
    input wire [2:0]  branch_type,
    input wire        jump,
    input wire        jalr,

    output wire [31:0] alu_result,
    output wire        branch_taken,
    output wire [31:0] next_pc
);

    wire [31:0] alu_in2 = (alu_src) ? imm : rd2;
    wire zero;

    alu alu_inst (
        .a(rd1),
        .b(alu_in2),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    assign branch_taken = branch && (
        (branch_type == 3'b000 && alu_result == 32'd0) || // BEQ
        (branch_type == 3'b001 && alu_result != 32'd0) || // BNE
        (branch_type == 3'b010 && alu_result == 32'd1) || // BLT
        (branch_type == 3'b011 && alu_result == 32'd0) || // BGE
        (branch_type == 3'b100 && alu_result == 32'd1) || // BLTU
        (branch_type == 3'b101 && alu_result == 32'd0)    // BGEU
    );

    assign next_pc = (jalr) ? {alu_result[31:1], 1'b0} :
                     (jump) ? pc + imm :
                     (branch_taken) ? pc + imm :
                     pc + 4;

endmodule
