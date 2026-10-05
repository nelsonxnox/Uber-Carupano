import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  String? _cachedToken;

  /// Inicializa FCM y solicita permiso en iOS/web.
  /// En web no hay tokens para push background, así que simplemente retorna.
  Future<void> init() async {
    if (kIsWeb) return; // Web no soporta push background
    try {
      final messaging = FirebaseMessaging.instance;

      // Solicita permiso (obligatorio en iOS, sin efecto en Android)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Obtiene el token real del dispositivo
      _cachedToken = await messaging.getToken();
      debugPrint('[FCM] Token obtenido: $_cachedToken');

      // Escucha refrescos de token (el SO puede rotar el token)
      messaging.onTokenRefresh.listen((newToken) {
        _cachedToken = newToken;
        debugPrint('[FCM] Token refrescado: $newToken');
      });
    } catch (e) {
      debugPrint('[FCM] Error en init: $e');
    }
  }

  /// Guarda el token en Firestore bajo el perfil del usuario/chofer.
  Future<void> syncUserToken({
    required String userId,
    required bool isDriver,
    String phone = '',
  }) async {
    if (kIsWeb) return;
    final token = _cachedToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      if (isDriver) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(userId)
            .set({'fcmToken': token}, SetOptions(merge: true));
      } else {
        final targetDoc = phone.isNotEmpty ? phone : userId;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetDoc)
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
      debugPrint('[FCM] Token sincronizado para ${isDriver ? "driver" : "user"} $userId');
    } catch (e) {
      debugPrint('[FCM] Error sincronizando token: $e');
    }
  }

  /// Obtiene el token FCM del destinatario desde Firestore.
  Future<String?> getRecipientToken(String recipientId, bool isDriver) async {
    try {
      final col = isDriver ? 'drivers' : 'users';
      final doc = await FirebaseFirestore.instance
          .collection(col)
          .doc(recipientId)
          .get();
      return doc.data()?['fcmToken'] as String?;
    } catch (e) {
      debugPrint('[FCM] Error obteniendo token del destinatario: $e');
      return null;
    }
  }
}
