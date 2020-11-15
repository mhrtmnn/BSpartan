#######################################
# SETUP
#######################################
set device xc7s15ftgb196-1
set outputDir ./output
set coe_file  ../../../../../../../../bram_initialization.coe
set stub_file  $outputDir/BD_proj/project1.srcs/sources_1/bd/myDesign/myDesign_stub.v
#######################################
#######################################

file mkdir $outputDir

create_project project1 $outputDir/BD_proj -part $device -force
create_bd_design myDesign

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 	myBramCtrl
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 	myBram

# customize imported IP Cores
set_property -dict [list                       \
	CONFIG.PROTOCOL 				{AXI4LITE} \
	CONFIG.SINGLE_PORT_BRAM 		{1}        \
	CONFIG.ECC_TYPE 				{0}        \
	] [get_bd_cells myBramCtrl]

set_property -dict [list                                     \
	CONFIG.use_bram_block {Stand_Alone}                      \
	CONFIG.Enable_32bit_Address {true} 	                     \
	CONFIG.Use_Byte_Write_Enable {true}                      \
	CONFIG.Byte_Size {8}                                     \
	CONFIG.Write_Depth_A {4096}                              \
	CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
	CONFIG.Load_Init_File {true}                             \
	CONFIG.Coe_File $coe_file                                \
	CONFIG.Use_RSTA_Pin {true}                               \
	CONFIG.EN_SAFETY_CKT {true}                              \
	] [get_bd_cells myBram]

# connect ports
apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto"}  [get_bd_intf_pins myBramCtrl/BRAM_PORTA]

# make input ports external
make_bd_intf_pins_external 	[get_bd_intf_pins myBramCtrl/S_AXI]
make_bd_pins_external  		[get_bd_pins myBramCtrl/s_axi_aclk]
make_bd_pins_external  		[get_bd_pins myBramCtrl/s_axi_aresetn]

set_property -dict [list CONFIG.HAS_PROT {0}] [get_bd_intf_ports S_AXI_0]

# assign AXI addr
assign_bd_address [get_bd_addr_segs {myBramCtrl/S_AXI/Mem0 }]

# synth
save_bd_design
set_property top myDesign [get_filesets sources_1]
launch_runs synth_1
wait_on_run synth_1

# write stub file
open_run synth_1
write_verilog -mode synth_stub $stub_file
