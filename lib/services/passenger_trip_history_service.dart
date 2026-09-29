import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerCompletedTrip {
  final String id;
  final String driverName;
  final String driverVehicle;
  final String driverPlate;
  final String pickupAddress;
  final String dropoffAddress;
  final double price;
  final double distanceKm;
  final DateTime timestamp;
  final double rating;
  final String paymentMethod;

  const PassengerCompletedTrip({
    required this.id,
    required this.driverName,
    required this.driverVehicle,
    required this.driverPlate,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.price,
    required this.distanceKm,
    required this.timestamp,
    this.rating = 5.0,
    this.paymentMethod = 'efectivo',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'driverName': driverName,
        'driverVehicle': driverVehicle,
        'driverPlate': driverPlate,
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'price': price,
        'distanceKm': distanceKm,
        'timestamp': timestamp.toIso8601String(),
        'rating': rating,
        'paymentMethod': paymentMethod,
      };

  factory PassengerCompletedTrip.fromMap(Map<String, dynamic> m) =>
      PassengerCompletedTrip(
        id: m['id']?.toString() ?? '',
        driverName: m['driverName']?.toString() ?? 'Conductor',
        driverVehicle: m['driverVehicle']?.toString() ?? 'Vehículo',
        driverPlate: m['driverPlate']?.toString() ?? '',
        pickupAddress: m['pickupAddress']?.toString() ?? 'Origen',
        dropoffAddress: m['dropoffAddress']?.toString() ?? 'Destino',
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
        distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0.0,
        timestamp: m['timestamp'] != null
            ? DateTime.tryParse(m['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        paymentMethod: m['paymentMethod']?.toString() ?? 'efectivo',
      );
}

class PassengerTripHistoryService extends ChangeNotifier {
  static final PassengerTripHistoryService _instance =
      PassengerTripHistoryService._();
  factory PassengerTripHistoryService() => _instance;
  PassengerTripHistoryService._();

  final List<PassengerCompletedTrip> _trips = [];

  List<PassengerCompletedTrip> get trips => List.unmodifiable(_trips);
  int get totalTrips => _trips.length;
  double get totalSpent => _trips.fold(0.0, (acc, t) => acc + t.price);

  String _prefKey(String userId) => 'passenger_trip_history_$userId';

  Future<void> load(String userId) async {
    if (userId.isEmpty) return;

    // 1. Cargar desde SharedPreferences (rápido / offline)
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey(userId));
      if (raw != null) {
        final list = json.decode(raw) as List<dynamic>;
        _trips.clear();
        _trips.addAll(list.map((e) =>
            PassengerCompletedTrip.fromMap(e as Map<String, dynamic>)));
        _trips.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PassengerTripHistoryService local load error: $e');
    }

    // 2. Sincronizar desde Firestore en la nube (colección users/{userId}/trips)
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips')
          .orderBy('timestamp', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        final cloudTrips = snap.docs
            .map((d) => PassengerCompletedTrip.fromMap(d.data()))
            .toList();
        _trips.clear();
        _trips.addAll(cloudTrips);
        notifyListeners();
        await _persistLocally(userId);
      }
    } catch (e) {
      debugPrint('PassengerTripHistoryService cloud load notice: $e');
    }
  }

  Future<void> addTrip({
    required String userId,
    required PassengerCompletedTrip trip,
  }) async {
    _trips.removeWhere((t) => t.id == trip.id);
    _trips.insert(0, trip);
    notifyListeners();
    await _persistLocally(userId);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(trip.id)
          .set(trip.toMap(), SetOptions(merge: true));
      debugPrint('✅ Viaje guardado en el perfil del usuario: ${trip.id}');
    } catch (e) {
      debugPrint('Error guardando viaje en Firestore de usuario: $e');
    }
  }

  /// Actualiza la calificación del último viaje guardado del pasajero.
  Future<void> updateLatestTripRating({
    required String userId,
    required double rating,
  }) async {
    if (_trips.isEmpty) return;
    final latest = _trips.first;
    final updated = PassengerCompletedTrip(
      id: latest.id,
      driverName: latest.driverName,
      driverVehicle: latest.driverVehicle,
      driverPlate: latest.driverPlate,
      pickupAddress: latest.pickupAddress,
      dropoffAddress: latest.dropoffAddress,
      price: latest.price,
      distanceKm: latest.distanceKm,
      timestamp: latest.timestamp,
      paymentMethod: latest.paymentMethod,
      rating: rating,
    );
    _trips[0] = updated;
    notifyListeners();
    await _persistLocally(userId);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(updated.id)
          .set(updated.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('PassengerTripHistoryService Firestore rating error: $e');
    }
  }

  Future<void> _persistLocally(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_trips.map((t) => t.toMap()).toList());
      await prefs.setString(_prefKey(userId), encoded);
    } catch (e) {
      debugPrint('Error persistiendo historial local de pasajero: $e');
    }
  }
}
