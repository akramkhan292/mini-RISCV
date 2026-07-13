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
    // Hardwire x0 to zero on reads
    // WB-to-ID bypass is required because the WB write and ID/EX capture occur
    // on the same rising edge. Without it, ID would latch the pre-write value.
    assign rd1 = (rs1 == 5'b0) ? 32'b0 :
                 ((we && rd == rs1) ? wd : regfile[rs1]);
    assign rd2 = (rs2 == 5'b0) ? 32'b0 :
                 ((we && rd == rs2) ? wd : regfile[rs2]);

    // Synchronous write - sequential
    always @(posedge clk) begin
        if(we && rd != 0)  // Don't write to x0 (hardwired zero)
            regfile[rd] <= wd;
    end

endmodule
