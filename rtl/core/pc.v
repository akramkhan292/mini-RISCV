module pc (
    input wire clk,             // Clock signal - triggers PC updates
    input wire rst,             // Reset signal - force PC to 0
    input wire [31:0] next_pc,  // Next instruction address (from datapath)
    output reg [31:0] pc        // Current instruction address (to memory)
);

    always @(posedge clk or posedge rst) begin
        if(rst)
            pc <= 32'd0;    // Asynchronous reset
        else
            pc <= next_pc;  // Update PC on clock edge
    end

endmodule