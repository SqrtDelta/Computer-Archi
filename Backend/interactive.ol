
package require openlane
prep -design . -ignore_mismatches -tag 250402-092831_SOLUTION1_simple_program_and_MULT1
set_odb ./runs/250402-092831_SOLUTION1_simple_program_and_MULT1/results/floorplan/cpu.odb
set_def ./runs/250402-092831_SOLUTION1_simple_program_and_MULT1/results/floorplan/cpu.def
or_gui

set_odb ./runs/250402-092831_SOLUTION1_simple_program_and_MULT1/results/placement/cpu.odb
set_def ./runs/250402-092831_SOLUTION1_simple_program_and_MULT1/results/placement/cpu.def
or_gui

set_odb ./runs/250402-092831_SOLUTION1_simple_program_and_MULT1/results/routing/cpu.odb
set_def ./runs/250402-092831_SOLUTION1_simple_program_and_MULT1/results/final/def/cpu.def
or_gui
