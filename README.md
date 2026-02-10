# 🌱 GotaGota - Matero Inteligente

Sistema de monitoreo inteligente de plantas con ESP32 y Flutter. Controla la salud de tus plantas en tiempo real desde tu celular.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)
![ESP32](https://img.shields.io/badge/ESP32-IoT-red.svg)

## ✨ Características

- 📊 **Monitoreo en Tiempo Real**: Visualiza temperatura, humedad del aire, humedad del suelo y nivel de luz en vivo
- 💧 **Registro de Riego**: Lleva un historial de cuándo regaste tus plantas y recibe recordatorios
- 📸 **Galería de Plantas**: Agrega fotos y descripciones de tus plantas
- 🔐 **Multi-usuario**: Cada usuario gestiona sus propias plantas de forma segura
- 🌐 **Configuración WiFi**: Conecta tu dispositivo ESP32 a tu red WiFi fácilmente
- 🎯 **Recomendaciones Inteligentes**: Recibe alertas cuando tus plantas necesitan atención
- 📱 **Multiplataforma**: Disponible para Android e iOS

## 🚀 Inicio Rápido

### Prerrequisitos

- Flutter SDK 3.0 o superior
- Cuenta de Supabase (gratuita)
- ESP32 DevKit con sensores (opcional para desarrollo)

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tuusuario/matero_fixed_new.git
   cd matero_fixed_new
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno**
   
   Crea un archivo `.env` en la raíz del proyecto (usa `.env.example` como referencia):
   ```env
   SUPABASE_URL=tu_url_de_supabase
   SUPABASE_ANON_KEY=tu_anon_key_de_supabase
   ```

4. **Configurar Supabase**
   
   Ejecuta el script SQL en tu proyecto de Supabase:
   ```bash
   # Copia el contenido de supabase_init.sql y ejecútalo en el SQL Editor de Supabase
   ```

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 🔧 Configuración de Hardware

### Componentes Necesarios

- **ESP32 DevKit** (NodeMCU-32S o similar)
- **Sensor DHT22** - Temperatura y humedad del aire
- **Sensor de Humedad de Suelo Capacitivo** - Humedad del suelo
- **Fotoresistor LDR** - Nivel de luz
- **Resistencia 10kΩ** - Para el fotoresistor
- **Cables Dupont** - Conexiones
- **Protoboard** (opcional)

### Diagrama de Conexiones

```
ESP32          DHT22
-----          -----
3.3V    --->   VCC
GND     --->   GND
GPIO 4  --->   DATA

ESP32          Sensor de Suelo
-----          ---------------
3.3V    --->   VCC
GND     --->   GND
GPIO 34 --->   AOUT

ESP32          LDR + Resistencia
-----          -----------------
3.3V    --->   LDR (un extremo)
GPIO 35 --->   LDR (otro extremo) + Resistencia
GND     --->   Resistencia (otro extremo)
```

### Código ESP32

El código Arduino para el ESP32 debe enviar datos a Supabase vía HTTP POST. Ejemplo básico:

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

#define DHTPIN 4
#define DHTTYPE DHT22
#define SOIL_PIN 34
#define LDR_PIN 35

DHT dht(DHTPIN, DHTTYPE);

const char* ssid = "TU_WIFI";
const char* password = "TU_PASSWORD";
const char* supabaseUrl = "https://tu-proyecto.supabase.co/rest/v1/matero_readings";
const char* supabaseKey = "tu_anon_key";

void setup() {
  Serial.begin(115200);
  dht.begin();
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi conectado!");
}

void loop() {
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();
  int soilMoisture = map(analogRead(SOIL_PIN), 0, 4095, 0, 100);
  int lightLevel = analogRead(LDR_PIN);
  
  // Enviar datos a Supabase
  HTTPClient http;
  http.begin(supabaseUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", supabaseKey);
  http.addHeader("Authorization", String("Bearer ") + supabaseKey);
  
  String payload = "{\"plant_id\":1,\"temperature\":" + String(temp) + 
                   ",\"humidity\":" + String(humidity) +
                   ",\"soil_moisture\":" + String(soilMoisture) +
                   ",\"light_level\":" + String(lightLevel) + "}";
  
  int httpCode = http.POST(payload);
  Serial.println("HTTP Code: " + String(httpCode));
  http.end();
  
  delay(30000); // Enviar cada 30 segundos
}
```

## 📱 Uso de la Aplicación

### 1. Registro e Inicio de Sesión
- Crea una cuenta con tu email
- Inicia sesión para acceder al dashboard

### 2. Agregar tu Primera Planta
- Presiona el botón **+** flotante
- Ingresa el nombre de tu planta
- (Opcional) Agrega una foto desde la cámara o galería
- (Opcional) Agrega una descripción

### 3. Configurar WiFi del ESP32
- Presiona el ícono de WiFi en la barra superior
- Conecta tu celular a la red "Matero-Setup"
- Sigue las instrucciones para conectar el ESP32 a tu WiFi

### 4. Monitorear tus Plantas
- Los datos se actualizan automáticamente en tiempo real
- Revisa las recomendaciones basadas en las condiciones
- Registra cuándo riegas tus plantas con el botón "REGAR HOY"

## 🧪 Testing

Ejecutar todos los tests:
```bash
flutter test
```

Ejecutar tests con cobertura:
```bash
flutter test --coverage
```

Ver reporte de cobertura:
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🏗️ Arquitectura del Proyecto

```
lib/
├── config/
│   └── constants.dart          # Constantes y configuraciones
├── models/
│   ├── plant.dart              # Modelo de Planta
│   └── sensor_reading.dart     # Modelo de Lectura de Sensores
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   └── plants/
│       └── add_plant_screen.dart
├── services/
│   ├── auth_service.dart       # Servicio de autenticación
│   └── matero_service.dart     # Servicio de plantas y sensores
├── utils/
│   └── logger.dart             # Utilidad de logging
└── main.dart                   # Punto de entrada
```

## 🔐 Seguridad

- ✅ Credenciales en variables de entorno (no en código)
- ✅ Row Level Security (RLS) en Supabase
- ✅ Autenticación JWT
- ✅ Cada usuario solo ve sus propias plantas

## 🐛 Troubleshooting

### La app no se conecta a Supabase
- Verifica que el archivo `.env` existe y tiene las credenciales correctas
- Asegúrate de que las credenciales son válidas en tu proyecto de Supabase

### No aparecen datos de sensores
- Verifica que el ESP32 está conectado a WiFi
- Revisa que el `plant_id` en el código ESP32 coincide con el ID de tu planta
- Verifica en Supabase que los datos se están insertando en `matero_readings`

### Error de permisos en Supabase
- Ejecuta el script `fix_permissions.sql` en el SQL Editor de Supabase
- Verifica que las políticas RLS están habilitadas

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver archivo `LICENSE` para más detalles.

## 👨‍💻 Autor

**Randy Molina**

## 🤝 Contribuciones

Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Si tienes alguna pregunta o problema, por favor abre un issue en GitHub.

---

**¡Hecho con ❤️ para los amantes de las plantas!** 🌿
