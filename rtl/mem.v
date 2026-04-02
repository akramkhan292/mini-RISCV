module inst_mem(
    input wire [31:0] addr,
    output wire [31:0] instruction
);
    reg [31:0] mem [255:0];

    initial begin
        $readmemh("program.mem", mem);
    end

    // addr[9:2] converts byte address to word index
    assign instruction = mem[addr[9:2]];

endmodule