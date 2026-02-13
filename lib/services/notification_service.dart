import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          AppLogger.info('Notificación tocada: ${details.payload}');
        },
      );

      // Solicitar permisos en iOS
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      _initialized = true;
      AppLogger.info('✅ Servicio de notificaciones inicializado');
    } catch (e) {
      AppLogger.error('❌ Error inicializando notificaciones', e);
    }
  }

  Future<void> showRecommendationNotification({
    required String recommendation,
    required String priority, // 'high', 'medium', 'low'
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'plant_recommendations',
      'Recomendaciones de Plantas',
      channelDescription: 'Notificaciones sobre el estado de tus plantas',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        0, // ID de la notificación
        '🌱 Estado de tu Planta',
        recommendation,
        details,
        payload: recommendation,
      );
      AppLogger.info('✅ Notificación mostrada: $recommendation');
    } catch (e) {
      AppLogger.error('❌ Error mostrando notificación', e);
    }
  }
}
