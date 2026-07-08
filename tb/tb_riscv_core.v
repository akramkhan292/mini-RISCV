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
        
        dut.imem.mem[0] = 32'h00500093;  // addi x1, x0, 5
        dut.imem.mem[1] = 32'h00300113;  // addi x2, x0, 3
        dut.imem.mem[2] = 32'h002081b3;  // add  x3, x1, x2
      	dut.imem.mem[3] = 32'h40218233;  // sub  x4, x3, x2
        dut.imem.mem[4] = 32'h00302023;  // sw   x3, 0(x0)
        dut.imem.mem[5] = 32'h00002283;  // lw   x5, 0(x0)
        dut.imem.mem[6] = 32'h00328463;  // beq  x5, x3, +8
        dut.imem.mem[7] = 32'h00100313;  // addi x6, x0, 1 (skipped)
        dut.imem.mem[8] = 32'h00900393;  // addi x7, x0, 9
        
        // Apply reset
        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;
        
        // Run for enough cycles
        repeat (14) @(posedge clk);
        
        // Display results
        $display("\n========== Test Results ==========");
        $display("x1 = %0d (expected: 5)", dut.rf.regfile[1]);
        $display("x2 = %0d (expected: 3)", dut.rf.regfile[2]);
        $display("x3 = %0d (expected: 8)", dut.rf.regfile[3]);
        $display("x4 = %0d (expected: 5)", dut.rf.regfile[4]);
        $display("x5 = %0d (expected: 8)", dut.rf.regfile[5]);
        $display("x7 = %0d (expected: 9)", dut.rf.regfile[7]);
        $display("mem[0] = %0d (expected: 8)", dut.dmem.mem[0]);
        $display("==================================\n");
        
        // Check if test passed
        if (dut.rf.regfile[1] == 5 &&
            dut.rf.regfile[2] == 3 &&
            dut.rf.regfile[3] == 8 &&
            dut.rf.regfile[4] == 5 &&
            dut.rf.regfile[5] == 8 &&
            dut.rf.regfile[7] == 9 &&
            dut.dmem.mem[0] == 8) begin
            $display("TEST PASSED!\n");
        end else begin
            $display("TEST FAILED!\n");
        end
        
        $finish;
    end
    
endmodule
