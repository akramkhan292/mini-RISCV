module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_ctrl,
    output reg [31:0] result,
    output wire zero 
);

localparam ADD = 4'b0000;
localparam SUB = 4'b0001;
localparam AND = 4'b0010;
localparam OR  = 4'b0011;

// Combinational logic: use blocking assignment (=) not non-blocking (<=)
// Blocking assignment ensures immediate evaluation (critical for combinational)
// Non-blocking (<=) would give stale values in combinational blocks

    always @(*) begin
        case (alu_ctrl)
            ADD: result = a + b;
            SUB: result = a - b;
            AND: result = a & b;
            OR: result = a | b; 
            default: result = 0;
        endcase
    end

    assign zero = (result == 0);
    
endmodule