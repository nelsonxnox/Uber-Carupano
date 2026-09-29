import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final DateTime registeredAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.registeredAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'registeredAt': registeredAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        registeredAt: map['registeredAt'] != null
            ? DateTime.tryParse(map['registeredAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const String _prefUserKey = 'registered_passenger_user';
  UserProfile? _currentUser;
  bool _isInitialized = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefUserKey);
      if (raw != null) {
        _currentUser = UserProfile.fromMap(json.decode(raw));
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
  }

  Future<void> registerPassenger({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final String cleanPhone = phone.trim();
    String userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';

    // Si ya existía este usuario en Firestore, preservar su ID original
    try {
      final existingDoc = await FirebaseFirestore.instance.collection('users').doc(cleanPhone).get();
      if (existingDoc.exists && existingDoc.data()?['id'] != null) {
        userId = existingDoc.data()!['id'].toString();
      }
    } catch (_) {}

    final newUser = UserProfile(
      id: userId,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phone: cleanPhone,
      registeredAt: DateTime.now(),
    );

    _currentUser = newUser;
    notifyListeners();

    // 1. Guardar localmente en el teléfono
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserKey, json.encode(newUser.toMap()));
    } catch (e) {
      debugPrint('Error saving user locally: $e');
    }

    // 2. Sincronizar en Firebase Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanPhone.isNotEmpty ? cleanPhone : userId)
          .set(newUser.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
    }
  }

  /// Permite a un usuario ya registrado iniciar sesión con su teléfono
  Future<UserProfile?> loginWithPhone(String phone) async {
    final String trimmed = phone.trim();
    final String cleanDigits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    final String fullPhone = trimmed.startsWith('+58') ? trimmed : '+58 $trimmed';

    try {
      // 1. Buscar directamente por doc ID
      var doc = await FirebaseFirestore.instance.collection('users').doc(fullPhone).get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('users').doc(trimmed).get();
      }

      // 2. Si no coincide el ID exacto, buscar en la colección comparando dígitos
      if (!doc.exists) {
        final querySnap = await FirebaseFirestore.instance.collection('users').get();
        for (final d in querySnap.docs) {
          final data = d.data();
          final storedPhone = data['phone']?.toString() ?? '';
          final storedDigits = storedPhone.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanDigits.isNotEmpty && storedDigits.isNotEmpty) {
            if (storedDigits.endsWith(cleanDigits) || cleanDigits.endsWith(storedDigits)) {
              doc = d;
              break;
            }
          }
        }
      }

      if (doc.exists && doc.data() != null) {
        final user = UserProfile.fromMap(doc.data()!);
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefUserKey, json.encode(user.toMap()));
        notifyListeners();
        return user;
      }
    } catch (e) {
      debugPrint('Error en loginWithPhone: $e');
    }
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUserKey);
    } catch (_) {}
  }
}
