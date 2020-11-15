#######################################
# SETUP
#######################################
set device xc7s15ftgb196-1
set topmodule spartan_top
set outputDir ./output
#######################################
#######################################

file mkdir $outputDir
set_part $device
read_verilog  [ glob ./src/*.v ] [ glob ./bsv_lib/*.v ]
read_xdc ./src/constraints.xdc

# import IP Cores that are used in the design
read_ip $outputDir/IP_proj/project1.srcs/sources_1/ip/myUartLite/myUartLite.xci
read_ip $outputDir/IP_proj/project1.srcs/sources_1/ip/myI2S/myI2S.xci

# import external BD
read_bd $outputDir/BD_proj/project1.srcs/sources_1/bd/myDesign/myDesign.bd

synth_design -top $topmodule -part $device
opt_design
place_design -directive Quick
route_design -directive Quick

report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_utilization -file $outputDir/post_place_util.rpt

write_bitstream -force $outputDir/$topmodule.bit
