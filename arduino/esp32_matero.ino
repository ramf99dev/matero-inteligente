#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// Configuración de Wi-Fi
const char* ssid = "TU_SSID_WIFI";
const char* password = "TU_PASSWORD_WIFI";

// Configuración de Supabase
const char* supabaseUrl = "https://TU_ROYECTO.supabase.co/rest/v1/lecturas";
const char* supabaseKey = "TU_SUPABASE_ANON_KEY";

// Identificación del Dispositivo
// Puedes usar la MAC address o un ID hardcodearlo
String deviceId = "GOTA-" + String((uint32_t)ESP.getEfuseMac(), HEX); 
// O si prefieres hardcodearlo: String deviceId = "GOTA-7429";

// Simulación de sensores
const int pinHumedad = 34;
const int pinLuz = 35;

void setup() {
  Serial.begin(115200);
  
  // Conexión Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Conectando a Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConectado a Wi-Fi");
  Serial.print("Dirección IP: ");
  Serial.println(WiFi.localIP());
  Serial.print("Device ID: ");
  Serial.println(deviceId);
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(supabaseUrl);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", String("Bearer ") + supabaseKey);
    http.addHeader("Prefer", "return=minimal");

    // Lectura de sensores (Simulados o Reales)
    int humedadSuelo = map(analogRead(pinHumedad), 0, 4095, 0, 100);
    int nivelLuz = map(analogRead(pinLuz), 0, 4095, 0, 100);
    float temperatura = 25.0 + (random(-10, 10) / 10.0); // Simulación
    float humedadAire = 60.0 + (random(-5, 5) / 10.0);   // Simulación

    // Crear JSON
    StaticJsonDocument<200> doc;
    doc["device_id"] = deviceId;
    doc["soil_moisture"] = humedadSuelo;
    doc["light_level"] = nivelLuz;
    doc["temperature"] = temperatura;
    doc["humidity"] = humedadAire;
    // doc["plant_id"] = ...; // YA NO ES NECESARIO si usas device_id

    String jsonPayload;
    serializeJson(doc, jsonPayload);

    // Enviar datos
    int httpResponseCode = http.POST(jsonPayload);

    if (httpResponseCode > 0) {
      Serial.print("HTTP Response code: ");
      Serial.println(httpResponseCode);
    } else {
      Serial.print("Error code: ");
      Serial.println(httpResponseCode);
    }
    http.end();
  } else {
    Serial.println("WiFi Desconectado");
  }

  // Enviar cada 30 segundos
  delay(30000);
}
