module inst_mem(
    input wire clk,
    input wire [31:0] addr,
    output wire [31:0] instruction
    // Add programing Interface
    input wire [31:0] prog_addr,
    input wire [31:0] prog_data,
    input wire        prog_we
);
    reg [31:0] mem [255:0];

    always @(posedge clk) begin
        if(prog_we)
            mem[prog_addr] <= prog_data;
    end
    // addr[9:2] converts byte address to word index
    assign instruction = mem[addr[9:2]];

endmodule