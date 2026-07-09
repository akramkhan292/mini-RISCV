RTL := $(shell find rtl -type f -name '*.v' | sort)
SMOKE_TB := tb/tb_riscv_core.v
UVM_TOP := tb/riscv_uvmtb.sv

SIM_DIR := sim
SMOKE_OUT := $(SIM_DIR)/cpu.vvp

.PHONY: smoke uvm questa clean

$(SIM_DIR):
	mkdir -p $(SIM_DIR)

smoke: $(SIM_DIR)
	iverilog -o $(SMOKE_OUT) $(RTL) $(SMOKE_TB)
	vvp $(SMOKE_OUT)

uvm:
	@echo "Use 'make questa' for the UVM flow. Icarus Verilog does not provide UVM."

questa:
	vlib work
	vlog -sv +incdir+tb $(RTL) $(UVM_TOP)
	vsim -c tb_riscv +UVM_TESTNAME=riscv_smoke_test -do "run -all; quit"

clean:
	rm -rf $(SIM_DIR) work transcript *.wlf *.vcd logs coverage
