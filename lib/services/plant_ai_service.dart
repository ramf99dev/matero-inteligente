import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

class PlantAIService {
  static final PlantAIService _instance = PlantAIService._internal();
  factory PlantAIService() => _instance;
  PlantAIService._internal();

  GenerativeModel? _model;

  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      AppLogger.warning('⚠️ GEMINI_API_KEY no configurada en .env');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
    );
    AppLogger.info('✅ Servicio de IA de plantas inicializado');
  }

  Future<String> getPlantInfo(String plantName) async {
    if (_model == null) {
      throw Exception(
          'Servicio de IA no inicializado. Por favor configura GEMINI_API_KEY en el archivo .env');
    }

    try {
      AppLogger.info('🤖 Consultando información sobre: $plantName');

      final prompt = '''
Proporciona información detallada y práctica sobre la planta: "$plantName"

Incluye:
1. 🌿 Nombre científico y familia
2. 📍 Origen y hábitat natural
3. 💧 Necesidades de riego (frecuencia y cantidad)
4. ☀️ Requerimientos de luz
5. 🌡️ Temperatura ideal
6. 🌱 Tipo de suelo recomendado
7. 🪴 Cuidados especiales
8. ⚠️ Problemas comunes y soluciones
9. 🌸 Época de floración (si aplica)
10. 💡 Consejos adicionales

Responde en español de forma clara, concisa y práctica. Usa emojis para hacer la información más visual y atractiva, que no se vean asteriscos ni signos no deseados a la visualidad de usuario.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No se recibió información de la IA');
      }

      AppLogger.info('✅ Información recibida exitosamente');
      return response.text!;
    } catch (e) {
      AppLogger.error('❌ Error consultando IA', e);
      rethrow;
    }
  }
}
