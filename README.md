# RISC-V Processor with UVM Testbench

A Verilog/SystemVerilog implementation of a simple 32-bit RISC-V processor with comprehensive UVM testbench for verification.

## Overview

This project implements a basic RISC-V CPU core with the following features:
- **Instruction Set**: RV32I (32-bit RISC-V base integer instruction set)
- **Architecture**: Single-cycle (non-pipelined)
- **Register File**: 32 general-purpose registers (x0-x31)
- **Memory**: Separate instruction and data memory (Harvard architecture)
- **Verification**: UVM-based testbench with Sequence/Sequencer/Driver/Monitor

---

## Project Structure

```
risc-v/
├── rtl/                          # RTL Design (Hardware)
│   ├── alu.v                     # Arithmetic Logic Unit
│   ├── control_unit.v            # Instruction Decoder
│   ├── register_file.v           # 32x32-bit Register File
│   ├── pc_rtl.v                  # Program Counter
│   ├── mem.v                     # Instruction Memory
│   ├── data_mem.v                # Data Memory
│   ├── riscv_core.v              # Top-level CPU Core
│   └── *_rtl.v                   # Additional modules
│
├── tb/                           # UVM Testbench
│   ├── interface.sv              # Virtual Interface
│   ├── sequence_item.sv          # Transaction Class
│   ├── sequence.sv               # Stimulus Generator
│   ├── driver.sv                 # DUT Driver
│   ├── monitor.sv                # Output Monitor
│   ├── agent.sv                  # Agent (connects components)
│   ├── environment.sv            # Test Environment
│   ├── riscv_test.sv             # Base Test
│   ├── riscv_uvmtb.sv            # Top-level TB
│   └── tb_riscv_core.v           # Verilog Testbench (legacy)
│
├── sim/                          # Simulation Outputs
│   ├── cpu.vvp                   # Compiled simulation
│   └── waveform.vcd              # Waveform dump
│
├── docs/                         # Documentation
│   ├── INTERVIEW_GUIDE.md        # UVM & Architecture Interview Q&A
│   └── README.md                 # This file
│
├── .gitignore
├── README.md                     # Project overview
└── program.mem                   # Sample program (hex)
```

---

## Components

### 1. **ALU (Arithmetic Logic Unit)**
- **File**: `rtl/alu.v`
- **Operations**: Add, Subtract, AND, OR
- **Interface**: 
  - Inputs: 32-bit operands (a, b) + 4-bit control
  - Outputs: 32-bit result + zero flag

### 2. **Register File**
- **File**: `rtl/register_file.v`
- **Capacity**: 32 registers × 32 bits each
- **Read Ports**: 2 (rs1, rs2)
- **Write Port**: 1 (rd with write_enable)

### 3. **Program Counter**
- **File**: `rtl/pc_rtl.v`
- **Width**: 32 bits
- **Features**: Reset, next_pc input, synchronous update

### 4. **Control Unit**
- **File**: `rtl/control_unit.v`
- **Function**: Decodes opcode and generates control signals
- **Supported Instructions**:
  - R-type (add, sub, and, or)
  - I-type (load instructions)
  - S-type (store instructions)

### 5. **Memory**
- **Instruction Memory** (`rtl/inst_mem.v`): Stores program instructions
- **Data Memory** (`rtl/data_mem.v`): Stores program data

---

## Features

✓ 32-bit data width  
✓ 32 general-purpose registers  
✓ Basic arithmetic operations (add, subtract)  
✓ Logic operations (AND, OR)  
✓ Memory read/write support  
✓ Control signal generation  
✓ Testbenches for verification  ## UVM Testbench Architecture

### Core Components

| Component | File | Purpose |
|-----------|------|---------|
| **Interface** | `interface.sv` | Virtual interface connecting testbench to DUT |
| **Sequence Item** | `sequence_item.sv` | Transaction class (instr_item) |
| **Sequence** | `sequence.sv` | Generates random instruction sequences |
| **Sequencer** | Built-in UVM | Distributes transactions to driver |
| **Driver** | `driver.sv` | Applies transactions to DUT via interface |
| **Monitor** | `monitor.sv` | Observes DUT outputs and captures transactions |
| **Agent** | `agent.sv` | Connects sequencer, driver, and monitor |
| **Environment** | `environment.sv` | Container for agent |
| **Test** | `riscv_test.sv` | Orchestrates simulation and starts sequences |
| **Top-level TB** | `riscv_uvmtb.sv` | Instantiates DUT + UVM components |

### Testbench Flow

