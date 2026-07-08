# RV32I Subset Specification

This project implements a staged RV32I subset. Every instruction must be added to RTL, directed tests, UVM reference model, scoreboard checks, and coverage before it is considered complete.

## Stage 1 Instructions

| Instruction | Type | opcode | funct3 | funct7 | Behavior |
| --- | --- | --- | --- | --- | --- |
| ADD | R | 0110011 | 000 | 0000000 | `rd = rs1 + rs2` |
| SUB | R | 0110011 | 000 | 0100000 | `rd = rs1 - rs2` |
| AND | R | 0110011 | 111 | 0000000 | `rd = rs1 & rs2` |
| OR | R | 0110011 | 110 | 0000000 | `rd = rs1 | rs2` |
| ADDI | I | 0010011 | 000 | n/a | `rd = rs1 + sext(imm[11:0])` |
| LW | I | 0000011 | 010 | n/a | `rd = mem[rs1 + sext(imm)]` |
| SW | S | 0100011 | 010 | n/a | `mem[rs1 + sext(imm)] = rs2` |
| BEQ | B | 1100011 | 000 | n/a | `if (rs1 == rs2) pc = pc + sext(branch_imm)` |

## Encoding Notes

- I-type immediate: `instr[31:20]`.
- S-type immediate: `{instr[31:25], instr[11:7]}`.
- B-type immediate: `{instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}`.
- `x0` must always read as zero and must not retain writes.
- Instruction and data memories are word-addressed internally with byte-address inputs using `addr[9:2]`.

## Planned Expansion

1. ALU ops: `XOR`, `SLT`, `SLTU`, `SLL`, `SRL`, `SRA`.
2. Immediate ops: `ORI`, `ANDI`, `XORI`, shifts.
3. Control flow: `BNE`, `BLT`, `BGE`, `JAL`, `JALR`.
4. Upper immediate: `LUI`, `AUIPC`.
