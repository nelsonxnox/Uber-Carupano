import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Solicitar permiso explícito en Android 13+
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      // Pre-registrar canal de chat
      const chatChannel = AndroidNotificationChannel(
        'chat_messages_channel',
        'Mensajes del Chat',
        description: 'Notificaciones de mensajes en el chat del viaje',
        importance: Importance.high,
      );
      await androidImplementation?.createNotificationChannel(chatChannel);

      _isInitialized = true;
      debugPrint('NotificationSoundService initialized successfully');
    } catch (e) {
      debugPrint('NotificationSoundService init error: $e');
    }
  }

  /// 🚨 ALERTA CHOFER: Nueva carrera disponible en el radar (Sonido + Vibración fuerte)
  Future<void> showNewRideAlert({
    required String rideId,
    required String passengerName,
    required String destination,
    required double offeredPrice,
  }) async {
    // Patrón de vibración tipo radar: vibra 500ms, pausa 250ms, vibra 500ms, pausa 250ms, vibra 1000ms
    final Int64List vibrationPattern = Int64List.fromList([0, 500, 250, 500, 250, 1000]);

    final androidDetails = AndroidNotificationDetails(
      'rides_radar_channel',
      'Alertas de Viajes (Radar)',
      channelDescription: 'Canal de máxima prioridad para solicitudes de carreras entrantes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: '¡Nueva carrera disponible!',
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        rideId.hashCode,
        '🚨 ¡Nueva Carrera! \$${offeredPrice.toStringAsFixed(2)} USD',
        '$passengerName solicita viaje hacia $destination',
        notificationDetails,
        payload: 'ride_$rideId',
      );
    } catch (e) {
      debugPrint('Error showing new ride alert: $e');
    }
  }

  /// 💬 ALERTA PASAJERO: Un conductor envió una oferta o contraoferta
  Future<void> showDriverOfferAlert({
    required String driverName,
    required String vehicle,
    required double price,
    required bool isCounterOffer,
  }) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 300, 200, 300]);

    final androidDetails = AndroidNotificationDetails(
      'driver_offers_channel',
      'Ofertas de Conductores',
      channelDescription: 'Avisos de mototaxistas y taxistas disponibles o contraofertas',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
      category: AndroidNotificationCategory.message,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final title = isCounterOffer
        ? '💬 Contraoferta de $driverName: \$${price.toStringAsFixed(2)}'
        : '🛵 ¡$driverName aceptó tu tarifa!';
    final body = '$vehicle • Toca para revisar y aceptar';

    try {
      await _notificationsPlugin.show(
        driverName.hashCode,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing driver offer alert: $e');
    }
  }

  /// 📍 ALERTA PASAJERO: El conductor ya llegó al punto de recogida
  Future<void> showDriverArrivedAlert({
    required String driverName,
    required String vehicle,
  }) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 400, 150, 400, 150, 400]);

    final androidDetails = AndroidNotificationDetails(
      'trip_status_channel',
      'Estado del Viaje en Vivo',
      channelDescription: 'Avisos de llegada del conductor y progreso de viaje',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
      category: AndroidNotificationCategory.status,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        999,
        '📍 ¡Tu conductor ha llegado!',
        '$driverName está esperándote afuera en su $vehicle.',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing driver arrived alert: $e');
    }
  }

  /// 🏁 ALERTA VIAJE COMPLETADO
  Future<void> showTripCompletedAlert({
    required double finalPrice,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'trip_status_channel',
      'Estado del Viaje en Vivo',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        1000,
        '🏁 ¡Llegaste a tu destino!',
        'Total del servicio: \$${finalPrice.toStringAsFixed(2)} USD. ¡Califica tu viaje!',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing completed alert: $e');
    }
  }
}
