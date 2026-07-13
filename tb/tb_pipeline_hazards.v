`timescale 1ns/1ps

module tb_pipeline_hazards;
    reg clk;
    reg reset;

    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire        dbg_reg_write;
    wire [4:0]  dbg_rd;
    wire [31:0] dbg_writeback_data;
    wire        dbg_mem_write;
    wire [31:0] dbg_mem_addr;
    wire [31:0] dbg_mem_wdata;
    wire        dbg_commit_valid;

    integer commit_count;
    integer pc_errors;
    integer i;
    reg [31:0] expected_pc [0:19];

    riscv_core dut (
        .clk(clk),
        .reset(reset),
        .prog_addr(32'd0),
        .prog_data(32'd0),
        .prog_we(1'b0),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_reg_write(dbg_reg_write),
        .dbg_rd(dbg_rd),
        .dbg_writeback_data(dbg_writeback_data),
        .dbg_mem_write(dbg_mem_write),
        .dbg_mem_addr(dbg_mem_addr),
        .dbg_mem_wdata(dbg_mem_wdata),
        .dbg_commit_valid(dbg_commit_valid)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, 7'b0110011};
        end
    endfunction

    function [31:0] enc_i;
        input [11:0] imm12;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_i = {imm12, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] enc_s;
        input [11:0] imm12;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        begin
            enc_s = {imm12[11:5], rs2, rs1, funct3,
                     imm12[4:0], 7'b0100011};
        end
    endfunction

    function [31:0] enc_b;
        input [12:0] imm13;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        begin
            enc_b = {imm13[12], imm13[10:5], rs2, rs1, funct3,
                     imm13[4:1], imm13[11], 7'b1100011};
        end
    endfunction

    function [31:0] enc_j;
        input [20:0] imm21;
        input [4:0] rd;
        begin
            enc_j = {imm21[20], imm21[10:1], imm21[11],
                     imm21[19:12], rd, 7'b1101111};
        end
    endfunction

    always @(negedge clk) begin
        if (dbg_commit_valid) begin
            if (commit_count >= 20) begin
                $error("Unexpected extra commit at PC 0x%08x", dbg_pc);
                pc_errors = pc_errors + 1;
            end else if (dbg_pc !== expected_pc[commit_count]) begin
                $error("Commit %0d: expected PC 0x%08x, got 0x%08x",
                       commit_count, expected_pc[commit_count], dbg_pc);
                pc_errors = pc_errors + 1;
            end
            commit_count = commit_count + 1;
        end
    end

    initial begin
        reset = 1'b1;
        commit_count = 0;
        pc_errors = 0;

        $dumpfile("pipeline_hazards.vcd");
        $dumpvars(0, tb_pipeline_hazards);

        // EX/MEM must beat MEM/WB when both match x1.
        dut.fetch_inst.imem.mem[0]  = enc_i(12'd1, 5'd0, 3'b000, 5'd1, 7'b0010011);
        dut.fetch_inst.imem.mem[1]  = enc_i(12'd1, 5'd1, 3'b000, 5'd1, 7'b0010011);
        dut.fetch_inst.imem.mem[2]  = enc_r(7'd0, 5'd0, 5'd1, 3'b000, 5'd2);

        // Consumer is in ID while x3 is in WB: this requires WB-to-ID bypass.
        dut.fetch_inst.imem.mem[3]  = enc_i(12'd5, 5'd0, 3'b000, 5'd3, 7'b0010011);
        dut.fetch_inst.imem.mem[4]  = enc_i(12'd0, 5'd0, 3'b000, 5'd0, 7'b0010011);
        dut.fetch_inst.imem.mem[5]  = enc_i(12'd0, 5'd0, 3'b000, 5'd0, 7'b0010011);
        dut.fetch_inst.imem.mem[6]  = enc_r(7'd0, 5'd0, 5'd3, 3'b000, 5'd4);

        // ALU-to-store forwarding and load-use stall/forwarding.
        dut.fetch_inst.imem.mem[7]  = enc_i(12'd42, 5'd0, 3'b000, 5'd5, 7'b0010011);
        dut.fetch_inst.imem.mem[8]  = enc_s(12'd0, 5'd5, 5'd0, 3'b010);
        dut.fetch_inst.imem.mem[9]  = enc_i(12'd0, 5'd0, 3'b010, 5'd6, 7'b0000011);
        dut.fetch_inst.imem.mem[10] = enc_r(7'd0, 5'd6, 5'd6, 3'b000, 5'd7);
        dut.fetch_inst.imem.mem[11] = enc_s(12'd4, 5'd7, 5'd0, 3'b010);
        dut.fetch_inst.imem.mem[12] = enc_i(12'd4, 5'd0, 3'b010, 5'd8, 7'b0000011);

        // Taken branch must kill both younger side effects.
        dut.fetch_inst.imem.mem[13] = enc_b(13'd12, 5'd7, 5'd8, 3'b000);
        dut.fetch_inst.imem.mem[14] = enc_s(12'd8, 5'd5, 5'd0, 3'b010);
        dut.fetch_inst.imem.mem[15] = enc_i(12'd99, 5'd0, 3'b000, 5'd9, 7'b0010011);
        dut.fetch_inst.imem.mem[16] = enc_i(12'd7, 5'd0, 3'b000, 5'd10, 7'b0010011);

        // JAL link value and wrong-path store flush.
        dut.fetch_inst.imem.mem[17] = enc_j(21'd8, 5'd11);
        dut.fetch_inst.imem.mem[18] = enc_s(12'd12, 5'd5, 5'd0, 3'b010);
        dut.fetch_inst.imem.mem[19] = enc_r(7'd0, 5'd0, 5'd11, 3'b000, 5'd12);

        // JALR base is forwarded from EX/MEM; target bit zero is cleared.
        dut.fetch_inst.imem.mem[20] = enc_i(12'd93, 5'd0, 3'b000, 5'd13, 7'b0010011);
        dut.fetch_inst.imem.mem[21] = enc_i(12'd0, 5'd13, 3'b000, 5'd14, 7'b1100111);
        dut.fetch_inst.imem.mem[22] = enc_s(12'd16, 5'd5, 5'd0, 3'b010);
        dut.fetch_inst.imem.mem[23] = enc_r(7'd0, 5'd0, 5'd14, 3'b000, 5'd15);

        for (i = 0; i < 20; i = i + 1)
            expected_pc[i] = 32'd0;
        expected_pc[0]  = 32'd0;
        expected_pc[1]  = 32'd4;
        expected_pc[2]  = 32'd8;
        expected_pc[3]  = 32'd12;
        expected_pc[4]  = 32'd16;
        expected_pc[5]  = 32'd20;
        expected_pc[6]  = 32'd24;
        expected_pc[7]  = 32'd28;
        expected_pc[8]  = 32'd32;
        expected_pc[9]  = 32'd36;
        expected_pc[10] = 32'd40;
        expected_pc[11] = 32'd44;
        expected_pc[12] = 32'd48;
        expected_pc[13] = 32'd52;
        expected_pc[14] = 32'd64;
        expected_pc[15] = 32'd68;
        expected_pc[16] = 32'd76;
        expected_pc[17] = 32'd80;
        expected_pc[18] = 32'd84;
        expected_pc[19] = 32'd92;

        dut.memory_inst.dmem.mem[0] = 32'd0;
        dut.memory_inst.dmem.mem[1] = 32'd0;
        dut.memory_inst.dmem.mem[2] = 32'd0;
        dut.memory_inst.dmem.mem[3] = 32'd0;
        dut.memory_inst.dmem.mem[4] = 32'd0;
        dut.decode_inst.rf.regfile[9] = 32'd0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (100) @(posedge clk);
        @(negedge clk);

        if (commit_count == 20 && pc_errors == 0 &&
            dut.decode_inst.rf.regfile[1] == 32'd2 &&
            dut.decode_inst.rf.regfile[2] == 32'd2 &&
            dut.decode_inst.rf.regfile[4] == 32'd5 &&
            dut.decode_inst.rf.regfile[6] == 32'd42 &&
            dut.decode_inst.rf.regfile[7] == 32'd84 &&
            dut.decode_inst.rf.regfile[8] == 32'd84 &&
            dut.decode_inst.rf.regfile[9] == 32'd0 &&
            dut.decode_inst.rf.regfile[10] == 32'd7 &&
            dut.decode_inst.rf.regfile[11] == 32'd72 &&
            dut.decode_inst.rf.regfile[12] == 32'd72 &&
            dut.decode_inst.rf.regfile[13] == 32'd93 &&
            dut.decode_inst.rf.regfile[14] == 32'd88 &&
            dut.decode_inst.rf.regfile[15] == 32'd88 &&
            dut.memory_inst.dmem.mem[0] == 32'd42 &&
            dut.memory_inst.dmem.mem[1] == 32'd84 &&
            dut.memory_inst.dmem.mem[2] == 32'd0 &&
            dut.memory_inst.dmem.mem[3] == 32'd0 &&
            dut.memory_inst.dmem.mem[4] == 32'd0) begin
            $display("PIPELINE HAZARD TEST PASSED!");
        end else begin
            $fatal(1, "PIPELINE HAZARD TEST FAILED: commits=%0d pc_errors=%0d",
                   commit_count, pc_errors);
        end

        $finish;
    end

endmodule
