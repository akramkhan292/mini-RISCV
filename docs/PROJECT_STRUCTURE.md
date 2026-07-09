# Project Structure

This repository is organized to separate the CPU datapath, memory models, testbench, and documentation.

## Directory layout

- `rtl/core/`
  - Core processor RTL, including instruction decode, ALU, register file, and PC logic.
- `rtl/memory/`
  - Instruction and data memory modules with byte/halfword store support.
- `tb/`
  - Smoke testbench and UVM verification components.
- `docs/`
  - Design notes, ISA subset documentation, verification plan, and project structure.
- `sim/`
  - Simulation build artifacts and outputs.

## RTL subdirectories

### `rtl/core/`
- `riscv_core.v` — top-level single-cycle RISC-V datapath that composes the fetch, decode, execute, and memory stages.
- `fetch_stage.v` — PC state and instruction fetch from `inst_mem`.
- `decode_stage.v` — instruction field extraction, register file read/write, and immediate generation.
- `execute_stage.v` — ALU operation, branch decision, jump/JALR target generation, and next-PC selection.
- `memory_stage.v` — data memory access plus load data byte/halfword extraction and sign/zero extension.
- `control_unit.v` — opcode and funct3 decode for ALU, memory, branch, and jump control.
- `alu.v` — arithmetic and logic operations.
- `register_file.v` — 32-register file with read/write ports.
- `imm_gen.v` — immediate generation for I, S, B, J, and U formats.
- `pc.v` — program counter state and update logic.

### `rtl/memory/`
- `inst_mem.v` — instruction memory with program-loading interface.
- `data_mem.v` — data memory with word, halfword, and byte stores.

## Testbench

- `tb/tb_riscv_core.v` — directed smoke test for core instruction behavior.
- `tb/` also contains UVM testbench sources for higher-fidelity verification.

## Build

- `Makefile` uses `find rtl -type f -name '*.v' | sort` so RTL module files can be reorganized without changing the build command.
- `make smoke` builds and runs the Icarus smoke test.

## Why this structure?

- Clear separation of core versus memory allows easier scaling to a pipelined design.
- Explicit directories make it easier to add new modules like `rtl/peripherals/` or `rtl/csr/` later.
- Documentation now matches the physical layout of source files.
