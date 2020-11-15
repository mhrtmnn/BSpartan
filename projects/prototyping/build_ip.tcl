#######################################
# SETUP
#######################################
set device xc7s15ftgb196-1
set outputDir ./output
#######################################
#######################################

file mkdir $outputDir

create_project project1 $outputDir/IP_proj -part $device -force
create_ip -vlnv xilinx.com:ip:axi_uartlite:2.0 -module_name myUartLite
create_ip -vlnv xilinx.com:ip:i2s_transmitter:1.0 -module_name myI2S

# customize imported IP Core
set_property CONFIG.C_S_AXI_ACLK_FREQ_HZ 	50000000 	[get_ips myUartLite]
set_property CONFIG.C_BAUDRATE 				9600 		[get_ips myUartLite]

set_property CONFIG.C_DWIDTH 				16 			[get_ips myI2S]

generate_target {all} [get_ips]
synth_ip [get_ips]
