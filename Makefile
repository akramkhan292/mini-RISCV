RTL := $(shell find rtl -type f -name '*.v' | sort)
SMOKE_TB := tb/tb_riscv_core.v
PIPELINE_TB := tb/tb_pipeline_hazards.v
UVM_TOP := tb/riscv_uvmtb.sv

BUILD_DIR := build
SMOKE_OUT := $(BUILD_DIR)/smoke.vvp
PIPELINE_OUT := $(BUILD_DIR)/pipeline_hazards.vvp
IVERILOG_FLAGS := -g2012 -Wall -Wno-timescale

.PHONY: test smoke pipeline uvm questa clean

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

test: smoke pipeline

smoke: $(BUILD_DIR)
	iverilog $(IVERILOG_FLAGS) -s tb_riscv_core -o $(SMOKE_OUT) $(RTL) $(SMOKE_TB)
	cd $(BUILD_DIR) && vvp smoke.vvp

pipeline: $(BUILD_DIR)
	iverilog $(IVERILOG_FLAGS) -s tb_pipeline_hazards -o $(PIPELINE_OUT) $(RTL) $(PIPELINE_TB)
	cd $(BUILD_DIR) && vvp pipeline_hazards.vvp

uvm:
	@echo "Use 'make questa' for the UVM flow. Icarus Verilog does not provide UVM."

questa:
	vlib work
	vlog -sv +incdir+tb $(RTL) $(UVM_TOP)
	vsim -c tb_riscv +UVM_TESTNAME=riscv_smoke_test -do "run -all; quit"

clean:
	rm -rf $(BUILD_DIR) work transcript *.wlf logs coverage
