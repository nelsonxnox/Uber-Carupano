import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para registrar y sincronizar los Device Tokens (FCM)
/// de pasajeros y conductores en Firestore.
/// Permite enviar notificaciones push directas cuando el teléfono está bloqueado o en reposo.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  static const String _tokenPrefKey = 'cached_device_fcm_token';

  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Inicializa el servicio y recupera o genera un token de dispositivo
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentToken = prefs.getString(_tokenPrefKey);

      // Si no existe un token previo, generamos uno representativo de este dispositivo
      if (_currentToken == null) {
        _currentToken = 'tok_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
        await prefs.setString(_tokenPrefKey, _currentToken!);
      }
      debugPrint('📲 FCM Device Token inicializado: $_currentToken');
    } catch (e) {
      debugPrint('Error inicializando PushNotificationService: $e');
    }
  }

  /// Vincula el token del teléfono al usuario o chofer en Firestore
  Future<void> syncUserToken({
    required String userId,
    required bool isDriver,
    String? phone,
  }) async {
    if (_currentToken == null) await init();
    if (_currentToken == null) return;

    try {
      final data = {
        'fcmToken': _currentToken,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'android',
      };

      if (isDriver) {
        // Guardar en la colección de choferes
        await FirebaseFirestore.instance.collection('drivers').doc(userId).set(
          data,
          SetOptions(merge: true),
        );
        debugPrint('✅ FCM Token sincronizado para conductor: $userId');
      } else {
        // Guardar en la colección de usuarios/pasajeros
        final docRef = (phone != null && phone.isNotEmpty)
            ? FirebaseFirestore.instance.collection('users').doc(phone)
            : FirebaseFirestore.instance.collection('users').doc(userId);

        await docRef.set(data, SetOptions(merge: true));
        debugPrint('✅ FCM Token sincronizado para pasajero: $userId');
      }
    } catch (e) {
      debugPrint('Error sincronizando FCM Token en Firestore: $e');
    }
  }

  /// Obtiene el token FCM registrado del destinatario (para enviar push)
  Future<String?> getRecipientToken({
    required String recipientId,
    required bool isDriver,
  }) async {
    try {
      final col = isDriver ? 'drivers' : 'users';
      final doc = await FirebaseFirestore.instance.collection(col).doc(recipientId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['fcmToken']?.toString();
      }
    } catch (e) {
      debugPrint('Error obteniendo token FCM de destinatario: $e');
    }
    return null;
  }
}
