import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../theme/beach_colors.dart';
import '../../services/ride_service.dart';
import '../../services/driver_profile_service.dart';
import '../../services/trip_history_service.dart';
import '../../services/notification_sound_service.dart';
import '../../services/auth_service.dart';
import 'driver_register_screen.dart';
import 'driver_finances_sheet.dart';
import '../shared/live_chat_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToPassenger;
  const DriverHomeScreen({super.key, required this.onSwitchToPassenger});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final MapController _mapController = MapController();
  final RideService _rideService = RideService();
  final DriverProfileService _profileService = DriverProfileService();
  final TripHistoryService _tripHistory = TripHistoryService();

  bool _isLoadingProfile = true;
  DriverProfile? _profile;

  bool isOnline = true;
  double driverWallet = 0.00; // Saldo en dólares

  LatLng _driverLocation = const LatLng(10.6690, -63.2575);
  StreamSubscription<Position>? _gpsStreamSub;

  RideRequest? _inspectedRide;
  List<LatLng> _inspectedRoutePoints = [];

  RideRequest? _activeAcceptedRide;
  String _activeRideStep = 'heading_to_pickup'; // 'heading_to_pickup', 'arrived', 'in_trip', 'completed'

  // Ruta activa: chofer→recogida (heading) o recogida→destino (in_trip)
  List<LatLng> _activeRoutePoints = [];
  bool _showDriverChatBanner = true; // Pestaña informativa de chat para el chofer


  @override
  void initState() {
    super.initState();
    _loadProfile();
    _tripHistory.addListener(_onTripHistoryChanged);
    _initDriverGps();
    _rideService.addListener(_onRideServiceChanged);
    if (_rideService.activeRides.isNotEmpty) {
      _selectRideToInspect(_rideService.activeRides.first);
    }
  }

  void _onTripHistoryChanged() {
    if (!mounted) return;
    setState(() {
      driverWallet = _tripHistory.totalEarnings;
    });
  }

  Future<void> _initDriverGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
        if (mounted) {
          setState(() {
            _driverLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
        _startGpsStream();
      }
    } catch (_) {}
  }

  void _startGpsStream() {
    _gpsStreamSub?.cancel();
    _gpsStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final newLoc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _driverLocation = newLoc;
      });
      if (_activeAcceptedRide != null) {
        _rideService.updateDriverLocation(
          rideId: _activeAcceptedRide!.id,
          location: newLoc,
        );
      }
    });
  }

  void _stopGpsStream() {
    _gpsStreamSub?.cancel();
    _gpsStreamSub = null;
  }

  /// Traza la ruta OSRM para el viaje activo:
  /// - heading_to_pickup / arrived : chofer → punto de recogida
  /// - in_trip                     : recogida → destino
  /// Se llama MANUALMENTE en dos momentos concretos, sin GPS automático.
  Future<void> _fetchActiveRouteForDriver() async {
    final ride = _activeAcceptedRide;
    if (ride == null) return;

    final LatLng origin = (_activeRideStep == 'in_trip')
        ? ride.pickupPoint
        : _driverLocation;
    final LatLng destination = (_activeRideStep == 'in_trip')
        ? ride.dropoffPoint
        : ride.pickupPoint;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final pts = coords
              .map<LatLng>((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();
          if (mounted) {
            setState(() => _activeRoutePoints = pts);
            // Centrar mapa entre los dos puntos del tramo actual
            _mapController.move(
              LatLng(
                (origin.latitude + destination.latitude) / 2,
                (origin.longitude + destination.longitude) / 2,
              ),
              13.5,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Driver OSRM active route error: $e');
    }
  }

  Future<void> _loadProfile() async {
    final userId = AuthService().currentUser?.id;
    final prof = await _profileService.loadProfile(userId);
    if (mounted) {
      setState(() {
        _profile = prof;
        _isLoadingProfile = false;
      });
      if (prof != null) {
        await _tripHistory.load(prof.id);
        if (mounted) {
          setState(() {
            driverWallet = _tripHistory.totalEarnings;
          });
        }
      } else {
        setState(() {
          driverWallet = 0.0;
        });
      }
    }
  }

  @override
  void dispose() {
    _stopGpsStream();
    _tripHistory.removeListener(_onTripHistoryChanged);
    _rideService.removeListener(_onRideServiceChanged);
    super.dispose();
  }

  final Set<String> _knownRideIds = {};
  // IDs de viajes donde este chofer envió oferta o contraoferta y espera decisión del pasajero
  final Set<String> _pendingOfferRideIds = {};

  void _onRideServiceChanged() {
    if (!mounted) return;

    final myId = _profile?.id ?? 'driver_me';

    // 🚨 Alerta de nueva carrera en el radar cuando el chofer está en línea
    if (isOnline) {
      for (final ride in _rideService.activeRides) {
        if (!_knownRideIds.contains(ride.id) && (ride.status == 'searching' || ride.status == 'negotiating')) {
          _knownRideIds.add(ride.id);
          NotificationSoundService().showNewRideAlert(
            rideId: ride.id,
            passengerName: ride.passengerName,
            destination: ride.dropoffAddress,
            offeredPrice: ride.offeredPrice,
          );
        }
      }
    }

    setState(() {
      if (_activeAcceptedRide == null) {
        // Verificar las carreras donde enviamos oferta o contraoferta
        final pendingIds = _pendingOfferRideIds.toList();
        for (final rideId in pendingIds) {
          final ride = _rideService.activeRides.where((r) => r.id == rideId).firstOrNull;

          if (ride != null) {
            // CASO 1: ¡El pasajero nos aceptó a NOSOTROS!
            if (ride.status == 'accepted' && ride.acceptedOffer?.id == myId) {
              _activeAcceptedRide = ride;
              _activeRideStep = 'heading_to_pickup';
              _activeRoutePoints = [];
              _inspectedRoutePoints = [];
              _inspectedRide = null;
              _pendingOfferRideIds.remove(rideId);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final price = ride.acceptedOffer?.price ?? ride.offeredPrice;
                  final isCounter = ride.acceptedOffer?.isCounterOffer ?? false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isCounter
                            ? '✅ ¡El pasajero aceptó tu contraoferta de \$${price.toStringAsFixed(2)}!'
                            : '✅ ¡El pasajero aceptó tu oferta de \$${price.toStringAsFixed(2)}!',
                      ),
                      backgroundColor: BeachColors.emeraldSuccess,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  // Trazar ruta al punto de recogida
                  _fetchActiveRouteForDriver();
                }
              });
              break;
            }

            // CASO 2: El pasajero seleccionó a OTRO chofer
            else if (ride.status == 'accepted' || ride.status == 'in_progress') {
              if (ride.acceptedOffer?.id != myId) {
                _pendingOfferRideIds.remove(rideId);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ℹ️ El pasajero seleccionó a otro conductor para este viaje.'),
                        backgroundColor: Color(0xFF475569),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                });
              }
            }
          } else {
            // El viaje desapareció o fue cancelado
            _pendingOfferRideIds.remove(rideId);
          }
        }
      } else {
        // Actualizar el ride activo con los datos más recientes de Firestore
        final updated = _rideService.activeRides
            .where((r) => r.id == _activeAcceptedRide!.id)
            .firstOrNull;
        if (updated != null) {
          if (updated.status == 'cancelled') {
            _activeAcceptedRide = null;
            _activeRideStep = 'heading_to_pickup';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ El pasajero ha cancelado el viaje.'),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            });
          } else {
            _activeAcceptedRide = updated;
          }
        } else {
          // El viaje fue completado o cancelado remotamente
          _activeAcceptedRide = null;
          _activeRideStep = 'heading_to_pickup';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ El viaje ya no está activo o fue cancelado.'),
                  backgroundColor: Colors.orangeAccent,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        }
      }
    });
  }

  Future<void> _selectRideToInspect(RideRequest ride) async {
    setState(() {
      _inspectedRide = ride;
      _inspectedRoutePoints = [];
    });

    _mapController.move(ride.pickupPoint, 14.0);

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${ride.pickupPoint.longitude},${ride.pickupPoint.latitude};'
        '${ride.dropoffPoint.longitude},${ride.dropoffPoint.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          final points = coordinates.map<LatLng>((coord) {
            return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
          }).toList();

          if (mounted) {
            setState(() {
              _inspectedRoutePoints = points;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Driver OSRM route fallback: $e');
    }
  }

  void _acceptRideDirectly(RideRequest ride) {
    final dName = _profile?.fullName ?? 'Conductor Carúpano';
    final dVehicle = _profile != null ? _profile!.vehicleDescription : 'Moto';
    final dPlate = _profile?.vehiclePlate ?? 'S/P';
    final dId = _profile?.id ?? 'driver_me';

    // Estimación real de llegada según distancia entre chofer y punto de recogida
    const distanceCalc = Distance();
    final distKm = distanceCalc.as(LengthUnit.Kilometer, _driverLocation, ride.pickupPoint);
    final etaMin = math.max(1, (distKm * 2.5).round()); // ~2.5 min por km en moto/calle

    final offer = DriverOffer(
      id: dId,
      driverName: dName,
      driverVehicle: dVehicle,
      driverPlate: dPlate,
      rating: _profile?.rating ?? 5.0,
      totalRides: _profile?.totalRides ?? 0,
      price: ride.offeredPrice,
      eta: '$etaMin min',
      isCounterOffer: false,
      driverLat: _driverLocation.latitude,
      driverLon: _driverLocation.longitude,
    );

    // Enviar oferta al pasajero para que éste la acepte o rechace
    _rideService.submitDriverOffer(rideId: ride.id, offer: offer);

    setState(() {
      _pendingOfferRideIds.add(ride.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏳ Oferta enviada por \$${ride.offeredPrice.toStringAsFixed(2)} — esperando que el pasajero elija.'),
        backgroundColor: BeachColors.oceanPrimary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _counterOffer(RideRequest ride, double counterPrice) {
    final dName = _profile?.fullName ?? 'Conductor Carúpano';
    final dVehicle = _profile != null ? _profile!.vehicleDescription : 'Moto';
    final dPlate = _profile?.vehiclePlate ?? 'S/P';
    final dId = _profile?.id ?? 'driver_me';

    const distanceCalc = Distance();
    final distKm = distanceCalc.as(LengthUnit.Kilometer, _driverLocation, ride.pickupPoint);
    final etaMin = math.max(1, (distKm * 2.5).round());

    final offer = DriverOffer(
      id: dId,
      driverName: dName,
      driverVehicle: dVehicle,
      driverPlate: dPlate,
      rating: _profile?.rating ?? 5.0,
      totalRides: _profile?.totalRides ?? 0,
      price: counterPrice,
      eta: '$etaMin min',
      isCounterOffer: true,
      driverLat: _driverLocation.latitude,
      driverLon: _driverLocation.longitude,
    );

    // Enviar contraoferta al pasajero
    _rideService.submitDriverOffer(rideId: ride.id, offer: offer);

    setState(() {
      _pendingOfferRideIds.add(ride.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏳ Contraoferta enviada por \$${counterPrice.toStringAsFixed(2)} — esperando respuesta del pasajero.'),
        backgroundColor: BeachColors.softAmber,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _advanceActiveRideStep() {
    if (_activeAcceptedRide == null) return;

    // ── PASO 1: Pasajero a bordo → Iniciar Viaje ─────────────────────────
    // Fusiona "llegué" + "iniciar": envía 'arrived' y luego 'in_progress' juntos.
    // El pasajero ya ve la posición del chofer en tiempo real en su mapa.
    if (_activeRideStep == 'heading_to_pickup' || _activeRideStep == 'arrived') {
      _rideService.updateRideStatus(rideId: _activeAcceptedRide!.id, newStatus: 'arrived');
      _rideService.updateRideStatus(rideId: _activeAcceptedRide!.id, newStatus: 'in_progress');
      setState(() {
        _activeRideStep = 'in_trip';
        _activeRoutePoints = []; // Limpiar para redibujar hacia destino
      });
      // Trazar nueva ruta: recogida → destino
      _fetchActiveRouteForDriver();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 ¡Viaje iniciado! Rumbo al destino.'),
          backgroundColor: BeachColors.oceanPrimary,
          duration: Duration(seconds: 3),
        ),
      );
    } else if (_activeRideStep == 'in_trip') {

      final ride = _activeAcceptedRide!;
      final earned = ride.acceptedOffer?.price ?? ride.offeredPrice;
      final dId = _profile?.id ?? 'driver_me';

      // Guardar en historial
      final completedTrip = CompletedTrip(
        id: '${ride.id}_${DateTime.now().millisecondsSinceEpoch}',
        passengerName: ride.passengerName,
        pickupAddress: ride.pickupAddress,
        dropoffAddress: ride.dropoffAddress,
        price: earned,
        distanceKm: ride.distanceKm,
        timestamp: DateTime.now(),
        paymentMethod: ride.paymentMethod,
        passengerRating: 0, // Se actualiza cuando el pasajero califique
      );
      _tripHistory.addTrip(driverId: dId, trip: completedTrip);

      setState(() {
        driverWallet += earned;
        _activeRideStep = 'completed';
      });
      _rideService.updateRideStatus(rideId: ride.id, newStatus: 'completed');
      _stopGpsStream();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: BeachColors.emeraldSuccess),
              SizedBox(width: 8),
              Text('¡Viaje Completado!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cobraste \$${earned.toStringAsFixed(2)} USD de ${ride.passengerName}.',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BeachColors.backgroundSand,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BeachColors.lagoonBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Comisión App (5%):', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                        Text('-\$${(earned * 0.05).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tu ganancia neta:', style: TextStyle(fontSize: 11, color: BeachColors.emeraldSuccess)),
                        Text('+\$${(earned * 0.95).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BeachColors.emeraldSuccess)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Acumulado en tu Billetera. El corte de comisiones es este viernes.',
                style: TextStyle(fontSize: 10.5, color: BeachColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _activeAcceptedRide = null;
                });
                _stopGpsStream();
                DriverFinancesSheet.show(
                  context,
                  driverId: _profile?.id ?? 'driver_me',
                  driverName: _profile?.fullName ?? 'Conductor',
                );
              },
              child: const Text('Ver Finanzas', style: TextStyle(color: BeachColors.oceanPrimary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BeachColors.emeraldSuccess,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _activeAcceptedRide = null;
                });
                _stopGpsStream();
              },
              child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: BeachColors.backgroundSand,
        body: Center(
          child: CircularProgressIndicator(color: BeachColors.oceanPrimary),
        ),
      );
    }

    if (_profile == null) {
      return DriverRegisterScreen(
        onProfileSaved: () {
          _loadProfile();
        },
        onBackToPassenger: () {
          widget.onSwitchToPassenger();
        },
      );
    }

    final activeRides = _rideService.activeRides;

    return Scaffold(
      backgroundColor: BeachColors.backgroundSand,
      drawer: _buildDriverDrawer(),
      appBar: AppBar(
        backgroundColor: BeachColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: BeachColors.lagoonBorder, height: 1),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: BeachColors.textMain, size: 22),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menú',
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: isOnline ? BeachColors.emeraldSuccess : BeachColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile!.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BeachColors.textMain,
                    ),
                  ),
                  Text(
                    '${_profile!.vehicleDescription} • ${_profile!.vehiclePlate}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: BeachColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                _stopGpsStream();
                widget.onSwitchToPassenger();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: BeachColors.backgroundSand,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BeachColors.lagoonBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, color: BeachColors.oceanPrimary, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Pasajero',
                      style: TextStyle(
                        color: BeachColors.oceanPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Mapa más grande cuando hay viaje activo (el chofer necesita ver la ruta)
          final double mapHeight = _activeAcceptedRide != null
              ? constraints.maxHeight * 0.62
              : constraints.maxHeight * 0.38;

          return Column(
            children: [
              // ─── Barra de Billetera + Estado (solo visible sin viaje activo) ───
              if (_activeAcceptedRide == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: BeachColors.pureWhite,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          DriverFinancesSheet.show(
                            context,
                            driverId: _profile?.id ?? 'driver_me',
                            driverName: _profile?.fullName ?? 'Conductor',
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: BeachColors.oceanLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.account_balance_wallet_outlined,
                                    color: BeachColors.oceanPrimary, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Text('Billetera',
                                          style: TextStyle(color: BeachColors.textMuted, fontSize: 9.5)),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios, size: 8, color: BeachColors.textMuted),
                                    ],
                                  ),
                                  Text(
                                    '\$${driverWallet.toStringAsFixed(2)} USD',
                                    style: const TextStyle(
                                      color: BeachColors.textMain,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            isOnline ? 'En línea' : 'Pausa',
                            style: TextStyle(
                              color: isOnline ? BeachColors.emeraldSuccess : BeachColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: isOnline,
                              activeThumbColor: BeachColors.oceanPrimary,
                              onChanged: (val) => setState(() => isOnline = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: BeachColors.lagoonBorder),
              ],

              // ─── MAPA ──────────────────────────────────────────────────────────
              SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _driverLocation,
                        initialZoom: 13.8,
                        minZoom: 10.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.carupano.riders',
                        ),

                        // ── Ruta del viaje activo (chofer→recogida o recogida→destino) ──
                        if (_activeAcceptedRide != null && _activeRoutePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _activeRoutePoints,
                                strokeWidth: 5.5,
                                color: _activeRideStep == 'in_trip'
                                    ? BeachColors.oceanPrimary
                                    : BeachColors.emeraldSuccess,
                                borderColor: _activeRideStep == 'in_trip'
                                    ? const Color(0xFF0369A1)
                                    : const Color(0xFF047857),
                                borderStrokeWidth: 1.5,
                              ),
                            ],
                          )
                        // ── Ruta inspeccionada en el radar ──────────────────────────
                        else if (_inspectedRoutePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _inspectedRoutePoints,
                                strokeWidth: 4.8,
                                color: BeachColors.oceanPrimary,
                                borderColor: const Color(0xFF0369A1),
                                borderStrokeWidth: 1.2,
                              ),
                            ],
                          ),

                        MarkerLayer(
                          markers: [
                            // ── Posición del chofer ─────────────────────────────────
                            Marker(
                              point: _driverLocation,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: BeachColors.oceanPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.two_wheeler, color: Colors.white, size: 20),
                              ),
                            ),

                            // ── Marcadores del viaje ACTIVO ─────────────────────────
                            if (_activeAcceptedRide != null) ...[
                              Marker(
                                point: _activeAcceptedRide!.pickupPoint,
                                width: 90,
                                height: 30,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: BeachColors.emeraldSuccess,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.trip_origin, size: 10, color: Colors.white),
                                      SizedBox(width: 3),
                                      Text('Recogida',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              Marker(
                                point: _activeAcceptedRide!.dropoffPoint,
                                width: 80,
                                height: 30,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on, size: 10, color: Colors.white),
                                      SizedBox(width: 3),
                                      Text('Destino',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ]
                            // ── Marcadores del viaje inspeccionado en radar ──────────
                            else if (_inspectedRide != null) ...[
                              Marker(
                                point: _inspectedRide!.pickupPoint,
                                width: 100,
                                height: 32,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: BeachColors.pureWhite,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: BeachColors.oceanPrimary, width: 1.2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.trip_origin, size: 10, color: BeachColors.oceanPrimary),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          _inspectedRide!.pickupAddress,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Marker(
                                point: _inspectedRide!.dropoffPoint,
                                width: 100,
                                height: 32,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: BeachColors.pureWhite,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, size: 10, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          _inspectedRide!.dropoffAddress,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    // ── Etiqueta flotante en el mapa ───────────────────────────────
                    Positioned(
                      top: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BeachColors.pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          _activeAcceptedRide != null
                              ? (_activeRideStep == 'in_trip' ? '🚀 Viaje en Curso' : '📍 En camino al pasajero')
                              : 'Radar Carúpano (${activeRides.where((r) => r.status == "searching" || r.status == "negotiating").length} viajes)',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: BeachColors.textMain),
                        ),
                      ),
                    ),

                    // ── Billetera flotante visible durante el viaje activo ──────────
                    if (_activeAcceptedRide != null)
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: BeachColors.pureWhite,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined,
                                  color: BeachColors.oceanPrimary, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '\$${driverWallet.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: BeachColors.textMain),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ─── Panel inferior (radar o viaje activo) ─────────────────────────
              Expanded(
                child: _activeAcceptedRide != null
                    ? _buildActiveTripPanel()
                    : _buildIncomingRequestsList(
                        activeRides.where((r) => r.status == "searching" || r.status == "negotiating").toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveTripPanel() {
    final ride = _activeAcceptedRide!;
    final price = ride.acceptedOffer?.price ?? ride.offeredPrice;

    // ── Configuración del botón principal según el paso ──────────────────
    final bool isInTrip = _activeRideStep == 'in_trip';
    final String buttonText = isInTrip
        ? 'Llegué al destino — Cobrar \$${price.toStringAsFixed(2)}'
        : 'Pasajero a bordo → Iniciar Viaje';
    final Color buttonColor =
        isInTrip ? const Color(0xFF0F172A) : BeachColors.emeraldSuccess;
    final String stepLabel = isInTrip
        ? '🚀 En viaje hacia el destino'
        : '📍 En camino a recoger al pasajero';

    return Container(
      color: BeachColors.backgroundSand,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Pestaña Informativa del Chat (afuera, con botón de cerrar/aceptar) ──
          if (_showDriverChatBanner)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BeachColors.oceanPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 16, color: BeachColors.oceanPrimary),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '💬 Usa el chat si necesitas confirmar la ubicación exacta o el pago.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => setState(() => _showDriverChatBanner = false),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: BeachColors.oceanPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Entendido',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Tarjeta de info del viaje ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            decoration: BoxDecoration(
              color: BeachColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BeachColors.lagoonBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pasajero + precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: BeachColors.oceanLight,
                          child: Icon(Icons.person, color: BeachColors.oceanPrimary, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ride.passengerName,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: BeachColors.textMain)),
                            Text(stepLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isInTrip ? BeachColors.oceanPrimary : BeachColors.emeraldSuccess,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    Text('\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800, color: BeachColors.oceanPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                // Recogida + Destino en una fila compacta
                Row(
                  children: [
                    const Icon(Icons.trip_origin, size: 12, color: BeachColors.oceanPrimary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(ride.pickupAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: BeachColors.textMain)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Color(0xFFEF4444)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(ride.dropoffAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: BeachColors.textMain)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── BOTÓN PRINCIPAL (único) ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: _advanceActiveRideStep,
              child: Text(buttonText,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),

          // ── Fila de acciones secundarias ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final rideId = _activeAcceptedRide?.id;
                    final dId = _profile?.id ?? 'driver_me';
                    final dName = _profile?.fullName ?? 'Conductor';
                    if (rideId == null) return;
                    LiveChatSheet.show(
                      context,
                      rideId: rideId,
                      currentUserId: dId,
                      currentUserName: dName,
                      isDriver: true,
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                  label: const Text('Chat', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BeachColors.oceanPrimary,
                    side: const BorderSide(color: BeachColors.oceanPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _activeAcceptedRide = null;
                      _activeRoutePoints = [];
                    });
                    _stopGpsStream();
                  },
                  icon: const Icon(Icons.radar, size: 15),
                  label: const Text('Radar', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BeachColors.textSecondary,
                    side: const BorderSide(color: BeachColors.lagoonBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestsList(List<RideRequest> activeRides) {

    if (!isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.bedtime_outlined, color: BeachColors.textMuted, size: 36),
            SizedBox(height: 8),
            Text('Turno pausado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('Activa el interruptor arriba para recibir solicitudes.', style: TextStyle(color: BeachColors.textSecondary, fontSize: 11)),
          ],
        ),
      );
    }

    if (activeRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.radar, color: BeachColors.oceanPrimary, size: 36),
            SizedBox(height: 8),
            Text('Buscando viajes en Carúpano...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('Las solicitudes de pasajeros aparecerán aquí en vivo.', style: TextStyle(color: BeachColors.textSecondary, fontSize: 11)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: activeRides.length,
      itemBuilder: (ctx, i) {
        final ride = activeRides[i];
        final isSelected = _inspectedRide?.id == ride.id;

        return InkWell(
          onTap: () => _selectRideToInspect(ride),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BeachColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? BeachColors.oceanPrimary : BeachColors.lagoonBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          ride.vehicleType == 'moto' ? Icons.two_wheeler : Icons.directions_car,
                          color: BeachColors.oceanPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ride.passengerName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: BeachColors.textMain),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: BeachColors.oceanLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${ride.offeredPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: BeachColors.oceanPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trip_origin, size: 12, color: BeachColors.oceanPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride.pickupAddress,
                        style: const TextStyle(fontSize: 11.5, color: BeachColors.textMain, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride.dropoffAddress,
                        style: const TextStyle(fontSize: 11.5, color: BeachColors.textMain, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${ride.distanceKm.toStringAsFixed(1)} km • ${(ride.paymentMethod == 'pago_movil' ? 'Pago Móvil' : 'Efectivo \$')}',
                      style: const TextStyle(fontSize: 10, color: BeachColors.textSecondary),
                    ),
                    if (ride.note.isNotEmpty) ...[
                      const Text(' • ', style: TextStyle(fontSize: 10, color: BeachColors.textMuted)),
                      Text(ride.note, style: const TextStyle(fontSize: 10, color: BeachColors.textMuted)),
                    ],
                  ],
                ),
                // ── Botones de acción ─────────────────────────────────────
                if (_pendingOfferRideIds.contains(ride.id))
                  // Estado: Esperando respuesta del pasajero a la oferta o contraoferta
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: BeachColors.oceanPrimary, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(BeachColors.oceanPrimary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '⏳ Oferta enviada — esperando que el pasajero elija...',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: BeachColors.oceanPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _pendingOfferRideIds.remove(ride.id)),
                          style: TextButton.styleFrom(
                            foregroundColor: BeachColors.textSecondary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Retirar', style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BeachColors.emeraldSuccess,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _acceptRideDirectly(ride),
                            child: Text(
                              'Aceptar \$${ride.offeredPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 34,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BeachColors.oceanPrimary,
                              side: const BorderSide(color: BeachColors.oceanPrimary),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _counterOffer(ride, ride.offeredPrice + 0.50),
                            child: Text(
                              '+\$0.50 (\$${(ride.offeredPrice + 0.50).toStringAsFixed(2)})',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 34,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BeachColors.oceanPrimary,
                              side: const BorderSide(color: BeachColors.oceanPrimary),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _counterOffer(ride, ride.offeredPrice + 1.00),
                            child: Text(
                              '+\$1.00 (\$${(ride.offeredPrice + 1.00).toStringAsFixed(2)})',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverDrawer() {
    // Recargar desde Firestore cada vez que se abre el drawer para ver ratings actualizados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profId = _profile?.id;
      if (profId != null && profId.isNotEmpty) {
        _tripHistory.load(profId);
      }
    });

    final trips = _tripHistory.trips;
    final totalEarnings = _tripHistory.totalEarnings;
    final avgRating = _tripHistory.averageRating;
    final totalTrips = trips.length;
    final fmt = NumberFormat('#,##0.00', 'es_VE');

    return Drawer(
      backgroundColor: BeachColors.pureWhite,
      child: Column(
        children: [
          // ─── Cabecera del perfil ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BeachColors.oceanPrimary, Color(0xFF0369A1)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(
                    _profile != null && _profile!.fullName.isNotEmpty
                        ? _profile!.fullName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _profile?.fullName ?? 'Conductor',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_profile?.vehicleDescription ?? ''} • ${_profile?.vehiclePlate ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 12),
                // Stats rápidas
                Row(
                  children: [
                    _drawerStatChip(Icons.route, '$totalTrips viajes'),
                    const SizedBox(width: 8),
                    _drawerStatChip(
                      Icons.star,
                      avgRating > 0 ? avgRating.toStringAsFixed(1) : 'Sin calif.',
                    ),
                    const SizedBox(width: 8),
                    _drawerStatChip(Icons.attach_money, '\$${fmt.format(totalEarnings)}'),
                  ],
                ),
              ],
            ),
          ),

          // ─── Acciones rápidas ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context); // Cerrar drawer
                            DriverFinancesSheet.show(
                              context,
                              driverId: _profile?.id ?? 'driver_me',
                              driverName: _profile?.fullName ?? 'Conductor',
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: _drawerActionCard(
                            icon: Icons.account_balance_wallet,
                            label: 'Billetera',
                            value: '\$${driverWallet.toStringAsFixed(2)}',
                            color: BeachColors.emeraldSuccess,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _drawerActionCard(
                          icon: Icons.star_rounded,
                          label: 'Calificación',
                          value: avgRating > 0 ? '${avgRating.toStringAsFixed(1)} ★' : '—',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: BeachColors.lagoonBorder),

                // ─── Menú items ────────────────────────────────────────────────────
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: BeachColors.oceanPrimary, size: 20),
                  title: const Text('Editar Perfil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => DriverRegisterScreen(
                          onProfileSaved: () {
                            Navigator.pop(ctx);
                            _loadProfile();
                          },
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: BeachColors.oceanPrimary, size: 20),
                  title: const Text('Historial de Viajes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: trips.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: BeachColors.oceanLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalTrips',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BeachColors.oceanPrimary),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _showTripHistorySheet();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent, color: BeachColors.oceanPrimary, size: 20),
                  title: const Text('Soporte / Ayuda', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente: Chat de soporte')),
                    );
                  },
                ),

                const Divider(height: 1, color: BeachColors.lagoonBorder),

                // ─── Cambiar a modo pasajero ───────────────────────────────────────
                ListTile(
                  leading: const Icon(Icons.person_outline, color: BeachColors.textMuted, size: 20),
                  title: const Text('Cambiar a Pasajero', style: TextStyle(fontSize: 13, color: BeachColors.textSecondary)),
                  onTap: () {
                    Navigator.pop(context);
                    _stopGpsStream();
                    widget.onSwitchToPassenger();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                  title: const Text('Cerrar Sesión', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    _stopGpsStream();
                    await AuthService().logout();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _drawerActionCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9.5, color: color.withValues(alpha: 0.8))),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTripHistorySheet() {
    final trips = _tripHistory.trips;
    final dateFmt = DateFormat('dd/MM/yy HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: BeachColors.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BeachColors.lagoonBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  children: [
                    const Text(
                      'Historial de Viajes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: BeachColors.textMain),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: BeachColors.oceanLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total: \$${_tripHistory.totalEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BeachColors.oceanPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: BeachColors.lagoonBorder),
              Expanded(
                child: trips.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 40, color: BeachColors.textMuted),
                            SizedBox(height: 8),
                            Text('Aún no has completado viajes',
                                style: TextStyle(color: BeachColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        itemCount: trips.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final t = trips[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BeachColors.backgroundSand,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: BeachColors.lagoonBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: BeachColors.oceanLight,
                                          child: Icon(Icons.person, size: 16, color: BeachColors.oceanPrimary),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.passengerName,
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                            Text(dateFmt.format(t.timestamp),
                                                style: const TextStyle(fontSize: 10, color: BeachColors.textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${t.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w800, color: BeachColors.emeraldSuccess),
                                        ),
                                        if (t.passengerRating > 0)
                                          Row(
                                            children: [
                                              const Icon(Icons.star, size: 11, color: Color(0xFFF59E0B)),
                                              Text(
                                                ' ${t.passengerRating.toStringAsFixed(1)}',
                                                style: const TextStyle(fontSize: 10, color: BeachColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.trip_origin, size: 11, color: BeachColors.oceanPrimary),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(t.pickupAddress,
                                          style: const TextStyle(fontSize: 10.5, color: BeachColors.textMain),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 11, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(t.dropoffAddress,
                                          style: const TextStyle(fontSize: 10.5, color: BeachColors.textMain),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Text(
                                      '${t.distanceKm.toStringAsFixed(1)} km',
                                      style: const TextStyle(fontSize: 9.5, color: BeachColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
