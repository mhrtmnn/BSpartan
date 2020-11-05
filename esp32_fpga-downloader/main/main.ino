/*
	To upload through terminal you can use: curl -F "image=@firmware.bin" esp32_upload.local/update
*/

#include <WiFi.h>
#include <WiFiClient.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include "spartan-edge-esp32-boot.h"
#include "local_cfg.h"

/* Global Variables */
const char* host = "esp32_upload";
const char* ssid = WIFI_SSID;
const char* password = WIFI_KEY;

WebServer server(80);
spartan_edge_esp32_boot esp32Cla;

const char* serverIndex = "<form method='POST' action='/update' enctype='multipart/form-data'>" \
							"<input type='file' name='update'><input type='submit' value='Update'>" \
						  "</form>";


void handleFileUpload() {
	HTTPUpload& upload = server.upload();
	if (upload.status == UPLOAD_FILE_START) {
		Serial.printf("Upload: START, filename: %s\n\r", upload.filename);
		esp32Cla.xfpgaGPIOInit();

	} else if (upload.status == UPLOAD_FILE_WRITE) {
		Serial.printf("Upload: writing %d Bytes (total size %d)\n\r", upload.currentSize, upload.totalSize);
		esp32Cla.xlibsSstream(upload.buf, upload.currentSize);
	} else if (upload.status == UPLOAD_FILE_END) {
		Serial.printf("Upload: END, Size: %d\n\r", upload.totalSize);
		esp32Cla.finish();
	}
}

void setup(void) {
	Serial.begin(115200);
	Serial.println("Booting Sketch...");
	Serial.setDebugOutput(true);

	WiFi.mode(WIFI_AP_STA);
	WiFi.begin(ssid, password);
	if (WiFi.waitForConnectResult() == WL_CONNECTED) {
		MDNS.begin(host);

		/* Server Callbacks */
		server.on("/", HTTP_GET, []() {
			server.sendHeader("Connection", "close");
			server.send(200, "text/html", serverIndex);
		});
		server.on("/update", HTTP_POST, []() {
			server.send(200, "text/plain", esp32Cla.was_successfull()?"Configuration completed!\n\r":"Error!\n\r");
		}, handleFileUpload);

		server.begin();
		MDNS.addService("http", "tcp", 80);

		Serial.printf("Ready! Open http://%s.local in your browser\n\r", host);
	} else {
		Serial.println("WiFi Failed");
	}
}

void loop(void) {
	server.handleClient();
	delay(1);
}
