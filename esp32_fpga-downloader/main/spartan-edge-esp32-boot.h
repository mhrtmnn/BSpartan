#ifndef SPARTAN_EDGE_ESP32_BOOT_H
#define SPARTAN_EDGE_ESP32_BOOT_H 

#define XFPGA_CCLK_PIN 17
#define XFPGA_DIN_PIN 27
#define XFPGA_PROGRAM_PIN 25
#define XFPGA_INTB_PIN 26
#define XFPGA_DONE_PIN 34

class spartan_edge_esp32_boot {
public:
	void xfpgaGPIOInit(void);
	int xlibsSstream(const unsigned char* buf, int buf_len);
	void finish();
	int was_successfull();
	
private:
	bool first_run;
	void send_byte(const unsigned char byte);
	int success;
};

#endif
