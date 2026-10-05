import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverOffer {
  final String id;
  final String driverName;
  final String driverVehicle;
  final String driverPlate;
  final double rating;
  final int totalRides;
  final double price;
  final String eta;
  final bool isCounterOffer;
  final double? driverLat;
  final double? driverLon;

  const DriverOffer({
    required this.id,
    required this.driverName,
    required this.driverVehicle,
    required this.driverPlate,
    required this.rating,
    required this.totalRides,
    required this.price,
    required this.eta,
    this.isCounterOffer = false,
    this.driverLat,
    this.driverLon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverName': driverName,
      'driverVehicle': driverVehicle,
      'driverPlate': driverPlate,
      'rating': rating,
      'totalRides': totalRides,
      'price': price,
      'eta': eta,
      'isCounterOffer': isCounterOffer,
      'driverLat': driverLat,
      'driverLon': driverLon,
    };
  }

  factory DriverOffer.fromMap(Map<String, dynamic> map) {
    return DriverOffer(
      id: map['id']?.toString() ?? '',
      driverName: map['driverName']?.toString() ?? 'Conductor',
      driverVehicle: map['driverVehicle']?.toString() ?? 'Bera SBR 150',
      driverPlate: map['driverPlate']?.toString() ?? 'AE5K82M',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      totalRides: (map['totalRides'] as num?)?.toInt() ?? 100,
      price: (map['price'] as num?)?.toDouble() ?? 2.0,
      eta: map['eta']?.toString() ?? '2 min',
      isCounterOffer: map['isCounterOffer'] == true,
      driverLat: (map['driverLat'] as num?)?.toDouble(),
      driverLon: (map['driverLon'] as num?)?.toDouble(),
    );
  }
}

class RideRequest {
  final String id;
  final String passengerName;
  final String passengerPhone; // Needed for FCM chat notifications to passenger
  final String pickupAddress;
  final LatLng pickupPoint;
  final String dropoffAddress;
  final LatLng dropoffPoint;
  final double offeredPrice;
  final String vehicleType;
  final String paymentMethod;
  final String note;
  final double distanceKm;
  String status; // 'searching', 'negotiating', 'accepted', 'in_progress', 'completed', 'cancelled'
  final List<DriverOffer> offers;
  DriverOffer? acceptedOffer;
  LatLng? currentDriverLocation;
  final DateTime createdAt;

