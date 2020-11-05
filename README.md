# FPGA Playground
Collection of projects using the [Spartan Edge Accelerator Board](http://wiki.seeedstudio.com/Spartan-Edge-Accelerator-Board/)


## OTA-Programming
If the ESP32 is running the firmware contained in `esp32_fpga-downloader` and is connected to the local WIFI, a webserver will be exposed at [esp32_upload.local](http://esp32_upload.local). Bistreams uploaded via the webform or using the `make deploy` target are programmed into the FPGA.


## JTAG-Programming
Using [xvcd](https://github.com/tmbinc/xvcd) the FPGA can be programmed using a FT232R USB UART (VID/PID: `0403:6001`). Alternatively, OpenOCD can be used with the `ft232r` adapter driver.

Connection:

| JTAG Pin | FTDI Pin | Bitbang Pin |
|----------|----------|-------------|
| TCK      | TX       | 0x01        |
| TDI      | RX       | 0x02        |
| TDO      | RTS      | 0x04        |
| TMS      | CTS      | 0x08        |


## Vivado/Vitis Info
- Installer needs `ncurses5-compat-libs` package or must be run in CLI mode
- Vitis needs `xorg-xlsclients` package
- Disable WebTalk: Put `export HTTPS_PROXY=localhost` at the end of `<VivadoPath>/bin/setupEnv.sh`


## Build instructions
Make sure vivado is in PATH, or alternatively put a `cfg.local` file in the `projects` directory that defines the variable `VIVADO := .../bin/vivado`.

In one of the project directories execute:
```
# build Xilinx UARTLite IPCore
make build_ip

# compile Bluespec design
make update_bsv

# build the bitstream
make synth

# program FPGA (alternatively via JTAG or OTA)
make ocd
```
