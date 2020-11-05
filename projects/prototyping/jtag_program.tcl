#######################################
# SETUP
#######################################
set outputDir ./output
#######################################
#######################################

open_hw_manager

connect_hw_server -url localhost:3121 -allow_non_jtag
open_hw_target -xvc_url localhost:2542

set_property PROGRAM.FILE $outputDir/spartan_top.bit [get_hw_devices xc7s15_0]
program_hw_devices [get_hw_devices xc7s15_0]

close_hw_manager
