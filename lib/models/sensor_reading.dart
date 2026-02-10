class SensorReading {
  final int? id;
  final int? plantId;
  final double temperature;
  final double humidity;
  final int soilMoisture;
  final int lightLevel;
  final DateTime timestamp;

  SensorReading({
    this.id,
    this.plantId,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightLevel,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id'] as int?,
      plantId: json['plant_id'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      soilMoisture: (json['soil_moisture'] as int?) ?? 0,
      lightLevel: (json['light_level'] as int?) ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (plantId != null) 'plant_id': plantId,
      'temperature': temperature,
      'humidity': humidity,
      'soil_moisture': soilMoisture,
      'light_level': lightLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Método para convertir a formato legacy (Map<String, dynamic>)
  Map<String, dynamic> toLegacyFormat() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'soil_moisture': soilMoisture,
      'light_level': lightLevel,
    };
  }

  @override
  String toString() {
    return 'SensorReading(temp: ${temperature.toStringAsFixed(1)}°C, '
        'humidity: ${humidity.toStringAsFixed(1)}%, '
        'soil: $soilMoisture%, light: $lightLevel)';
  }
}
