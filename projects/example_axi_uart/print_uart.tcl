#######################################
# HELPER FUNCTIONS
#######################################
proc write {address value} {
	create_hw_axi_txn -force wr_tx [get_hw_axis hw_axi_1] -address $address -data $value -len 1 -type write
	run_hw_axi wr_tx
}

proc read {address} {
	create_hw_axi_txn -force rd_tx [get_hw_axis hw_axi_1] -address $address -len 1 -type read
	run_hw_axi rd_tx
	return 0x[get_property DATA [get_hw_axi_txn rd_tx]]
}

proc string2hex s {
	binary scan [encoding convertto utf-8 $s] H* hex
	regsub -all (..) $hex {\1 }
}

proc print {uart string} {
	set hex_string [split [string trim [string2hex $string]] " "]

	foreach char $hex_string {
		write $uart 000000$char
		after 100
	}
}
#######################################
#######################################


open_hw_manager

connect_hw_server -url localhost:3121 -allow_non_jtag
open_hw_target -xvc_url localhost:2542
refresh_hw_device [lindex [get_hw_devices xc7s15_0] 0]

print 0x40600004 "Hello World!"

close_hw_manager
