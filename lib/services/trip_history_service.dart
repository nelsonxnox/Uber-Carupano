import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompletedTrip {
  final String id;
  final String passengerName;
  final String pickupAddress;
  final String dropoffAddress;
  final double price;
  final double distanceKm;
  final DateTime timestamp;
  final double passengerRating;
  final String paymentMethod;

  const CompletedTrip({
    required this.id,
    required this.passengerName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.price,
    required this.distanceKm,
    required this.timestamp,
    this.passengerRating = 0,
    this.paymentMethod = 'efectivo',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'passengerName': passengerName,
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'price': price,
        'distanceKm': distanceKm,
        'timestamp': timestamp.toIso8601String(),
        'passengerRating': passengerRating,
        'paymentMethod': paymentMethod,
      };

  factory CompletedTrip.fromMap(Map<String, dynamic> m) => CompletedTrip(
        id: m['id']?.toString() ?? '',
        passengerName: m['passengerName']?.toString() ?? 'Pasajero',
        pickupAddress: m['pickupAddress']?.toString() ?? '',
        dropoffAddress: m['dropoffAddress']?.toString() ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
        timestamp: m['timestamp'] != null
            ? DateTime.tryParse(m['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        passengerRating: (m['passengerRating'] as num?)?.toDouble() ?? 0,
        paymentMethod: m['paymentMethod']?.toString() ?? 'efectivo',
      );
}

class TripHistoryService extends ChangeNotifier {
  static final TripHistoryService _instance = TripHistoryService._();
  factory TripHistoryService() => _instance;
  TripHistoryService._();

  final List<CompletedTrip> _trips = [];

  List<CompletedTrip> get trips => List.unmodifiable(_trips);

  double get totalEarnings =>
      _trips.fold(0.0, (acc, t) => acc + t.price);

  double get averageRating {
    final rated = _trips.where((t) => t.passengerRating > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.fold(0.0, (acc, t) => acc + t.passengerRating) / rated.length;
  }

  String _prefKey(String driverId) => 'driver_trip_history_$driverId';

  Future<void> load([String? driverId]) async {
    _trips.clear();
    if (driverId == null || driverId.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey(driverId));
      if (raw != null) {
        final list = json.decode(raw) as List<dynamic>;
        _trips.clear();
        _trips.addAll(list.map((e) => CompletedTrip.fromMap(e as Map<String, dynamic>)));
        _trips.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TripHistoryService load error: $e');
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('trips')
          .orderBy('timestamp', descending: true)
          .get();
      if (snap.docs.isNotEmpty) {
        _trips.clear();
        _trips.addAll(snap.docs.map((d) => CompletedTrip.fromMap(d.data())));
        notifyListeners();
        await _persist(driverId);
      }
    } catch (_) {}
  }

  Future<void> addTrip({
    required String driverId,
    required CompletedTrip trip,
  }) async {
    _trips.insert(0, trip);
    notifyListeners();
    await _persist(driverId);
    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('trips')
          .doc(trip.id)
          .set(trip.toMap());
    } catch (e) {
      debugPrint('TripHistoryService Firestore error: $e');
    }
  }

  Future<void> updateLatestTripRating({
    required String driverId,
    required double rating,
  }) async {
    // Actualizar en memoria local (cuando lo llama el mismo chofer)
    if (_trips.isNotEmpty) {
      final latest = _trips.first;
      final updated = CompletedTrip(
        id: latest.id,
        passengerName: latest.passengerName,
        pickupAddress: latest.pickupAddress,
        dropoffAddress: latest.dropoffAddress,
        price: latest.price,
        distanceKm: latest.distanceKm,
        timestamp: latest.timestamp,
        passengerRating: rating,
        paymentMethod: latest.paymentMethod,
      );
      _trips[0] = updated;
      notifyListeners();
      await _persist(driverId);
    }

    final db = FirebaseFirestore.instance;

    // 1. Actualizar el passengerRating en el viaje específico
    try {
      final snap = await db
          .collection('drivers')
          .doc(driverId)
          .collection('trips')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({'passengerRating': rating});
        debugPrint('TripHistoryService: rating $rating guardado en viaje.');
      }
    } catch (e) {
      debugPrint('TripHistoryService Firestore trip rating error: $e');
    }

    // 2. Recalcular y actualizar el rating global del chofer en su perfil
    // usando una transacción atómica para evitar race conditions
    try {
      final driverRef = db.collection('drivers').doc(driverId);
      await db.runTransaction((tx) async {
        final driverSnap = await tx.get(driverRef);
        if (!driverSnap.exists) return;
        final data = driverSnap.data()!;
        final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;

        // Promedio acumulado: ((rating_actual * total) + nuevo) / (total + 1)
        final newTotal = totalRatings + 1;
        final newRating = totalRatings == 0
            ? rating
            : ((currentRating * totalRatings) + rating) / newTotal;

        tx.update(driverRef, {
          'rating': double.parse(newRating.toStringAsFixed(2)),
          'totalRatings': newTotal,
        });
        debugPrint(
            'Rating chofer actualizado: $currentRating → ${newRating.toStringAsFixed(2)} ($newTotal calificaciones)');
      });
    } catch (e) {
      debugPrint('TripHistoryService Firestore driver rating update error: $e');
    }
  }

  Future<void> _persist(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(driverId), json.encode(_trips.map((t) => t.toMap()).toList()));
    } catch (e) {
      debugPrint('TripHistoryService persist error: $e');
    }
  }
}
