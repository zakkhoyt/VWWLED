
void setup() {
        Serial.begin(250000);
        Serial.print("\n\nHello, I just rebooted\n\n");
}

void loop() {
        uint8_t incomingByte;
        // send data only when you receive data:
	if (Serial.available() > 0) {
		// read the incoming byte:
		incomingByte = Serial.read();
                
		// say what you got with both the ASCII and decimal representations
		Serial.print("I received: ");
		Serial.print(incomingByte, HEX);
		Serial.print(" : ");
		Serial.print(incomingByte, DEC);
		Serial.print(" : ");

                char *str = (char*)malloc(10 * sizeof(byte));
                sprintf(str, "%c\n", incomingByte);
                Serial.println(str);
                free(str);
          }
}

