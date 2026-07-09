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
localparam XOR = 4'b0100;
localparam SLL = 4'b0101;
localparam SRL = 4'b0110;
localparam SRA = 4'b0111;
localparam SLT = 4'b1000;
localparam SLTU = 4'b1001;

// Combinational logic: use blocking assignment (=) not non-blocking (<=)
// Blocking assignment ensures immediate evaluation (critical for combinational)
// Non-blocking (<=) would give stale values in combinational blocks

    always @(*) begin
        case (alu_ctrl)
            ADD: result = a + b;
            SUB: result = a - b;
            AND: result = a & b;
            OR: result = a | b; 
            XOR: result = a ^ b;
            SLL: result = a << b;
            SRL: result = a >> b;
            SRA: result = $signed(a) >>> b;
            SLT: result = ($signed(a)<$signed(b)) ? 32'd1 : 32'd0;
            SLTU: result = (a<b) ? 32'd1 : 32'd0;
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);
    
endmodule
