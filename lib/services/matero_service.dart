import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../models/plant.dart';
import '../models/sensor_reading.dart';
import '../config/constants.dart';

class MateroService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String> uploadPlantImage(File imageFile) async {
    try {
      AppLogger.info('📤 Iniciando subida de imagen...');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el archivo existe
      if (!await imageFile.exists()) {
        throw Exception('El archivo de imagen no existe');
      }

      // Leer el archivo como bytes
      final bytes = await imageFile.readAsBytes();
      final fileSize = bytes.length;
      AppLogger.info('📦 Tamaño del archivo: ${fileSize / 1024} KB');

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      AppLogger.info('📁 Subiendo a: $fileName');

      // Subir los bytes en lugar del File directamente
      await _supabase.storage.from(AppConstants.plantImagesBucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage
          .from(AppConstants.plantImagesBucket)
          .getPublicUrl(fileName);

      AppLogger.info('✅ Imagen subida exitosamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      AppLogger.error('❌ Error subiendo imagen', e);
      rethrow;
    }
  }

  // PLANTA

  Future<List<Plant>> getPlants() async {
    try {
      final response = await _supabase
          .from(AppConstants.plantsTable)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error obteniendo plantas', e);
      rethrow;
    }
  }

  Future<void> addPlant(
      String name, String? imageUrl, String? description) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _supabase.from(AppConstants.plantsTable).insert({
        'user_id': user.id,
        'name': name,
        'image_url': imageUrl,
        'description': description,
      });
      AppLogger.info('✅ Planta agregada: $name');
    } catch (e) {
      AppLogger.error('❌ Error agregando planta', e);
      rethrow;
    }
  }

  Future<void> updatePlant(
      int id, String name, String? imageUrl, String? description) async {
    try {
      await _supabase.from(AppConstants.plantsTable).update({
        'name': name,
        'image_url': imageUrl,
        'description': description,
      }).eq('id', id);
      AppLogger.info('✅ Planta actualizada: $name');
    } catch (e) {
      AppLogger.error('❌ Error actualizando planta', e);
      rethrow;
    }
  }

  Future<void> deletePlant(int id) async {
    try {
      await _supabase.from(AppConstants.plantsTable).delete().eq('id', id);
      AppLogger.info('✅ Planta eliminada: $id');
    } catch (e) {
      AppLogger.error('❌ Error eliminando planta', e);
      rethrow;
    }
  }

  Future<void> waterPlant(int id) async {
    try {
      await _supabase.from(AppConstants.plantsTable).update({
        'last_watered': DateTime.now().toIso8601String(),
      }).eq('id', id);
      AppLogger.info('✅ Planta regada: $id');
    } catch (e) {
      AppLogger.error('❌ Error regando planta', e);
      rethrow;
    }
  }

  Future<void> linkDeviceToPlant(int plantId, String deviceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Intentar registrar el dispositivo si no existe (Provisionamiento)
      try {
        await _supabase.from('devices').upsert({
          'id': deviceId,
          'user_id': user.id,
        });
      } catch (e) {
        AppLogger.warning('⚠️ El dispositivo ya podría estar registrado: $e');
        // Continuamos, asumiendo que el error fue por duplicado o permisos,
        // pero intentaremos vincularlo a la planta de todos modos.
      }

      // Vincular a la planta
      await _supabase.from(AppConstants.plantsTable).update({
        'device_id': deviceId,
      }).eq('id', plantId);

      AppLogger.info('✅ Dispositivo $deviceId vinculado a planta $plantId');
    } catch (e) {
      AppLogger.error('❌ Error vinculando dispositivo', e);
      rethrow;
    }
  }

  // LECTURA DE DATOS

  Future<void> saveSensorData(
      int plantId, Map<String, dynamic> sensorData) async {
    try {
      final dataToSave = Map<String, dynamic>.from(sensorData);
      dataToSave['plant_id'] = plantId;

      await _supabase.from(AppConstants.readingsTable).insert(dataToSave);
      AppLogger.debug('✅ Datos guardados para planta $plantId');
    } catch (e) {
      AppLogger.error('❌ Error guardando datos', e);
      rethrow;
    }
  }

  // Stream de datos en tiempo real - TODOS LOS DATOS DEL ESP32
  Stream<SensorReading?> getRealtimeData() {
    return _supabase
        .from(AppConstants.readingsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) return null;
          return SensorReading.fromJson(data.first);
        })
        .handleError((error) {
          AppLogger.error('❌ Error en stream de datos', error);
          return null;
        });
  }

  // Obtener última lectura - TODOS LOS DATOS
  Future<SensorReading?> getLatestReading() async {
    try {
      final response = await _supabase
          .from(AppConstants.readingsTable)
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return SensorReading.fromJson(response);
    } catch (e) {
      AppLogger.error('❌ Error obteniendo última lectura', e);
      return null;
    }
  }

  String getRecommendation(int soilMoisture, double temperature) {
    if (soilMoisture < PlantThresholds.criticalSoilMoisture) {
      return '🚨 RIEGO URGENTE - Tierra muy seca';
    } else if (soilMoisture < PlantThresholds.lowSoilMoisture) {
      return '💧 RIEGO PRÓXIMO - En las próximas horas';
    } else if (temperature > PlantThresholds.highTemperature) {
      return '🌡️ Mover a sombra - Temperatura alta';
    } else if (soilMoisture > PlantThresholds.excessWater) {
      return '⚠️ EXCESO DE AGUA - Reducir riego';
    } else {
      return '✅ ESTADO ÓPTIMO - Todo en orden';
    }
  }
}
