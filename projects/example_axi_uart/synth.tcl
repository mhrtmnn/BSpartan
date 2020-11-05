#######################################
# SETUP
#######################################
set device xc7s15ftgb196-1
set topmodule test
set outputDir ./output
set repo_path ~/Documents/Projects/Vivado-Projects/IPs/
#######################################
#######################################

file mkdir $outputDir
create_project project1 $outputDir/JtagToUart_proj -part $device -force

read_verilog [ glob ./src/*.v ]
read_xdc ./src/constraints.xdc

# import IP Cores that are used in the design
set_property ip_repo_paths $repo_path [current_project]
update_ip_catalog
create_ip -vlnv MH.org:user:jtag_to_uart:1.0 -module_name jtag_to_uart
generate_target {all} [get_ips]

synth_ip [get_ips]
synth_design -top $topmodule -part $device

# this also builds the debug core (JTAG-to-AXI)
opt_design
place_design
route_design

report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_utilization -file $outputDir/post_place_util.rpt

write_bitstream -force $outputDir/$topmodule.bit
write_debug_probes -force $outputDir/designProbes.ltx
