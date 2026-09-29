import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class DriverProfile {
  final String id;
  final String fullName;
  final String phone;
  final String vehicleType; // 'moto' | 'auto'
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final double rating;
  final int totalRides;

  DriverProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    this.rating = 5.0,
    this.totalRides = 0,
  });

  String get vehicleDescription => '$vehicleModel ($vehicleColor)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehiclePlate': vehiclePlate,
      'rating': rating,
      'totalRides': totalRides,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory DriverProfile.fromMap(Map<String, dynamic> map, String id) {
    return DriverProfile(
      id: id,
      fullName: map['fullName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      vehicleType: map['vehicleType']?.toString() ?? 'moto',
      vehicleModel: map['vehicleModel']?.toString() ?? '',
      vehicleColor: map['vehicleColor']?.toString() ?? '',
      vehiclePlate: map['vehiclePlate']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      totalRides: (map['totalRides'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverProfileService {
  static final DriverProfileService _instance = DriverProfileService._internal();
  factory DriverProfileService() => _instance;
  DriverProfileService._internal();

  DriverProfile? _currentProfile;
  DriverProfile? get currentProfile => _currentProfile;

  String _prefKeyForUser(String userId) => 'driver_profile_user_$userId';

  void resetMemory() {
    _currentProfile = null;
  }

  /// Carga el perfil del chofer perteneciente EXCLUSIVAMENTE a este usuario.
  Future<DriverProfile?> loadProfile([String? targetUserId]) async {
    final userId = targetUserId ?? AuthService().currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _currentProfile = null;
      return null;
    }

    final prefs = await SharedPreferences.getInstance();

    // 1. Limpiar keys legacy antiguas para que no interfieran entre usuarios
    if (prefs.containsKey('driver_profile_id')) {
      await prefs.remove('driver_profile_id');
      await prefs.remove('driver_profile_name');
    }

    // 2. Intentar cargar desde SharedPreferences específico de este usuario
    final rawJson = prefs.getString(_prefKeyForUser(userId));
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final map = json.decode(rawJson) as Map<String, dynamic>;
        _currentProfile = DriverProfile.fromMap(map, userId);
        return _currentProfile;
      } catch (e) {
        debugPrint('Error parseando driver_profile local: $e');
      }
    }

    // 3. Buscar en Firestore en la colección drivers/{userId}
    try {
      final doc = await FirebaseFirestore.instance.collection('drivers').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final profile = DriverProfile.fromMap(doc.data()!, userId);
        _currentProfile = profile;
        await prefs.setString(_prefKeyForUser(userId), json.encode(profile.toMap()));
        return _currentProfile;
      }
    } catch (e) {
      debugPrint('Error cargando conductor de Firestore: $e');
    }

    _currentProfile = null;
    return null;
  }

  /// Guarda el perfil del chofer vinculado a la cuenta del usuario
  Future<void> saveProfile(DriverProfile profile, {String? userId}) async {
    final effectiveUserId = userId ?? profile.id;
    _currentProfile = profile;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyForUser(effectiveUserId), json.encode(profile.toMap()));

    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(effectiveUserId)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando perfil de chofer en Firestore: $e');
    }
  }

  Future<void> clearProfile([String? targetUserId]) async {
    final userId = targetUserId ?? AuthService().currentUser?.id;
    _currentProfile = null;
    if (userId != null && userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyForUser(userId));
    }
  }
}