```
┌─────────────────────────────────────────────────────┐
│  test (base_test)                                   │
│  - Raises objection                                 │
│  - Creates and starts sequence on sequencer         │
│  - Drops objection when done                        │
└────────────────┬────────────────────────────────────┘
                 │
         ┌───────▼──────────┐
         │  environment     │
         │  (riscv_env)     │
         └────────┬─────────┘
                  │
         ┌────────▼────────┐
         │ agent           │
         │ (riscv_agent)   │
         └────────┬────────┘
                  │
        ┌─────────┼─────────┐
        │         │         │
   ┌────▼──┐ ┌───▼──┐ ┌───▼────┐
   │Driver │ │Seqr  │ │Monitor  │
   │       │ │      │ │         │
   │Drives │◄┤Feeds │ │Captures │
   │DUT    │ │Items │ │Output   │
   └───────┘ └──────┘ └─────────┘
```

### Key Phases

```
1. BUILD_PHASE
   └─ Create sequencer, driver, monitor
   └─ Get virtual interface from config_db
   
2. CONNECT_PHASE
   └─ Connect driver.seq_item_port ◄► sequencer.seq_item_export
   └─ Monitor ready to capture
   
3. RUN_PHASE
   └─ Sequence starts: generates 5 random instructions
   └─ Each instruction:
      • Randomized (opcode, rd, rs1, rs2, funct3, funct7, imm)
      • Passed to driver
      • Driver encodes and writes to program memory sequentially
      • Monitor observes write and captures transaction
```

---

### Prerequisites
- Verilog/SystemVerilog simulator (e.g., ModelSim, Icarus Verilog, VCS)
- Make (optional, for using Makefile)

### Building

#### Using Makefile (if available):
```bash
make build
```

#### Manual compilation (Icarus Verilog):
```bash
iverilog -o sim/cpu.vvp rtl/*.v tb/tb_cpu_top.v
```

### UVM Testbench Compilation & Simulation

```bash
# Compile RTL + UVM testbench
iverilog -o sim/cpu.vvp rtl/*.v tb/*.sv

# Run UVM simulation
vvp sim/cpu.vvp -vcd sim/waveform.vcd

# View waveforms
gtkwave sim/waveform.vcd
```

### Manual RTL Testbench (Legacy)

```bash
# Compile and run
iverilog -o sim/cpu.vvp rtl/*.v tb/tb_riscv_core.v
vvp sim/cpu.vvp
```

---

## Testing

### Run Component Tests
```bash
# Test ALU
iverilog -o sim/alu.vvp rtl/alu.v tb/tb_alu.v
vvp sim/alu.vvp

# Test Register File
iverilog -o sim/regfile.vvp rtl/register_file.v tb/tb_register_file.v
vvp sim/regfile.vvp
```

### Run Full System Test
```bash
# UVM testbench
iverilog -o sim/cpu.vvp rtl/*.v tb/*.sv
vvp sim/cpu.vvp

# Check test results in console output
# Look for "TB PASS" or "TB FAIL"
```

---

## Instruction Format

### R-Type (Register-Register)
```
[31:25] [24:20] [19:15] [14:12] [11:7] [6:0]
  func7   rs2    rs1   func3    rd   opcode
```

### I-Type (Immediate)
```
[31:20]     [19:15] [14:12] [11:7] [6:0]
immediate     rs1   func3    rd    opcode
```

### S-Type (Store)
```
[31:25] [24:20] [19:15] [14:12] [11:7] [6:0]
offset[11:5] rs2    rs1   func3 offset[4:0] opcode
```

---

## Register Naming Convention

| Register | ABI Name | Purpose |
|----------|----------|---------|
| x0 | zero | Hard-wired zero |
| x1 | ra | Return address |
| x2 | sp | Stack pointer |
| x5 | t0 | Temporary |
| x10-x11 | a0-a1 | Function arguments |

---

## Testing

Run individual component tests:
```bash
# Test ALU
iverilog -o sim/alu.vvp rtl/alu.v tb/tb_alu.v
vvp sim/alu.vvp

# Test Register File
iverilog -o sim/regfile.vvp rtl/register_file.v tb/tb_register_file.v
vvp sim/regfile.vvp
```

---

## Future Enhancements

- [ ] Full 5-stage pipeline implementation
- [ ] Branch prediction
- [ ] Cache hierarchy
- [ ] Floating-point units (RV32F)
- [ ] Exception handling
- [ ] More instruction types (M, A extensions)

---

## References

- [RISC-V Official Specification](https://riscv.org/specifications/)
- [RISC-V Reader](https://riscv.org/technical/specifications/)
- [Computer Organization and Design (Patterson & Hennessy)](https://www.elsevier.com/books/computer-organization-and-design-mips-edition/patterson/978-0-124-07726-9)

---

## License

This project is open source. Use freely for educational purposes.

---

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Test your changes
2. Document your modifications
3. Submit a pull request with clear description

---

**Last Updated**: April 2, 2026
