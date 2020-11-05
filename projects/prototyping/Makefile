-include ../cfg.local

VIVADO   ?= vivado
XVCD     ?= xvcd

BIT      := spartan_top.bit
URL      := esp32_upload.local
V_FLAGS  := -nojournal -nolog -mode batch

IP_STUBS := output/IP_proj/project1.srcs/sources_1/ip/myUartLite/myUartLite_stub.v
LIBS     := bsv_lib/*

.PHONY: sim


################### RTL Stuff ###################
hdl_build:
	iverilog $(IP_STUBS) $(LIBS) src/*.v -o sim.out

hdl_sim: hdl_build
	./sim.out

show: hdl_sim
	gtkwave dump.vcd


################### Vivado targets ###################
synth:
	$(VIVADO) $(V_FLAGS) -source synth_lean.tcl
	notify-send "Vivado synthesis done"

build_ip:
	$(VIVADO) $(V_FLAGS) -source build_ip.tcl

jtag:
	$(VIVADO) $(V_FLAGS) -source jtag_program.tcl
	notify-send "JTAG programming done"


################### deployment ###################
get_ip:
	echo $(shell resolvectl query $(URL) --legend=no | grep -oE '[0-9]+(\.[0-9]+){3}') > ESP_IP

deploy:
	curl -F "image=@output/$(BIT)" $(shell cat ESP_IP)/update

serterm:
	picocom /dev/ttyUSB0 -b 115200

virt_cable:
	$(XVCD) -P 0x6001

ocd:
	openocd -f openocd_xc7.cfg -c "upload_bit output/$(BIT)"


################### convenience ###################
update_bsv:
	make -C bsv_src deploy_verilog

full: update_bsv synth deploy

clean:
	rm -rf output .Xil
