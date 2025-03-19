###########
# general #
###########
clean:
	rm -rf xcelium.d .simvision xrun.* xmverilog.* *.vcd *.shm *.dump

all: clean sim

###########
# simulation #
###########	
sim:
	clear;
	xrun +sv -64bit -f files_verilog.f -top cpu_tb -timescale 1ns/10ps -access +rwc -allowredefinition

sim_gui:
	clear;
	xrun +sv -64bit -f files_verilog.f -top cpu_tb -timescale 1ns/10ps -access +rwc -allowredefinition -linedebug -gui &
