TB       ?= Tb
BINNAME   = myLinkedModule

BSC       = bsc
BSC_FLAGS = -show-range-conflict -show-schedule -aggressive-conditions -O

# verilog generation
TOPMODULE = mkBs_top
V_FILE    = Bs_top


################### BS Sim ###################
all: build sim

build: compile link

compile:
	$(BSC) $(BSC_FLAGS) -sim -g mk$(TB) -u $(TB).bsv

link:
	$(BSC) $(BSC_FLAGS) -sim -e mk$(TB) -o $(BINNAME)

sim:
	@echo "================ Start Simulation ================"
	./$(BINNAME) -V
	@echo "================ Stop  Simulation ================"

view:
	gtkwave dump.vcd

sched:
	cat mk$(TB).sched


################### Verilog ###################
deploy_verilog: verilog_compile
	cp $(TOPMODULE).v ../src

show_verilog: verilog_compile
	bat $(TOPMODULE).v

verilog_compile:
	$(BSC) $(BSC_FLAGS) -verilog -g $(TOPMODULE) -u $(V_FILE).bsv

verilog_link:
	$(BSC) $(BSC_FLAGS) -verilog -e $(TOPMODULE) -o $(BINNAME)


################### plot sched ###################
plot_sched: gen_dot gen_pdf

gen_dot:
	$(BSC) $(BSC_FLAGS) -sched-dot -sim -g mk$(TB) -u $(TB).bsv

gen_pdf: $(patsubst %.dot,%.pdf,$(wildcard *.dot))

%.pdf: %.dot
	dot -Tpdf "$<" -o "$@"


################### cleanup ###################
clean:
	rm -rf *.pdf *.dot *.cxx *.h *.o *.so *.bo *.ba *.v *.sched