  RideRequest({
    required this.id,
    required this.passengerName,
    this.passengerPhone = '',
    required this.pickupAddress,
    required this.pickupPoint,
    required this.dropoffAddress,
    required this.dropoffPoint,
    required this.offeredPrice,
    required this.vehicleType,
    required this.paymentMethod,
    this.note = '',
    required this.distanceKm,
    this.status = 'searching',
    List<DriverOffer>? offers,
    this.acceptedOffer,
    this.currentDriverLocation,
    DateTime? createdAt,
  })  : offers = offers ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupPoint.latitude,
      'pickupLon': pickupPoint.longitude,
      'dropoffAddress': dropoffAddress,
      'dropoffLat': dropoffPoint.latitude,
      'dropoffLon': dropoffPoint.longitude,
      'offeredPrice': offeredPrice,
      'vehicleType': vehicleType,
      'paymentMethod': paymentMethod,
      'note': note,
      'distanceKm': distanceKm,
      'status': status,
      'offers': offers.map((o) => o.toMap()).toList(),
      'acceptedOffer': acceptedOffer?.toMap(),
      'driverLat': currentDriverLocation?.latitude,
      'driverLon': currentDriverLocation?.longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RideRequest.fromMap(Map<String, dynamic> map, String docId) {
    final offersList = (map['offers'] as List<dynamic>?)
            ?.map((o) => DriverOffer.fromMap(o as Map<String, dynamic>))
            .toList() ??
        [];

    final acceptedMap = map['acceptedOffer'] as Map<String, dynamic>?;

    LatLng? driverLoc;
    if (map['driverLat'] != null && map['driverLon'] != null) {
      driverLoc = LatLng(
        (map['driverLat'] as num).toDouble(),
        (map['driverLon'] as num).toDouble(),
      );
    }

    return RideRequest(
      id: docId,
      passengerName: map['passengerName']?.toString() ?? 'Pasajero',
      passengerPhone: map['passengerPhone']?.toString() ?? '',
      pickupAddress: map['pickupAddress']?.toString() ?? 'Carúpano',
      pickupPoint: LatLng(
        (map['pickupLat'] as num?)?.toDouble() ?? 10.6678,
        (map['pickupLon'] as num?)?.toDouble() ?? -63.2585,
      ),
      dropoffAddress: map['dropoffAddress']?.toString() ?? 'Carúpano',
      dropoffPoint: LatLng(
        (map['dropoffLat'] as num?)?.toDouble() ?? 10.6710,
        (map['dropoffLon'] as num?)?.toDouble() ?? -63.3058,
      ),
      offeredPrice: (map['offeredPrice'] as num?)?.toDouble() ?? 2.50,
      vehicleType: map['vehicleType']?.toString() ?? 'moto',
      paymentMethod: map['paymentMethod']?.toString() ?? 'pago_movil',
      note: map['note']?.toString() ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 2.0,
      status: map['status']?.toString() ?? 'searching',
      offers: offersList,
      acceptedOffer: acceptedMap != null ? DriverOffer.fromMap(acceptedMap) : null,
      currentDriverLocation: driverLoc,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class RideService extends ChangeNotifier {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal() {
    _listenToFirestore();
  }

  final List<RideRequest> _rides = [];
  List<RideRequest> get activeRides =>
      _rides.where((r) => r.status != 'cancelled' && r.status != 'completed').toList();

  RideRequest? _currentPassengerRide;
  RideRequest? get currentPassengerRide => _currentPassengerRide;

  StreamSubscription? _firestoreSub;

  void _listenToFirestore() {
    try {
      _firestoreSub = FirebaseFirestore.instance
          .collection('rides')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots()
          .listen((snapshot) {
        // Rebuild the full list from Firestore on every snapshot
        final updatedRides = snapshot.docs
            .map((doc) => RideRequest.fromMap(doc.data(), doc.id))
            .toList();

        _rides
          ..clear()
          ..addAll(updatedRides);

        // Keep _currentPassengerRide in sync
        if (_currentPassengerRide != null) {
          final match = _rides.where((r) => r.id == _currentPassengerRide!.id);
          if (match.isNotEmpty) {
            _currentPassengerRide = match.first;
          }
        }

        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore real-time sync error: $e');
      });
    } catch (e) {
      debugPrint('Firestore initialization error: $e');
    }
  }

  Future<RideRequest> requestRide({
    required String passengerName,
    String passengerPhone = '',
    required String pickupAddress,
    required LatLng pickupPoint,
    required String dropoffAddress,
    required LatLng dropoffPoint,
    required double offeredPrice,
    required String vehicleType,
    required String paymentMethod,
    required double distanceKm,
    String note = '',
  }) async {
    // Generate a unique ID using timestamp
    final String id = 'ride_${DateTime.now().millisecondsSinceEpoch}';
    final newRide = RideRequest(
      id: id,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      pickupAddress: pickupAddress,
      pickupPoint: pickupPoint,
      dropoffAddress: dropoffAddress,
      dropoffPoint: dropoffPoint,
      offeredPrice: offeredPrice,
      vehicleType: vehicleType,
      paymentMethod: paymentMethod,
      distanceKm: distanceKm,
      note: note,
      status: 'searching',
    );

    // Optimistic local update while Firestore saves
    _rides.insert(0, newRide);
    _currentPassengerRide = newRide;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(id)
          .set(newRide.toMap());
      debugPrint('✅ Ride saved to Firestore: $id');
    } catch (e) {
      debugPrint('❌ Firestore ride save error: $e');
    }

    return newRide;
  }

  Future<void> submitDriverOffer({
    required String rideId,
    required DriverOffer offer,
  }) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      _rides[index].offers.add(offer);
      _rides[index].status = 'negotiating';
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
          'offers': _rides[index].offers.map((o) => o.toMap()).toList(),
          'status': 'negotiating',
        });
      } catch (e) {
        debugPrint('Firestore submit offer notice: ');
      }
    }
  }

  Future<void> acceptOffer({
    required String rideId,
    required DriverOffer offer,
    LatLng? driverLocation,
  }) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      _rides[index].acceptedOffer = offer;
      _rides[index].status = 'accepted';
      if (driverLocation != null) {
        _rides[index].currentDriverLocation = driverLocation;
      }
      if (_currentPassengerRide?.id == rideId) {
        _currentPassengerRide = _rides[index];
      }
      notifyListeners();

      try {
        final updateData = <String, dynamic>{
          'acceptedOffer': offer.toMap(),
          'status': 'accepted',
        };
        if (driverLocation != null) {
          updateData['driverLat'] = driverLocation.latitude;
          updateData['driverLon'] = driverLocation.longitude;
        }
        await FirebaseFirestore.instance.collection('rides').doc(rideId).update(updateData);
      } catch (e) {
        debugPrint('Firestore accept offer notice: $e');
      }
    }
  }

  Future<void> updateDriverLocation({
    required String rideId,
    required LatLng location,
  }) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      _rides[index].currentDriverLocation = location;
      if (_currentPassengerRide?.id == rideId) {
        _currentPassengerRide = _rides[index];
      }
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
          'driverLat': location.latitude,
          'driverLon': location.longitude,
        });
      } catch (e) {
        debugPrint('Firestore update driver location notice: $e');
      }
    }
  }

  Future<void> updateRideStatus({
    required String rideId,
    required String newStatus,
  }) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      _rides[index].status = newStatus;
      if (_currentPassengerRide?.id == rideId) {
        _currentPassengerRide = _rides[index];
      }
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
          'status': newStatus,
        });

        // 🧹 Si el viaje se finalizó o canceló, eliminar los mensajes efímeros del chat
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          _cleanRideChatMessages(rideId);
        }
      } catch (e) {
        debugPrint('Firestore update status notice: $e');
      }
    }
  }

  Future<void> _cleanRideChatMessages(String rideId) async {
    try {
      final messagesSnap = await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .get();
      for (final doc in messagesSnap.docs) {
        await doc.reference.delete();
      }
      debugPrint('🧹 Mensajes del chat eliminados para el viaje $rideId');
    } catch (e) {
      debugPrint('Error limpiando mensajes de chat: $e');
    }
  }

  Future<void> cancelRide(String rideId) async {
    await updateRideStatus(
      rideId: rideId,
      newStatus: 'cancelled',
    );
  }

  void cancelCurrentPassengerRide() {
    if (_currentPassengerRide != null) {
      updateRideStatus(
        rideId: _currentPassengerRide!.id,
        newStatus: 'cancelled',
      );
      _currentPassengerRide = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    super.dispose();
  }
}
