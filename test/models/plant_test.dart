import 'package:flutter_test/flutter_test.dart';
import 'package:matero_fixed/models/plant.dart';
import 'package:matero_fixed/config/constants.dart';

void main() {
  group('Plant Model', () {
    test('fromJson creates Plant correctly', () {
      final json = {
        'id': 1,
        'user_id': 'user123',
        'name': 'Rosa',
        'image_url': 'https://example.com/rosa.jpg',
        'description': 'Una hermosa rosa roja',
        'last_watered': '2026-01-30T10:00:00.000Z',
        'watering_frequency': 2,
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final plant = Plant.fromJson(json);

      expect(plant.id, 1);
      expect(plant.userId, 'user123');
      expect(plant.name, 'Rosa');
      expect(plant.imageUrl, 'https://example.com/rosa.jpg');
      expect(plant.description, 'Una hermosa rosa roja');
      expect(plant.wateringFrequency, 2);
      expect(plant.lastWatered, isNotNull);
    });

    test('toJson converts Plant correctly', () {
      final plant = Plant(
        id: 1,
        userId: 'user123',
        name: 'Cactus',
        wateringFrequency: 7,
      );

      final json = plant.toJson();

      expect(json['id'], 1);
      expect(json['user_id'], 'user123');
      expect(json['name'], 'Cactus');
      expect(json['watering_frequency'], 7);
    });

    test('uses default watering frequency when not provided', () {
      final plant = Plant(
        userId: 'user123',
        name: 'Planta sin frecuencia',
      );

      expect(plant.wateringFrequency,
          PlantThresholds.defaultWateringFrequencyDays);
    });

    test('nextWatering calculates correctly', () {
      final lastWatered = DateTime(2026, 1, 28);
      final plant = Plant(
        userId: 'user123',
        name: 'Test Plant',
        lastWatered: lastWatered,
        wateringFrequency: 3,
      );

      final nextWatering = plant.nextWatering;
      expect(nextWatering, isNotNull);
      expect(nextWatering!.day, 31); // 28 + 3 = 31
    });

    test('nextWatering returns null when never watered', () {
      final plant = Plant(
        userId: 'user123',
        name: 'Never Watered',
      );

      expect(plant.nextWatering, isNull);
    });

    test('needsWatering returns true when never watered', () {
      final plant = Plant(
        userId: 'user123',
        name: 'Never Watered',
      );

      expect(plant.needsWatering, true);
    });

    test('needsWatering returns true when overdue', () {
      final lastWatered = DateTime.now().subtract(Duration(days: 10));
      final plant = Plant(
        userId: 'user123',
        name: 'Overdue Plant',
        lastWatered: lastWatered,
        wateringFrequency: 3,
      );

      expect(plant.needsWatering, true);
    });

    test('needsWatering returns false when not due yet', () {
      final lastWatered = DateTime.now();
      final plant = Plant(
        userId: 'user123',
        name: 'Recently Watered',
        lastWatered: lastWatered,
        wateringFrequency: 3,
      );

      expect(plant.needsWatering, false);
    });

    test('daysUntilNextWatering calculates correctly', () {
      final lastWatered = DateTime.now().subtract(Duration(days: 1));
      final plant = Plant(
        userId: 'user123',
        name: 'Test Plant',
        lastWatered: lastWatered,
        wateringFrequency: 3,
      );

      final days = plant.daysUntilNextWatering;
      expect(days, isNotNull);
      expect(days, greaterThanOrEqualTo(1));
      expect(days, lessThanOrEqualTo(3));
    });

    test('copyWith creates new instance with updated values', () {
      final original = Plant(
        id: 1,
        userId: 'user123',
        name: 'Original',
        wateringFrequency: 3,
      );

      final copy = original.copyWith(name: 'Updated');

      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.name, 'Updated');
      expect(copy.wateringFrequency, original.wateringFrequency);
    });
  });
}
