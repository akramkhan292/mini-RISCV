// Pipeline registers for the in-order five-stage core.
// Valid bits distinguish real instructions from reset, stall, and redirect bubbles.
module pipeline_regs(
    input wire clk,
    input wire reset,

    input wire stall_if_id,
    input wire flush_if_id,
    input wire flush_id_ex,

    // IF/ID
    input wire [31:0] if_instr,
    input wire [31:0] if_pc,
    input wire        if_valid,
    output reg [31:0] id_instr,
    output reg [31:0] id_pc,
    output reg        id_valid,

    // ID/EX inputs
    input wire [31:0] id_rd1,
    input wire [31:0] id_rd2,
    input wire [31:0] id_imm,
    input wire [4:0]  id_rs1,
    input wire [4:0]  id_rs2,
    input wire [4:0]  id_rd,
    input wire [2:0]  id_func3,
    input wire        id_reg_write,
    input wire        id_mem_read,
    input wire        id_mem_write,
    input wire        id_alu_src,
    input wire [3:0]  id_alu_ctrl,
    input wire        id_branch,
    input wire [2:0]  id_branch_type,
    input wire        id_jump,
    input wire        id_jalr,
    input wire [2:0]  id_store_type,
    input wire [31:0] id_pc_for_ex,
    input wire [31:0] id_instr_for_ex,
    input wire        id_valid_for_ex,

    // ID/EX outputs
    output reg [31:0] ex_rd1,
    output reg [31:0] ex_rd2,
    output reg [31:0] ex_imm,
    output reg [4:0]  ex_rs1,
    output reg [4:0]  ex_rs2,
    output reg [4:0]  ex_rd,
    output reg [2:0]  ex_func3,
    output reg        ex_reg_write,
    output reg        ex_mem_read,
    output reg        ex_mem_write,
    output reg        ex_alu_src,
    output reg [3:0]  ex_alu_ctrl,
    output reg        ex_branch,
    output reg [2:0]  ex_branch_type,
    output reg        ex_jump,
    output reg        ex_jalr,
    output reg [2:0]  ex_store_type,
    output reg [31:0] ex_pc,
    output reg [31:0] ex_instr,
    output reg        ex_valid,

    // EX/MEM inputs
    input wire [31:0] ex_alu_result,
    input wire [31:0] ex_store_data,

    // EX/MEM outputs
    output reg [31:0] mem_alu_result,
    output reg [4:0]  mem_rd,
    output reg [31:0] mem_rd2,
    output reg        mem_reg_write,
    output reg        mem_mem_read,
    output reg        mem_mem_write,
    output reg [2:0]  mem_func3,
    output reg [2:0]  mem_store_type,
    output reg [31:0] mem_pc,
    output reg [31:0] mem_instr,
    output reg        mem_jump,
    output reg        mem_jalr,
    output reg        mem_valid,

    // MEM/WB input
    input wire [31:0] mem_load_data,

    // MEM/WB outputs
    output reg [31:0] wb_load_data,
    output reg [31:0] wb_alu_result,
    output reg [4:0]  wb_rd,
    output reg        wb_reg_write,
    output reg        wb_mem_read,
    output reg        wb_mem_write,
    output reg [31:0] wb_mem_addr,
    output reg [31:0] wb_mem_wdata,
    output reg        wb_jump,
    output reg        wb_jalr,
    output reg [31:0] wb_pc,
    output reg [31:0] wb_instr,
    output reg        wb_valid
);

    always @(posedge clk) begin
        if (reset) begin
            id_instr <= 32'h00000013;
            id_pc <= 32'd0;
            id_valid <= 1'b0;

            ex_rd1 <= 32'd0;
            ex_rd2 <= 32'd0;
            ex_imm <= 32'd0;
            ex_rs1 <= 5'd0;
            ex_rs2 <= 5'd0;
            ex_rd <= 5'd0;
            ex_func3 <= 3'd0;
            ex_reg_write <= 1'b0;
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_alu_src <= 1'b0;
            ex_alu_ctrl <= 4'd0;
            ex_branch <= 1'b0;
            ex_branch_type <= 3'd0;
            ex_jump <= 1'b0;
            ex_jalr <= 1'b0;
            ex_store_type <= 3'b010;
            ex_pc <= 32'd0;
            ex_instr <= 32'h00000013;
            ex_valid <= 1'b0;

            mem_alu_result <= 32'd0;
            mem_rd <= 5'd0;
            mem_rd2 <= 32'd0;
            mem_reg_write <= 1'b0;
            mem_mem_read <= 1'b0;
            mem_mem_write <= 1'b0;
            mem_func3 <= 3'd0;
            mem_store_type <= 3'b010;
            mem_pc <= 32'd0;
            mem_instr <= 32'h00000013;
            mem_jump <= 1'b0;
            mem_jalr <= 1'b0;
            mem_valid <= 1'b0;

            wb_load_data <= 32'd0;
            wb_alu_result <= 32'd0;
            wb_rd <= 5'd0;
            wb_reg_write <= 1'b0;
            wb_mem_read <= 1'b0;
            wb_mem_write <= 1'b0;
            wb_mem_addr <= 32'd0;
            wb_mem_wdata <= 32'd0;
            wb_jump <= 1'b0;
            wb_jalr <= 1'b0;
            wb_pc <= 32'd0;
            wb_instr <= 32'h00000013;
            wb_valid <= 1'b0;
        end else begin
            // A redirect kills the fetched wrong-path instruction. A load-use
            // stall instead holds IF/ID so it can be decoded on the next cycle.
            if (flush_if_id) begin
                id_instr <= 32'h00000013;
                id_pc <= 32'd0;
                id_valid <= 1'b0;
            end else if (!stall_if_id) begin
                id_instr <= if_instr;
                id_pc <= if_pc;
                id_valid <= if_valid;
            end

            // Redirects and load-use stalls inject a bubble into ID/EX.
            if (flush_id_ex) begin
                ex_rd1 <= 32'd0;
                ex_rd2 <= 32'd0;
                ex_imm <= 32'd0;
                ex_rs1 <= 5'd0;
                ex_rs2 <= 5'd0;
                ex_rd <= 5'd0;
                ex_func3 <= 3'd0;
                ex_reg_write <= 1'b0;
                ex_mem_read <= 1'b0;
                ex_mem_write <= 1'b0;
                ex_alu_src <= 1'b0;
                ex_alu_ctrl <= 4'd0;
                ex_branch <= 1'b0;
                ex_branch_type <= 3'd0;
                ex_jump <= 1'b0;
                ex_jalr <= 1'b0;
                ex_store_type <= 3'b010;
                ex_pc <= 32'd0;
                ex_instr <= 32'h00000013;
                ex_valid <= 1'b0;
            end else begin
                ex_rd1 <= id_rd1;
                ex_rd2 <= id_rd2;
                ex_imm <= id_imm;
                ex_rs1 <= id_rs1;
                ex_rs2 <= id_rs2;
                ex_rd <= id_rd;
                ex_func3 <= id_func3;
                ex_reg_write <= id_reg_write;
                ex_mem_read <= id_mem_read;
                ex_mem_write <= id_mem_write;
                ex_alu_src <= id_alu_src;
                ex_alu_ctrl <= id_alu_ctrl;
                ex_branch <= id_branch;
                ex_branch_type <= id_branch_type;
                ex_jump <= id_jump;
                ex_jalr <= id_jalr;
                ex_store_type <= id_store_type;
                ex_pc <= id_pc_for_ex;
                ex_instr <= id_instr_for_ex;
                ex_valid <= id_valid_for_ex;
            end

            // Older stages always drain, including while a load-use stall holds IF/ID.
            mem_alu_result <= ex_alu_result;
            mem_rd <= ex_rd;
            mem_rd2 <= ex_store_data;
            mem_reg_write <= ex_reg_write;
            mem_mem_read <= ex_mem_read;
            mem_mem_write <= ex_mem_write;
            mem_func3 <= ex_func3;
            mem_store_type <= ex_store_type;
            mem_pc <= ex_pc;
            mem_instr <= ex_instr;
            mem_jump <= ex_jump;
            mem_jalr <= ex_jalr;
            mem_valid <= ex_valid;

            wb_load_data <= mem_load_data;
            wb_alu_result <= mem_alu_result;
            wb_rd <= mem_rd;
            wb_reg_write <= mem_reg_write;
            wb_mem_read <= mem_mem_read;
            wb_mem_write <= mem_mem_write;
            wb_mem_addr <= mem_alu_result;
            wb_mem_wdata <= mem_rd2;
            wb_jump <= mem_jump;
            wb_jalr <= mem_jalr;
            wb_pc <= mem_pc;
            wb_instr <= mem_instr;
            wb_valid <= mem_valid;
        end
    end

endmodule
