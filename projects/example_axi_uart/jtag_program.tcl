#######################################
# SETUP
#######################################
set outputDir ./output

set axi_UART_TX_addr 0x40600004
set axi_value        0x00000046
#######################################
#######################################

open_hw_manager

connect_hw_server -url localhost:3121 -allow_non_jtag
open_hw_target -xvc_url localhost:2542

set_property PROGRAM.FILE $outputDir/test.bit         [get_hw_devices xc7s15_0]
set_property PROBES.FILE  $outputDir/designProbes.ltx [get_hw_devices xc7s15_0]
program_hw_devices [get_hw_devices xc7s15_0]

refresh_hw_device [lindex [get_hw_devices xc7s15_0] 0]

# Generate an AXI transaction: Put 0x46='F' into UART TX FIFO
create_hw_axi_txn wr_tx [get_hw_axis hw_axi_1] -address $axi_UART_TX_addr -data $axi_value -type write
run_hw_axi wr_tx

close_hw_manager
