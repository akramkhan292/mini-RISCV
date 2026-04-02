# RISC-V Processor

A Verilog/SystemVerilog implementation of a simple 32-bit RISC-V processor.

## Overview

This project implements a basic RISC-V CPU core with the following features:
- **Instruction Set**: RV32I (32-bit RISC-V base integer instruction set)
- **Architecture**: 5-stage pipeline (Fetch, Decode, Execute, Memory, Writeback)
- **Register File**: 32 general-purpose registers (x0-x31)
- **Memory**: Separate instruction and data memory

---

## Project Structure

```
risc-v-processor/
├── rtl/                      # Register Transfer Level (HDL code)
│   ├── alu.v                 # Arithmetic Logic Unit
│   ├── control_unit.v        # Control signal decoder
│   ├── register_file.v       # 32x32-bit register file
│   ├── pc_rtl.v              # Program Counter
│   ├── mem.v                 # Memory modules
│   ├── inst_mem.v            # Instruction memory
│   ├── data_mem.v            # Data memory
│   ├── decoder.v             # Instruction decoder
│   └── cpu_top.v             # Top-level CPU module
│
├── tb/                       # Testbenches
│   ├── tb_alu.v
│   ├── tb_register_file.v
│   ├── tb_control_unit.v
│   └── tb_cpu_top.v
│
├── sim/                      # Simulation outputs
│   └── .gitkeep
│
├── docs/                     # Documentation
│   └── README.md
│
├── README.md                 # This file
├── .gitignore
└── Makefile                  # Build and simulation scripts
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
✓ Testbenches for verification  

---

## Getting Started

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

### Running Simulations

#### Using Makefile:
```bash
make sim
```

#### Manual simulation (Icarus Verilog):
```bash
vvp sim/cpu.vvp -vcd sim/waveform.vcd
```

#### View waveforms (gtkwave):
```bash
gtkwave sim/waveform.vcd
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
