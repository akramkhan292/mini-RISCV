`timescale 1ns/1ps

module tb_riscv_core;
    
    // Testbench signals
    reg clk;
    reg reset;
    
    // Instantiate your RISC-V core
    riscv_core dut (
        .clk(clk),
        .reset(reset),
        .prog_addr(32'd0),
        .prog_data(32'd0),
        .prog_we(1'b0)
    );
    
    // Clock generation: 10ns period (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test program
    initial begin
        // Assert reset before the first active clock edge.
        reset = 1'b1;

        // Setup waveform dump
        $dumpfile("riscv.vcd");
        $dumpvars(0, tb_riscv_core);
        
        // Initialize instruction memory with program
        // Program:
        //   addi x1, x0, 5    -> x1 = 5
        //   addi x2, x0, 3    -> x2 = 3
        //   add  x3, x1, x2   -> x3 = 8
        //   sub  x4, x3, x2   -> x4 = 5
        //   sw   x3, 0(x0)    -> mem[0] = 8
        //   lw   x5, 0(x0)    -> x5 = 8
        //   beq  x5, x3, +8   -> skip next instruction
        //   addi x6, x0, 1    -> skipped
        //   addi x7, x0, 9    -> x7 = 9
        //   lb   x11, 4(x0)   -> x11 = -120 (sign-extended 0x88)
        //   lbu  x12, 4(x0)   -> x12 = 136 (zero-extended 0x88)
        //   lh   x13, 4(x0)   -> x13 = -30584 (sign-extended 0x8888)
        //   lhu  x14, 4(x0)   -> x14 = 34952 (zero-extended 0x8888)
        //   sb   x1, 8(x0)    -> mem[2][7:0] = 5 (byte store)
        //   sh   x2, 10(x0)   -> mem[2][31:16] = 3 (halfword store)
        //   lw   x15, 8(x0)   -> x15 = read back from mem[2]
        
dut.fetch_inst.imem.mem[0] = 32'h00500093;  // addi x1, x0, 5
        dut.fetch_inst.imem.mem[1] = 32'h00300113;  // addi x2, x0, 3
        dut.fetch_inst.imem.mem[2] = 32'h002081b3;  // add  x3, x1, x2
      	dut.fetch_inst.imem.mem[3] = 32'h40218233;  // sub  x4, x3, x2
        dut.fetch_inst.imem.mem[4] = 32'h00302023;  // sw   x3, 0(x0)
        dut.fetch_inst.imem.mem[5] = 32'h00002283;  // lw   x5, 0(x0)
        dut.fetch_inst.imem.mem[6] = 32'h00328463;  // beq  x5, x3, +8
        dut.fetch_inst.imem.mem[7] = 32'h00100313;  // addi x6, x0, 1 (skipped)
        dut.fetch_inst.imem.mem[8] = 32'h00900393;  // addi x7, x0, 9
        dut.fetch_inst.imem.mem[9] = 32'h00400583;  // lb   x11, 4(x0)   -> sign-extend byte
        dut.fetch_inst.imem.mem[10] = 32'h00404603; // lbu  x12, 4(x0)   -> zero-extend byte
        dut.fetch_inst.imem.mem[11] = 32'h00401683; // lh   x13, 4(x0)   -> sign-extend halfword
        dut.fetch_inst.imem.mem[12] = 32'h00405703; // lhu  x14, 4(x0)   -> zero-extend halfword
        dut.fetch_inst.imem.mem[13] = 32'h00100423; // sb   x1, 8(x0)    -> store byte 5 to mem[2][7:0]
        dut.fetch_inst.imem.mem[14] = 32'h00201523; // sh   x2, 10(x0)   -> store halfword 3 to mem[2][31:16]
        dut.fetch_inst.imem.mem[15] = 32'h00802783; // lw   x15, 8(x0)   -> load mem[2] back to verify

        dut.fetch_inst.imem.mem[16] = 32'h00500813; // addi x16, x0, 5
        dut.fetch_inst.imem.mem[17] = 32'h00300893; // addi x17, x0, 3
        dut.fetch_inst.imem.mem[18] = 32'h0000913;  // addi x18, x0, 0 (initialize skipped target)
        dut.fetch_inst.imem.mem[19] = 32'h0000a13;  // addi x20, x0, 0
        dut.fetch_inst.imem.mem[20] = 32'h0000b13;  // addi x22, x0, 0
        dut.fetch_inst.imem.mem[21] = 32'h0000c13;  // addi x24, x0, 0
        dut.fetch_inst.imem.mem[22] = 32'h0000d13;  // addi x26, x0, 0
        dut.fetch_inst.imem.mem[23] = 32'h1181463;  // bne x16, x17, +8 -> taken
        dut.fetch_inst.imem.mem[24] = 32'h100913;   // addi x18, x0, 1 (skipped)
        dut.fetch_inst.imem.mem[25] = 32'h200993;   // addi x19, x0, 2
        dut.fetch_inst.imem.mem[26] = 32'h108c463;  // blt x17, x16, +8 -> taken
        dut.fetch_inst.imem.mem[27] = 32'h100a13;   // addi x20, x0, 1 (skipped)
        dut.fetch_inst.imem.mem[28] = 32'h200a93;   // addi x21, x0, 2
        dut.fetch_inst.imem.mem[29] = 32'h1185463;  // bge x16, x17, +8 -> taken
        dut.fetch_inst.imem.mem[30] = 32'h100b13;   // addi x22, x0, 1 (skipped)
        dut.fetch_inst.imem.mem[31] = 32'h200b93;   // addi x23, x0, 2
        dut.fetch_inst.imem.mem[32] = 32'h108e463;  // bltu x17, x16, +8 -> taken
        dut.fetch_inst.imem.mem[33] = 32'h100c13;   // addi x24, x0, 1 (skipped)
        dut.fetch_inst.imem.mem[34] = 32'h200c93;   // addi x25, x0, 2
        dut.fetch_inst.imem.mem[35] = 32'h1187463;  // bgeu x16, x17, +8 -> taken
        dut.fetch_inst.imem.mem[36] = 32'h100d13;   // addi x26, x0, 1 (skipped)
        dut.fetch_inst.imem.mem[37] = 32'h200d93;   // addi x27, x0, 2

        // JAL / JALR tests
        dut.fetch_inst.imem.mem[38] = 32'h0b000e93; // addi x29, x0, 176  -> target address for JALR
        dut.fetch_inst.imem.mem[39] = 32'h0080056f; // jal  x10, 8        -> x10 = pc+4, skip mem[40]
        dut.fetch_inst.imem.mem[40] = 32'h100613;   // addi x12, x0, 1   -> skipped by JAL
        dut.fetch_inst.imem.mem[41] = 32'h200e13;   // addi x28, x0, 2   -> executed after JAL
        dut.fetch_inst.imem.mem[42] = 32'h00e8f67; // jalr x30, x29, 0  -> x30 = pc+4, jump to mem[44]
        dut.fetch_inst.imem.mem[43] = 32'h100e13;   // addi x28, x0, 1   -> skipped by JALR
        dut.fetch_inst.imem.mem[44] = 32'h400f93;   // addi x31, x0, 4   -> executed after JALR target

        // Non-zero byte/halfword lane selection tests.
        dut.fetch_inst.imem.mem[45] = 32'h00d04403; // lbu  x8, 13(x0) -> byte lane 1 = 0x22
        dut.fetch_inst.imem.mem[46] = 32'h00e01483; // lh   x9, 14(x0) -> upper halfword = 0x4433
        dut.fetch_inst.imem.mem[47] = 32'h00c00e03; // lb   x28,12(x0) -> sign-extended 0x80

        // Pre-initialize data memory with test value for load instruction testing
        dut.memory_inst.dmem.mem[1] = 32'h00008888;  // Test value for LB, LBU, LH, LHU instructions
        dut.memory_inst.dmem.mem[2] = 32'h00000000;  // Initialize mem[2] for store instruction testing
        dut.memory_inst.dmem.mem[3] = 32'h44332280;  // Non-zero byte/halfword lanes

        // The architectural register file is intentionally not reset. Give the
        // skipped destination a known sentinel so the branch test is meaningful.
        dut.decode_inst.rf.regfile[6] = 32'd0;
        
        // Release reset away from the active clock edge to avoid a sampling race.
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        
        // Allow for pipeline fill, data-hazard stalls, and control-hazard flushes.
        repeat (160) @(posedge clk);
        @(negedge clk);
        
        // Display results
        $display("\n========== Test Results ==========");
        $display("x1 = %0d (expected: 5)", dut.decode_inst.rf.regfile[1]);
        $display("x2 = %0d (expected: 3)", dut.decode_inst.rf.regfile[2]);
        $display("x3 = %0d (expected: 8)", dut.decode_inst.rf.regfile[3]);
        $display("x4 = %0d (expected: 5)", dut.decode_inst.rf.regfile[4]);
        $display("x5 = %0d (expected: 8)", dut.decode_inst.rf.regfile[5]);
        $display("x6 = %0d (expected: 0, skipped)", dut.decode_inst.rf.regfile[6]);
        $display("x7 = %0d (expected: 9)", dut.decode_inst.rf.regfile[7]);
        $display("mem[0] = %0d (expected: 8)", dut.memory_inst.dmem.mem[0]);
        $display("\n--- Load Instruction Tests ---");
        $display("x11 (LB  0x88) = %d (expected: -120)", $signed(dut.decode_inst.rf.regfile[11][7:0]));
        $display("x12 (LBU 0x88) = 0x%08x (expected: 0x00000088)", dut.decode_inst.rf.regfile[12]);
        $display("x13 (LH  0x8888) = %d (expected: -30584)", $signed(dut.decode_inst.rf.regfile[13][15:0]));
        $display("x14 (LHU 0x8888) = 0x%08x (expected: 0x00008888)", dut.decode_inst.rf.regfile[14]);
        $display("x8  (LBU lane 1) = 0x%08x (expected: 0x00000022)", dut.decode_inst.rf.regfile[8]);
        $display("x9  (LH lane 2)  = 0x%08x (expected: 0x00004433)", dut.decode_inst.rf.regfile[9]);
        $display("x28 (LB lane 0)  = %0d (expected: -128)", $signed(dut.decode_inst.rf.regfile[28]));
        $display("\n--- Store Instruction Tests ---");
        $display("mem[2] (SB + SH) = 0x%08x (expected: 0x00030005)", dut.memory_inst.dmem.mem[2]);
        $display("x15 (LW mem[2]) = 0x%08x (expected: 0x00030005)", dut.decode_inst.rf.regfile[15]);
        $display("x10 (JAL) = %0d (expected: 160)", dut.decode_inst.rf.regfile[10]);
        $display("x30 (JALR) = %0d (expected: 172)", dut.decode_inst.rf.regfile[30]);
        $display("x31 (JALR skip target) = %0d (expected: 4)", dut.decode_inst.rf.regfile[31]);
        $display("\n--- Branch Instruction Tests ---");
        $display("x18 = %0d (expected: 0)", dut.decode_inst.rf.regfile[18]);
        $display("x19 = %0d (expected: 2)", dut.decode_inst.rf.regfile[19]);
        $display("x20 = %0d (expected: 0)", dut.decode_inst.rf.regfile[20]);
        $display("x21 = %0d (expected: 2)", dut.decode_inst.rf.regfile[21]);
        $display("x22 = %0d (expected: 0)", dut.decode_inst.rf.regfile[22]);
        $display("x23 = %0d (expected: 2)", dut.decode_inst.rf.regfile[23]);
        $display("x24 = %0d (expected: 0)", dut.decode_inst.rf.regfile[24]);
        $display("x25 = %0d (expected: 2)", dut.decode_inst.rf.regfile[25]);
        $display("x26 = %0d (expected: 0)", dut.decode_inst.rf.regfile[26]);
        $display("x27 = %0d (expected: 2)", dut.decode_inst.rf.regfile[27]);
        $display("==================================\n");
        
        // Check if test passed
        if (dut.decode_inst.rf.regfile[1] == 5 &&
            dut.decode_inst.rf.regfile[2] == 3 &&
            dut.decode_inst.rf.regfile[3] == 8 &&
            dut.decode_inst.rf.regfile[4] == 5 &&
            dut.decode_inst.rf.regfile[5] == 8 &&
            dut.decode_inst.rf.regfile[6] == 0 &&
            dut.decode_inst.rf.regfile[7] == 9 &&
            dut.memory_inst.dmem.mem[0] == 8 &&
            $signed(dut.decode_inst.rf.regfile[11]) == -120 &&
            dut.decode_inst.rf.regfile[12] == 32'd136 &&
            $signed(dut.decode_inst.rf.regfile[13]) == -30584 &&
            dut.decode_inst.rf.regfile[14] == 32'd34952 &&
            dut.decode_inst.rf.regfile[8] == 32'h00000022 &&
            dut.decode_inst.rf.regfile[9] == 32'h00004433 &&
            $signed(dut.decode_inst.rf.regfile[28]) == -128 &&
            dut.memory_inst.dmem.mem[2] == 32'h00030005 &&
            dut.decode_inst.rf.regfile[15] == 32'h00030005 &&
            dut.decode_inst.rf.regfile[10] == 160 &&
            dut.decode_inst.rf.regfile[30] == 172 &&
            dut.decode_inst.rf.regfile[31] == 4 &&
            dut.decode_inst.rf.regfile[18] == 0 &&
            dut.decode_inst.rf.regfile[19] == 2 &&
            dut.decode_inst.rf.regfile[20] == 0 &&
            dut.decode_inst.rf.regfile[21] == 2 &&
            dut.decode_inst.rf.regfile[22] == 0 &&
            dut.decode_inst.rf.regfile[23] == 2 &&
            dut.decode_inst.rf.regfile[24] == 0 &&
            dut.decode_inst.rf.regfile[25] == 2 &&
            dut.decode_inst.rf.regfile[26] == 0 &&
            dut.decode_inst.rf.regfile[27] == 2) begin
            $display("TEST PASSED!\n");
        end else begin
            $fatal(1, "TEST FAILED!");
        end
        
        $finish;
    end
    
endmodule
