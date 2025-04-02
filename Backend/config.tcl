
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

set ::env(DESIGN_NAME) cpu
set ::env(VERILOG_FILES) ../Verilog/RTL_SOLUTION1_simple_program_and_MULT1/*.v

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"
set ::env(CLOCK_PERIOD) 100
set ::env(CLOCK_TREE_SYNTH) 1

set ::env(DESIGN_IS_CORE) 1      
set ::env(SYNTH_MAX_FANOUT) 30
set ::env(SYNTH_NO_FLAT) 1

set ::env(SYNTH_STRATEGY) "AREA 0"
set ::env(SYNTH_NO_FLAT) 1

# Connect the layout files and abstracts
# Connect the blackbox information and timing data
set ::env(EXTRA_LEFS)      [list OpenRAM_output/sky130_sram_2rw_32x128_32.lef OpenRAM_output/sky130_sram_2rw_64x128_64.lef]
set ::env(EXTRA_GDS_FILES) [list OpenRAM_output/sky130_sram_2rw_64x128_64.gds OpenRAM_output/sky130_sram_2rw_32x128_32.gds]
set ::env(EXTRA_LIBS)      [list OpenRAM_output/sky130_sram_2rw_64x128_64_TT_1p8V_25C.lib OpenRAM_output/sky130_sram_2rw_32x128_32_TT_1p8V_25C.lib]

set ::env(BASE_SDC_FILE) H05d4a.sdc

# SRAM config
set ::env(VDD_NETS) "vccd1"
set ::env(GND_NETS) "vssd1"
set ::env(FP_PDN_MACRO_HOOKS) "\
 instruction_memory.*.dram_inst      vccd1 vssd1 vccd1 vssd1,\
 data_memory.*.spad_inst      vccd1 vssd1 vccd1 vssd1"
 
# Option-?: Some floorplan empirical parameters
## floorplan factor that controls the core utilization and the relative die area
set ::env(FP_CORE_UTIL) 35
# set ::env(FP_CORE_UTIL) 50
# set ::env(FP_CORE_UTIL) 65

## placement factor that controls the cell density
# set ::env(PL_TARGET_DENSITY) 0.65
# set ::env(PL_TARGET_DENSITY) 0.75
# set ::env(PL_TARGET_DENSITY) 0.85

# # Option-1: Auto DIE Area selection
set ::env(FP_SIZING) relative
# # Option-2: Manual DIE Area config
# set ::env(FP_SIZING) absolute
# set ::env(DIE_AREA) "0 0 1400 1400"

# Option-1: Auto Macro Placement
set ::env(PL_MACRO_CHANNEL) [list 80 80]
# # Option-2: Manual Macro Placement 
# set ::env(MACRO_PLACEMENT_CFG) macro_placement.cfg

# other config
set ::env(ROUTING_CORES) 12
set ::env(RUN_KLAYOUT_XOR) 0
set ::env(MAGIC_DRC_USE_GDS) 0
set ::env(QUIT_ON_MAGIC_DRC) 0    

set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 1 
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 1  
set ::env(PL_RESIZER_REPAIR_TIE_FANOUT) 1  
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 1  
set ::env(GLB_RESIZER_DESIGN_OPTIMIZATIONS) 1 

set ::env(DIODE_INSERTION_STRATEGY) 3
set ::env(QUIT_ON_LONG_WIRE) 1 
