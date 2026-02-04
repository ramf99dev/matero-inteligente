import '../config/constants.dart';

class Plant {
  final int? id;
  final String userId;
  final String name;
  final String? imageUrl;
  final String? description;
  final DateTime? lastWatered;
  final int wateringFrequency;
  final DateTime createdAt;
  final String? deviceId; // ID del dispositivo ESP32 vinculado

  Plant({
    this.id,
    required this.userId,
    required this.name,
    this.imageUrl,
    this.description,
    this.lastWatered,
    int? wateringFrequency,
    DateTime? createdAt,
    this.deviceId,
  })  : wateringFrequency =
            wateringFrequency ?? PlantThresholds.defaultWateringFrequencyDays,
        createdAt = createdAt ?? DateTime.now();

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      lastWatered: json['last_watered'] != null
          ? DateTime.parse(json['last_watered'] as String)
          : null,
      wateringFrequency: (json['watering_frequency'] as int?) ??
          PlantThresholds.defaultWateringFrequencyDays,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      deviceId: json['device_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (description != null) 'description': description,
      if (lastWatered != null) 'last_watered': lastWatered!.toIso8601String(),
      'watering_frequency': wateringFrequency,
      'created_at': createdAt.toIso8601String(),
      if (deviceId != null) 'device_id': deviceId,
    };
  }

  // Calcula la próxima fecha de riego
  DateTime? get nextWatering {
    if (lastWatered == null) return null;
    return lastWatered!.add(Duration(days: wateringFrequency));
  }

  // Verifica si necesita riego urgente
  bool get needsWatering {
    final next = nextWatering;
    if (next == null) return true;
    return next.isBefore(DateTime.now());
  }

  // Días hasta el próximo riego (negativo si está atrasado)
  int? get daysUntilNextWatering {
    final next = nextWatering;
    if (next == null) return null;
    return next.difference(DateTime.now()).inDays;
  }

  // Copia con modificaciones
  Plant copyWith({
    int? id,
    String? userId,
    String? name,
    String? imageUrl,
    String? description,
    DateTime? lastWatered,
    int? wateringFrequency,
    DateTime? createdAt,
    String? deviceId,
  }) {
    return Plant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      lastWatered: lastWatered ?? this.lastWatered,
      wateringFrequency: wateringFrequency ?? this.wateringFrequency,
      createdAt: createdAt ?? this.createdAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  String toString() {
    return 'Plant(id: $id, name: $name, nextWatering: $nextWatering)';
  }
}
