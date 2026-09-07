import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _prefKeyId = 'driver_profile_id';
  static const String _prefKeyName = 'driver_profile_name';
  static const String _prefKeyPhone = 'driver_profile_phone';
  static const String _prefKeyVehicleType = 'driver_profile_v_type';
  static const String _prefKeyVehicleModel = 'driver_profile_v_model';
  static const String _prefKeyVehicleColor = 'driver_profile_v_color';
  static const String _prefKeyVehiclePlate = 'driver_profile_v_plate';

  Future<DriverProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKeyId);
    final name = prefs.getString(_prefKeyName);

    if (id == null || name == null || name.trim().isEmpty) {
      _currentProfile = null;
      return null;
    }

    _currentProfile = DriverProfile(
      id: id,
      fullName: name,
      phone: prefs.getString(_prefKeyPhone) ?? '',
      vehicleType: prefs.getString(_prefKeyVehicleType) ?? 'moto',
      vehicleModel: prefs.getString(_prefKeyVehicleModel) ?? '',
      vehicleColor: prefs.getString(_prefKeyVehicleColor) ?? '',
      vehiclePlate: prefs.getString(_prefKeyVehiclePlate) ?? '',
    );

    return _currentProfile;
  }

  Future<void> saveProfile(DriverProfile profile) async {
    _currentProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyId, profile.id);
    await prefs.setString(_prefKeyName, profile.fullName);
    await prefs.setString(_prefKeyPhone, profile.phone);
    await prefs.setString(_prefKeyVehicleType, profile.vehicleType);
    await prefs.setString(_prefKeyVehicleModel, profile.vehicleModel);
    await prefs.setString(_prefKeyVehicleColor, profile.vehicleColor);
    await prefs.setString(_prefKeyVehiclePlate, profile.vehiclePlate);

    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(profile.id)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> clearProfile() async {
    _currentProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyId);
    await prefs.remove(_prefKeyName);
    await prefs.remove(_prefKeyPhone);
    await prefs.remove(_prefKeyVehicleType);
    await prefs.remove(_prefKeyVehicleModel);
    await prefs.remove(_prefKeyVehicleColor);
    await prefs.remove(_prefKeyVehiclePlate);
  }
}
