# Single-Cycle Micro-Architecture

## Architecture

The current CPU is a single-cycle RV32I-subset core. Each instruction is fetched, decoded, executed, and committed through one combinational datapath between clock edges.

```text
PC -> Instruction Memory -> Decode/Control -> Register File
   -> Immediate Generator -> ALU -> Data Memory -> Writeback
   -> Branch/PC Update
```

## Main Blocks

- `pc`: holds the current byte-addressed program counter.
- `inst_mem`: 256-word instruction memory with a programming port for testbench loading.
- `control_unit`: decodes opcode/funct fields into register, memory, branch, and ALU controls.
- `imm_gen`: generates sign-extended I/S/B immediates.
- `register_file`: 32 x 32-bit register file, two async reads, one sync write, hardwired `x0`.
- `alu`: executes ADD, SUB, AND, OR.
- `data_mem`: 256-word data memory with async read and sync write.
- `riscv_core`: top-level datapath integration and debug/commit interface.

## Verification Interface

The top-level core exposes debug outputs for testbench use:

- `dbg_pc`, `dbg_instr`
- `dbg_reg_write`, `dbg_rd`, `dbg_writeback_data`
- `dbg_mem_write`, `dbg_mem_addr`, `dbg_mem_wdata`
- `dbg_commit_valid`

These signals are not part of a production bus interface. They exist to make the single-cycle core observable for directed tests, assertions, coverage, and UVM scoreboard checks.

## Current Limitations

- No pipeline.
- No hazard handling because only one instruction is active at a time.
- No illegal instruction trap.
- No byte/halfword memory accesses.
- No external instruction/data bus protocol.
