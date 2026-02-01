import 'package:flutter_test/flutter_test.dart';
import 'package:matero_fixed/services/matero_service.dart';
import 'package:matero_fixed/config/constants.dart';

void main() {
  group('MateroService', () {
    late MateroService service;

    setUp(() {
      service = MateroService();
    });

    group('getRecommendation', () {
      test('returns urgent watering for critical soil moisture', () {
        final result = service.getRecommendation(20, 25.0);
        expect(result, contains('RIEGO URGENTE'));
        expect(result, contains('🚨'));
      });

      test('returns watering soon for low soil moisture', () {
        final result = service.getRecommendation(35, 25.0);
        expect(result, contains('RIEGO PRÓXIMO'));
        expect(result, contains('💧'));
      });

      test('returns move to shade for high temperature', () {
        final result = service.getRecommendation(50, 35.0);
        expect(result, contains('Mover a sombra'));
        expect(result, contains('🌡️'));
      });

      test('returns excess water warning for high soil moisture', () {
        final result = service.getRecommendation(85, 25.0);
        expect(result, contains('EXCESO DE AGUA'));
        expect(result, contains('⚠️'));
      });

      test('returns optimal state for normal conditions', () {
        final result = service.getRecommendation(50, 25.0);
        expect(result, contains('ESTADO ÓPTIMO'));
        expect(result, contains('✅'));
      });

      test('uses correct thresholds from constants', () {
        // Test critical threshold
        final critical = service.getRecommendation(
            PlantThresholds.criticalSoilMoisture - 1, 25.0);
        expect(critical, contains('RIEGO URGENTE'));

        // Test low threshold
        final low = service.getRecommendation(
            PlantThresholds.lowSoilMoisture - 1, 25.0);
        expect(low, contains('RIEGO PRÓXIMO'));

        // Test high temperature threshold
        final highTemp =
            service.getRecommendation(50, PlantThresholds.highTemperature + 1);
        expect(highTemp, contains('Mover a sombra'));

        // Test excess water threshold
        final excess =
            service.getRecommendation(PlantThresholds.excessWater + 1, 25.0);
        expect(excess, contains('EXCESO DE AGUA'));
      });
    });
  });
}
