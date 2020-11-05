#include <Arduino.h>
#include <HardwareSerial.h>
#include "spartan-edge-esp32-boot.h"

void spartan_edge_esp32_boot::xfpgaGPIOInit(void) {
	// GPIO Initialize
	pinMode(XFPGA_INTB_PIN, INPUT);
	pinMode(XFPGA_DONE_PIN, INPUT);
	pinMode(XFPGA_PROGRAM_PIN, OUTPUT);

	// FPGA configuration start sign
	digitalWrite(XFPGA_PROGRAM_PIN, LOW);
	pinMode(XFPGA_CCLK_PIN, OUTPUT);
	digitalWrite(XFPGA_CCLK_PIN, LOW);
	digitalWrite(XFPGA_PROGRAM_PIN, HIGH);

	// wait until fpga reports reset complete
	while (digitalRead(XFPGA_INTB_PIN) == 0) {}

	this->first_run = true;
	this->success = 0;
}

int spartan_edge_esp32_boot::xlibsSstream(const unsigned char *byte_buff, int buf_len) {
	int buf_pos = 0;

	// init
	if (first_run) {
		// find the raw bits
		if (byte_buff[0] != 0xff) {
			// skip header
			buf_pos = ((byte_buff[0] << 8) | byte_buff[1]) + 4;

			// find the 'e' record
			while (byte_buff[buf_pos] != 0x65) {
				// skip the record
				buf_pos += (byte_buff[buf_pos+1] << 8 | byte_buff[buf_pos+2]) + 3;
				// exit if the next record isn't within the buffer
				if (buf_pos >= buf_len)
					return -1;
			}
			// skip the field name and bitstrem length
			buf_pos += 5;
		} // else it's already a raw bin file


		// put pins down for Configuration
		pinMode(XFPGA_DIN_PIN, OUTPUT);
		first_run = false;
	}

	for ( ; buf_pos < buf_len; buf_pos++)
		send_byte(byte_buff[buf_pos]);
}

void spartan_edge_esp32_boot::finish() {
	digitalWrite(XFPGA_CCLK_PIN, LOW); 
	
	// check the result
	if (0 == digitalRead(XFPGA_DONE_PIN)) {
		Serial.println("FPGA Configuration Failed");
	} else {
		Serial.println("FPGA Configuration success");
		this->success = 1;
	}

}

void spartan_edge_esp32_boot::send_byte(unsigned char byte) {
	for (int j = 0;j < 8;j++) {
		digitalWrite(XFPGA_CCLK_PIN, LOW); 
		digitalWrite(XFPGA_DIN_PIN, (byte&0x80)?HIGH:LOW);
		byte = byte << 1;
		digitalWrite(XFPGA_CCLK_PIN, HIGH); 
	}
}

int spartan_edge_esp32_boot::was_successfull() {
	return this->success;
}
