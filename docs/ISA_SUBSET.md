# RV32I Subset Specification

This project implements a staged RV32I subset. An instruction is considered supported only after its RTL behavior, pipeline hazards, directed tests, UVM reference model, scoreboard, and coverage agree.

## Support Status

`Declared` is the project contract. `Qualification pending` means some RTL or directed-test plumbing exists, but the instruction is deliberately not claimed as supported yet.

| Group | Instructions | Status |
| --- | --- | --- |
| Register ALU | `ADD`, `SUB`, `AND`, `OR` | Declared |
| Immediate ALU | `ADDI` | Declared |
| Loads | `LB`, `LH`, `LW`, `LBU`, `LHU` | Declared |
| Stores | `SB`, `SH`, `SW` | Declared |
| Conditional branches | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | Declared |
| Additional register ALU | `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU` | Qualification pending |
| Additional immediate ALU | `XORI`, `ORI`, `ANDI`, `SLTI`, `SLTIU`, immediate shifts | Qualification pending |
| Jumps | `JAL`, `JALR` | Qualification pending |
| Upper immediate | `LUI`, `AUIPC` | Not implemented |
| System and standard extensions | CSR/system, RV32M/A/C/F | Out of scope |

Pipeline control includes an EX-stage redirect path for branch and jump operations. That microarchitectural path does not by itself qualify `JAL` or `JALR` as supported instructions.

## Declared Instruction Behavior

| Instruction | Type | opcode | funct3 | funct7 | Behavior |
| --- | --- | --- | --- | --- | --- |
| ADD | R | 0110011 | 000 | 0000000 | `rd = rs1 + rs2` |
| SUB | R | 0110011 | 000 | 0100000 | `rd = rs1 - rs2` |
| AND | R | 0110011 | 111 | 0000000 | `rd = rs1 & rs2` |
| OR | R | 0110011 | 110 | 0000000 | `rd = rs1 | rs2` |
| ADDI | I | 0010011 | 000 | n/a | `rd = rs1 + sext(imm[11:0])` |
| LW | I | 0000011 | 010 | n/a | `rd = mem32[rs1 + sext(imm)]` |
| LB | I | 0000011 | 000 | n/a | `rd = sext8(mem8[rs1 + sext(imm)])` |
| LH | I | 0000011 | 001 | n/a | `rd = sext16(mem16[rs1 + sext(imm)])` |
| LBU | I | 0000011 | 100 | n/a | `rd = zext8(mem8[rs1 + sext(imm)])` |
| LHU | I | 0000011 | 101 | n/a | `rd = zext16(mem16[rs1 + sext(imm)])` |
| SW | S | 0100011 | 010 | n/a | `mem32[rs1 + sext(imm)] = rs2` |
| SH | S | 0100011 | 001 | n/a | `mem16[rs1 + sext(imm)] = rs2[15:0]` |
| SB | S | 0100011 | 000 | n/a | `mem8[rs1 + sext(imm)] = rs2[7:0]` |
| BEQ | B | 1100011 | 000 | n/a | `if (rs1 == rs2) pc = pc + sext(branch_imm)` |
| BNE | B | 1100011 | 001 | n/a | `if (rs1 != rs2) pc = pc + sext(branch_imm)` |
| BLT | B | 1100011 | 100 | n/a | `if (signed(rs1) < signed(rs2)) pc = pc + sext(branch_imm)` |
| BGE | B | 1100011 | 101 | n/a | `if (signed(rs1) >= signed(rs2)) pc = pc + sext(branch_imm)` |
| BLTU | B | 1100011 | 110 | n/a | `if (rs1 < rs2) pc = pc + sext(branch_imm)` |
| BGEU | B | 1100011 | 111 | n/a | `if (rs1 >= rs2) pc = pc + sext(branch_imm)` |

## Encoding and Memory Notes

- I-type immediate: `instr[31:20]`.
- S-type immediate: `{instr[31:25], instr[11:7]}`.
- B-type immediate: `{instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}`.
- J-type immediate, used by the qualification-pending jump path: `{instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}`.
- `x0` always reads as zero. Writes, forwarding matches, and stalls for destination `x0` are suppressed.
- Instruction and data addresses are byte addresses. The internal memories select a word with `addr[9:2]`; subword accesses additionally select a byte or halfword using `addr[1:0]`.
- The declared memory model does not define misaligned or out-of-range access behavior and does not raise traps.
