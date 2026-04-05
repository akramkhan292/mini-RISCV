`include "driver.sv"
`include "monitor.sv"
`include "agent.sv"
`include "environment.sv"
`include "test.sv"

module tb_riscv;
  
  logic clk;
  logic reset;
  
  riscv_core dut(
    .clk(clk),
    .reset(reset)
  );
  
  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin
    reset = 0;
    repeat(2) @(posedge clk);
    reset = 1;
  end
  
  initial begin
    run_test("base_test");
  end
   
endmodule



