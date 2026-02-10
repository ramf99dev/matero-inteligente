class PlantThresholds {
  // Umbrales de humedad del suelo (%)
  static const int criticalSoilMoisture = 25;
  static const int lowSoilMoisture = 40;
  static const int excessWater = 80;

  // Umbrales de temperatura (°C)
  static const double highTemperature = 30.0;
  static const double lowTemperature = 10.0;

  // Configuración de riego por defecto
  static const int defaultWateringFrequencyDays = 3;

  // Configuración de UI
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int imageQuality = 85;

  // Configuración de WiFi
  static const String wifiSetupSSID = 'Matero-Setup';
  static const String wifiSetupURL = 'http://192.168.4.1';

  // Timeouts y delays
  static const int notificationDurationMs = 2500;
  static const int refreshIntervalSeconds = 30;
}

class AppConstants {
  static const String appName = 'GotaGota';
  static const String appDescription =
      'Matero Inteligente - Sistema de Monitoreo';

  // Supabase Tables
  static const String plantsTable = 'plants';
  static const String readingsTable = 'matero_readings';
  static const String profilesTable = 'profiles';

  // Storage Buckets
  static const String plantImagesBucket = 'plant_images';
}
