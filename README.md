# RV32I Five-Stage Pipeline Core with UVM Verification

This repository is a staged learning and portfolio project for industry-style CPU design and verification. The core is an in-order, single-issue, five-stage `IF/ID/EX/MEM/WB` pipeline with directed tests, a retirement/debug interface, and a growing UVM environment.

## Pipeline Overview

```text
IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
```

- IF fetches at the current PC and normally selects `if_pc + 4` for the next fetch.
- ID decodes the instruction, reads the register file, and generates immediates and control.
- EX applies EX/MEM and MEM/WB forwarding, performs the ALU operation, and resolves branches and jumps.
- MEM performs the data-memory access.
- WB selects the ALU, load, or link value and writes the `rd` carried in the MEM/WB register.
- A WB-to-ID bypass supplies a value written and read in the same cycle.
- A load followed immediately by a dependent instruction inserts one bubble while holding PC and IF/ID.
- A taken branch or jump redirects fetch from EX and flushes the younger IF/ID and ID/EX entries.
- Valid, PC, instruction, destination, and side-effect metadata travel together so the debug interface describes one coherent retiring instruction.

See [docs/MICRO_ARCH.md](docs/MICRO_ARCH.md) for the forwarding, stall, flush, writeback, and retirement rules.

## Declared ISA Scope

The currently declared subset is:

- R-type: `ADD`, `SUB`, `AND`, `OR`
- I-type: `ADDI`
- Loads: `LW`, `LB`, `LH`, `LBU`, `LHU`
- Stores: `SW`, `SB`, `SH`
- Branches: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`

Additional ALU operations and `JAL`/`JALR` have RTL paths or directed stimulus, but are not claimed as qualified until the directed and UVM checks agree. See [docs/ISA_SUBSET.md](docs/ISA_SUBSET.md) for the support matrix.

## Project Structure

```text
rtl/core/         pipeline stages, pipeline registers, control, and datapath
rtl/memory/       instruction and data memory models
tb/               directed smoke test and UVM components
docs/             ISA, microarchitecture, verification, and debug notes
Makefile          directed regressions and Questa commands
```

Key RTL blocks:

- `rtl/core/riscv_core.v` integrates the five stages and pipeline control.
- `rtl/core/pipeline_regs.v` holds the IF/ID, ID/EX, EX/MEM, and MEM/WB state.
- `rtl/core/fetch_stage.v`, `decode_stage.v`, `execute_stage.v`, and `memory_stage.v` contain the stage logic.
- `rtl/core/register_file.v`, `control_unit.v`, `imm_gen.v`, and `alu.v` provide shared datapath functions.

Key documents:

- [docs/PIPELINE_BLOCK_DIAGRAM.md](docs/PIPELINE_BLOCK_DIAGRAM.md)
- [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)
- [docs/MICRO_ARCH.md](docs/MICRO_ARCH.md)
- [docs/ISA_SUBSET.md](docs/ISA_SUBSET.md)
- [docs/VERIFICATION_PLAN.md](docs/VERIFICATION_PLAN.md)
- [docs/DEBUG_GUIDE.md](docs/DEBUG_GUIDE.md)
- [docs/DESIGN_JOURNEY.md](docs/DESIGN_JOURNEY.md)

## Run

Run both Icarus directed regressions:

```sh
make test
```

Run either test independently:

```sh
make smoke
make pipeline
```

UVM flow with Questa/ModelSim:

```sh
make questa
```

Icarus Verilog does not provide a full UVM library, so it is used for the directed smoke and pipeline-hazard tests.

## Development Rule

An instruction is complete only when all of these agree:

- ISA documentation
- RTL decode and datapath behavior
- pipeline hazard and control-flow behavior
- directed tests
- UVM reference model and scoreboard
- functional coverage
