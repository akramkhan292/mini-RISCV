module control_unit(
    input wire [6:0] opcode,
    input wire [2:0] func3,
    input wire [6:0] func7,

    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg [2:0] store_type,  // Store type: 000=SB, 001=SH, 010=SW
    output reg alu_src,
    output reg branch,
    output reg [2:0] branch_type,
    output reg [3:0] alu_ctrl,
    output reg jump,
    output reg jalr,
    output reg instr_valid
);
    localparam R_TYPE = 7'b0110011;    // Register-Register
    localparam I_TYPE = 7'b0010011;    // Immediate
    localparam LOAD   = 7'b0000011;    // Load
    localparam STORE  = 7'b0100011;    // Store
    localparam BRANCH = 7'b1100011;    // Branch
    localparam JAL    = 7'b1101111;    // JAL
    localparam JALR   = 7'b1100111;    // JALR

    always @(*) begin
        // Default: prevent latches
        reg_write = 0;
        mem_read = 0;
        mem_write = 0;
        store_type = 3'b010;  // Default to SW
        branch_type = 3'b000; // Default no branch
        jump = 0;
        jalr = 0;
        instr_valid = 0;
        alu_src = 0;
        branch = 0;
        alu_ctrl = 4'b0000;

        case (opcode)
            R_TYPE: begin
                case({func7, func3})
                    {7'b0000000, 3'b000}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0000; end // ADD
                    {7'b0100000, 3'b000}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0001; end // SUB
                    {7'b0000000, 3'b111}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0010; end // AND
                    {7'b0000000, 3'b110}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0011; end // OR
                    {7'b0000000, 3'b001}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0101; end // SLL
                    {7'b0000000, 3'b010}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b1000; end // SLT
                    {7'b0000000, 3'b011}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b1001; end // SLTU
                    {7'b0000000, 3'b100}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0100; end // XOR
                    {7'b0000000, 3'b101}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0110; end // SRL
                    {7'b0100000, 3'b101}: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0111; end // SRA
                endcase
            end
            I_TYPE: begin
                alu_src = 1;
                case (func3)
                    3'b000: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0000; end // ADDI
                    3'b010: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b1000; end // SLTI
                    3'b011: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b1001; end // SLTIU
                    3'b100: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0100; end // XORI
                    3'b110: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0011; end // ORI
                    3'b111: begin instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0010; end // ANDI
                    3'b001: begin
                        if (func7 == 7'b0000000) begin
                            instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0101; // SLLI
                        end
                    end
                    3'b101: begin
                        if (func7 == 7'b0000000) begin
                            instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0110; // SRLI
                        end else if (func7 == 7'b0100000) begin
                            instr_valid = 1; reg_write = 1; alu_ctrl = 4'b0111; // SRAI
                        end
                    end
                endcase
            end
            LOAD: begin
                alu_src = 1;
                alu_ctrl = 4'b0000;
                case (func3)
                    3'b000, // LB
                    3'b001, // LH
                    3'b010, // LW
                    3'b100, // LBU
                    3'b101: begin // LHU
                        instr_valid = 1;
                        reg_write = 1;
                        mem_read = 1;
                    end
                endcase
            end
            STORE: begin
                alu_src = 1;
                alu_ctrl = 4'b0000;
                case (func3)
                    3'b000: begin // SB (Store Byte)
                        instr_valid = 1;
                        mem_write = 1;
                        store_type = 3'b000;
                    end
                    3'b001: begin // SH (Store Halfword)
                        instr_valid = 1;
                        mem_write = 1;
                        store_type = 3'b001;
                    end
                    3'b010: begin // SW (Store Word)
                        instr_valid = 1;
                        mem_write = 1;
                        store_type = 3'b010;
                    end
                endcase
            end
            BRANCH: begin
                case (func3)
                    3'b000: begin // BEQ
                        instr_valid = 1;
                        branch = 1;
                        branch_type = 3'b000;
                        alu_ctrl = 4'b0001; // SUB
                    end
                    3'b001: begin // BNE
                        instr_valid = 1;
                        branch = 1;
                        branch_type = 3'b001;
                        alu_ctrl = 4'b0001; // SUB
                    end
                    3'b100: begin // BLT
                        instr_valid = 1;
                        branch = 1;
                        branch_type = 3'b010;
                        alu_ctrl = 4'b1000; // SLT
                    end
                    3'b101: begin // BGE
                        instr_valid = 1;
                        branch = 1;
                        branch_type = 3'b011;
                        alu_ctrl = 4'b1000; // SLT
                    end
                    3'b110: begin // BLTU
                        instr_valid = 1;
                        branch = 1;
                        branch_type = 3'b100;
                        alu_ctrl = 4'b1001; // SLTU
                    end
                    3'b111: begin // BGEU
                        instr_valid = 1;
                        branch = 1;
                        branch_type = 3'b101;
                        alu_ctrl = 4'b1001; // SLTU
                    end
                endcase
            end
            JAL: begin
                instr_valid = 1;
                reg_write = 1;
                jump = 1;
                alu_ctrl = 4'b1111;
            end
            JALR: begin
                alu_src = 1;
                alu_ctrl = 4'b0000; // ADD rs1 + imm
                if (func3 == 3'b000) begin
                    instr_valid = 1;
                    reg_write = 1;
                    jump = 1;
                    jalr = 1;
                end
            end
        endcase
    end

endmodule
