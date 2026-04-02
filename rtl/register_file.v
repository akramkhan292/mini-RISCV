module register_file(
    input logic clk,
    input logic we,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [31:0] wd,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);

    logic [31:0] regfile [31:0];

    //for immidiate access of register file we used combinational/dataflow modelling.
    assign rd1 = regfile[rs1];
    assign rd2 = regfile[rs2];

    // since in write value is changing and output depends on state and input hence sequential unlike read.
    always_ff @(posedge clk) begin
        if(we && rd != 0)
            regfile[rd] <= wd;
    end

endmodule