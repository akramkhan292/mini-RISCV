module data_mem(
    input wire clk,              // Clock for synchronous writes
    input wire mem_read,         // Read enable (from control unit)
    input wire mem_write,        // Write enable (from control unit)
    input wire [2:0] store_type, // Store type: 000=byte(SB), 001=halfword(SH), 010=word(SW)
    input wire [31:0] addr,      // Memory address (byte-addressed)
    input wire [31:0] data_in,   // Data to write (from registers)

    output wire [31:0] data_out  // Data read from memory (to registers)
);

    // 256 × 32-bit data memory
    reg [31:0] mem [255:0];

    // Combinational read: output 0 if not reading
    assign data_out = (mem_read) ? mem[addr[9:2]] : 32'd0;

    // Synchronous write: selective byte writes based on store_type
    always @(posedge clk) begin
        if (mem_write) begin
            case (store_type)
                3'b000: begin // SB - Store Byte
                    case (addr[1:0])
                        2'b00: mem[addr[9:2]][7:0]   <= data_in[7:0];    // Byte 0
                        2'b01: mem[addr[9:2]][15:8]  <= data_in[7:0];    // Byte 1
                        2'b10: mem[addr[9:2]][23:16] <= data_in[7:0];    // Byte 2
                        2'b11: mem[addr[9:2]][31:24] <= data_in[7:0];    // Byte 3
                    endcase
                end
                3'b001: begin // SH - Store Halfword
                    case (addr[1])
                        1'b0: mem[addr[9:2]][15:0]  <= data_in[15:0];   // Halfword 0
                        1'b1: mem[addr[9:2]][31:16] <= data_in[15:0];   // Halfword 1
                    endcase
                end
                3'b010: begin // SW - Store Word
                    mem[addr[9:2]] <= data_in;                           // Full 32-bit word
                end
            endcase
        end
    end

endmodule