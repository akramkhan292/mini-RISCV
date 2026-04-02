`timescale 1ns/1ps

module tb_riscv_core;

    logic clk;
    logic reset;

    riscv_core dut (
        .clk(clk),
        .reset(reset)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Program:
        // addi x1, x0, 5
        // addi x2, x0, 3
        // add  x3, x1, x2
        dut.imem.mem[0] = 32'h00500093;
        dut.imem.mem[1] = 32'h00300113;
        dut.imem.mem[2] = 32'h002081b3;

        reset = 1'b1;
        #12;
        reset = 1'b0;

        repeat (10) @(posedge clk);

        $display("x1=%0d x2=%0d x3=%0d", dut.rf.regfile[1], dut.rf.regfile[2], dut.rf.regfile[3]);

        if ((dut.rf.regfile[1] === 32'd5) &&
            (dut.rf.regfile[2] === 32'd3) &&
            (dut.rf.regfile[3] === 32'd8))
            $display("TB PASS");
        else
            $display("TB FAIL");

        $finish;
    end

endmodule
