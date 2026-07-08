# Verification Plan

## Goal

Verify the CPU at architectural state level: PC sequence, register writeback, memory writes, and instruction behavior for the supported RV32I subset.

## Testbench Strategy

- Directed smoke tests prove basic functionality with deterministic programs.
- UVM driver loads instruction memory while reset is asserted.
- UVM monitor samples committed instructions through the debug interface.
- UVM scoreboard maintains a reference model of registers, PC, and memory.
- Coverage tracks instruction types, function fields, register destinations, register writes, stores, and branches.
- Assertions check core invariants during simulation.

## Stage 1 Directed Scenarios

| Scenario | Purpose |
| --- | --- |
| Arithmetic smoke | ADDI, ADD, SUB dataflow |
| Logical ops | AND/OR decode and ALU control |
| x0 behavior | Writes to x0 do not change architectural state |
| Load semantics | LB/LH sign-extend, LBU/LHU zero-extend |
| Store granularity | SB/SH write bytes and halfwords into memory |
| Memory | SW followed by LW from same address |
| Branch taken | Conditional branch changes PC by branch immediate |
| Branch not taken | Conditional branch falls through to `pc + 4` |
| Sign extension | Negative I/S/B immediates |

## Scoreboard Checks

- Observed PC equals expected reference PC.
- Register write enable matches expected instruction behavior.
- Register writeback destination/data matches the reference model.
- Store address/data matches the reference model.
- Reference register `x0` is forced to zero after every instruction.

## Assertions

- PC is word-aligned.
- Store address is word-aligned.
- Reset returns execution to PC zero.
- x0 must not retain writes.

## Coverage Goals

- Hit every supported opcode.
- Hit every implemented ALU operation.
- Hit byte/halfword and word load/store behaviors.
- Hit signed and unsigned load variants.
- Hit branch instruction variants.
- Hit destination register bins: x0, low, mid, high.
- Hit both register-writing and non-register-writing instructions.
