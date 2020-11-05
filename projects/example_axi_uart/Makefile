-include ../cfg.local

VIVADO   ?= vivado
XVCD     ?= xvcd

V_FLAGS  := -nojournal -nolog -mode batch


synth:
	$(VIVADO) $(V_FLAGS) -source synth.tcl

jtag:
	$(VIVADO) $(V_FLAGS) -source jtag_program.tcl

print:
	$(VIVADO) $(V_FLAGS) -source print_uart.tcl

virt_cable:
	$(XVCD) -P 0x6001

clean:
	rm -rf output .Xil
