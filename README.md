# RISC-V Single-Cycle Core with UVM Verification

This repository is a staged learning and portfolio project for industry-style CPU design and verification. The current design is a single-cycle RV32I-subset core with directed tests, debug/commit visibility, and a growing UVM environment.

## Current RTL Scope

Implemented instructions:

- R-type: `ADD`, `SUB`, `AND`, `OR`
- I-type: `ADDI`, `LW`, `LB`, `LH`, `LBU`, `LHU`
- S-type: `SW`, `SB`, `SH`
- B-type: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`

See [docs/ISA_SUBSET.md](docs/ISA_SUBSET.md) for encoding and behavior.

## Project Structure

```text
rtl/core/         synthesizable CPU blocks and core datapath
rtl/memory/       instruction and data memory modules
tb/               smoke testbench and UVM components
docs/             ISA, micro-architecture, verification, debug notes
Makefile          local smoke and Questa commands
```

`rtl/core/` now uses a stage-oriented core decomposition:
- `riscv_core.v` assembles fetch, decode, execute, and memory stage modules.
- `fetch_stage.v` handles PC and instruction fetch.
- `decode_stage.v` handles register file reads/writes and immediate decode.
- `execute_stage.v` handles ALU operations, branch/jump decisions, and next-PC.
- `memory_stage.v` handles data memory access and load sign/zero extension.

Key docs:

- [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)
- [docs/MICRO_ARCH.md](docs/MICRO_ARCH.md)
- [docs/VERIFICATION_PLAN.md](docs/VERIFICATION_PLAN.md)
- [docs/DEBUG_GUIDE.md](docs/DEBUG_GUIDE.md)
- [docs/DESIGN_JOURNEY.md](docs/DESIGN_JOURNEY.md)

## Run

Directed smoke test with Icarus:

```sh
make smoke
```

UVM flow with Questa/ModelSim:

```sh
make questa
```

Icarus Verilog does not provide a full UVM library, so it is used only for the smoke test.

## Development Rule

An instruction is complete only when all of these are updated:

- ISA documentation
- RTL decode/execute path
- directed test
- UVM reference model/scoreboard
- functional coverage
