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
        
        dut.imem.mem[0] = 32'h00500093;  // addi x1, x0, 5
        dut.imem.mem[1] = 32'h00300113;  // addi x2, x0, 3
        dut.imem.mem[2] = 32'h002081b3;  // add  x3, x1, x2
      	dut.imem.mem[3] = 32'h40218233;  // sub  x4, x3, x2
        dut.imem.mem[4] = 32'h00302023;  // sw   x3, 0(x0)
        dut.imem.mem[5] = 32'h00002283;  // lw   x5, 0(x0)
        dut.imem.mem[6] = 32'h00328463;  // beq  x5, x3, +8
        dut.imem.mem[7] = 32'h00100313;  // addi x6, x0, 1 (skipped)
        dut.imem.mem[8] = 32'h00900393;  // addi x7, x0, 9
        dut.imem.mem[9] = 32'h00400583;  // lb   x11, 4(x0)   -> sign-extend byte
        dut.imem.mem[10] = 32'h00404603; // lbu  x12, 4(x0)   -> zero-extend byte
        dut.imem.mem[11] = 32'h00401683; // lh   x13, 4(x0)   -> sign-extend halfword
        dut.imem.mem[12] = 32'h00405703; // lhu  x14, 4(x0)   -> zero-extend halfword
        dut.imem.mem[13] = 32'h00100423; // sb   x1, 8(x0)    -> store byte 5 to mem[2][7:0]
        dut.imem.mem[14] = 32'h00201523; // sh   x2, 10(x0)   -> store halfword 3 to mem[2][31:16]
        dut.imem.mem[15] = 32'h00802783; // lw   x15, 8(x0)   -> load mem[2] back to verify
        
        // Pre-initialize data memory with test value for load instruction testing
        dut.dmem.mem[1] = 32'h00008888;  // Test value for LB, LBU, LH, LHU instructions
        dut.dmem.mem[2] = 32'h00000000;  // Initialize mem[2] for store instruction testing
        
        // Apply reset
        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;
        
        // Run for enough cycles (16 instructions, ~22-24 cycles)
        repeat (26) @(posedge clk);
        
        // Display results
        $display("\n========== Test Results ==========");
        $display("x1 = %0d (expected: 5)", dut.rf.regfile[1]);
        $display("x2 = %0d (expected: 3)", dut.rf.regfile[2]);
        $display("x3 = %0d (expected: 8)", dut.rf.regfile[3]);
        $display("x4 = %0d (expected: 5)", dut.rf.regfile[4]);
        $display("x5 = %0d (expected: 8)", dut.rf.regfile[5]);
        $display("x7 = %0d (expected: 9)", dut.rf.regfile[7]);
        $display("mem[0] = %0d (expected: 8)", dut.dmem.mem[0]);
        $display("\n--- Load Instruction Tests ---");
        $display("x11 (LB  0x88) = %d (expected: -120)", $signed(dut.rf.regfile[11][7:0]));
        $display("x12 (LBU 0x88) = %0d (expected: 136)", dut.rf.regfile[12][7:0]);
        $display("x13 (LH  0x8888) = %d (expected: -30584)", $signed(dut.rf.regfile[13][15:0]));
        $display("x14 (LHU 0x8888) = %0d (expected: 34952)", dut.rf.regfile[14][15:0]);
        $display("\n--- Store Instruction Tests ---");
        $display("mem[2] (SB + SH) = 0x%08x (expected: 0x00030005)", dut.dmem.mem[2]);
        $display("x15 (LW mem[2]) = 0x%08x (expected: 0x00030005)", dut.rf.regfile[15]);
        $display("==================================\n");
        
        // Check if test passed
        if (dut.rf.regfile[1] == 5 &&
            dut.rf.regfile[2] == 3 &&
            dut.rf.regfile[3] == 8 &&
            dut.rf.regfile[4] == 5 &&
            dut.rf.regfile[5] == 8 &&
            dut.rf.regfile[7] == 9 &&
            dut.dmem.mem[0] == 8 &&
            $signed(dut.rf.regfile[11]) == -120 &&
            dut.rf.regfile[12][7:0] == 136 &&
            $signed(dut.rf.regfile[13]) == -30584 &&
            dut.rf.regfile[14][15:0] == 34952 &&
            dut.dmem.mem[2] == 32'h00030005 &&
            dut.rf.regfile[15] == 32'h00030005) begin
            $display("TEST PASSED!\n");
        end else begin
            $display("TEST FAILED!\n");
        end
        
        $finish;
    end
    
endmodule
