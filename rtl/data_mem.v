module data_mem(
    input wire clk,              // Clock for synchronous writes
    input wire mem_read,         // Read enable (from control unit)
    input wire mem_write,        // Write enable (from control unit)
    input wire [31:0] addr,      // Memory address (byte-addressed)
    input wire [31:0] data_in,   // Data to write (from ALU or registers)

    output wire [31:0] data_out  // Data read from memory (to registers)
);

    // 256 × 32-bit data memory
    reg [31:0] mem [255:0];

    // Combinational read: output 0 if not reading
    assign data_out = (mem_read) ? mem[addr[9:2]] : 32'd0;

    // Synchronous write: only write on clock edge
    always @(posedge clk) begin
        if (mem_write)
            mem[addr[9:2]] <= data_in;
    end

endmodule