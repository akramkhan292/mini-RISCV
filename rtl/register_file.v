module register_file(
    input wire clk,
    input wire we,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    input wire [4:0] rd,
    input wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    // 32 × 32-bit register array
    reg [31:0] regfile [31:0];

    // Asynchronous read - combinational
    assign rd1 = regfile[rs1];
    assign rd2 = regfile[rs2];

    // Synchronous write - sequential
    always @(posedge clk) begin
        if(we && rd != 0)  // Don't write to x0 (hardwired zero)
            regfile[rd] <= wd;
    end

endmodule