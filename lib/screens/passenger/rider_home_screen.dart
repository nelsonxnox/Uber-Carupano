import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/beach_colors.dart';

class RiderHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToDriver;
  const RiderHomeScreen({super.key, required this.onSwitchToDriver});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();

  // Lugares Clave y Frecuentes de Carúpano con coordenadas GPS exactas
  static final List<Map<String, dynamic>> _carupanoPlaces = [
    {
      'title': 'Plaza Bolívar (Centro)',
      'subtitle': 'Calle Independencia',
      'point': const LatLng(10.6678, -63.2585),
      'icon': Icons.account_balance,
    },
    {
      'title': 'Playa Copey',
      'subtitle': 'Sector Balneario Copey',
      'point': const LatLng(10.6820, -63.2380),
      'icon': Icons.beach_access,
    },
    {
      'title': 'Hospital Dominicci',
      'subtitle': 'Santos Aníbal Dominicci',
      'point': const LatLng(10.6610, -63.2550),
      'icon': Icons.local_hospital,
    },
    {
      'title': 'Terminal de Pasajeros',
      'subtitle': 'Avenida Universitaria',
      'point': const LatLng(10.6550, -63.2680),
      'icon': Icons.directions_bus,
    },
    {
      'title': 'Mercado Municipal',
      'subtitle': 'Casco Central de Carúpano',
      'point': const LatLng(10.6698, -63.2530),
      'icon': Icons.storefront,
    },
    {
      'title': 'Playa Grande',
      'subtitle': 'Sector Playa Grande',
      'point': const LatLng(10.6480, -63.2850),
      'icon': Icons.waves,
    },
    {
      'title': 'El Muco',
      'subtitle': 'Avenida Principal del Muco',
      'point': const LatLng(10.6590, -63.2420),
      'icon': Icons.location_city,
    },
    {
      'title': 'Guaca',
      'subtitle': 'Pueblo Costero de Guaca',
      'point': const LatLng(10.6420, -63.3100),
      'icon': Icons.sailing,
    },
  ];

  // Puntos interactivos actuales
  LatLng _originPoint = const LatLng(10.6678, -63.2585); // Plaza Bolívar
  LatLng _destinationPoint = const LatLng(10.6820, -63.2380); // Playa Copey
  bool _isGpsLocating = false;

  // Selección de modo al tocar el mapa ('origin' o 'destination')
  String _mapTapMode = 'destination'; 

  // Mototaxis simuladas en calles reales de Carúpano
  final List<Map<String, dynamic>> _nearbyMotos = [
    {
      'name': 'Bera SBR (Azul)',
      'eta': '2 min',
      'point': const LatLng(10.6695, -63.2570),
      'color': BeachColors.oceanPrimary,
    },
    {
      'name': 'Empire Keeway (Roja)',
      'eta': '4 min',
      'point': const LatLng(10.6655, -63.2595),
      'color': const Color(0xFFE11D48),
    },
    {
      'name': 'Bera 150 (Negra)',
      'eta': '3 min',
      'point': const LatLng(10.6688, -63.2610),
      'color': const Color(0xFF0F172A),
    },
  ];

  String selectedVehicle = 'moto'; // 'moto', 'auto', 'auto_ac'
  String selectedPayment = 'pago_movil'; // 'pago_movil', 'efectivo'

  final TextEditingController _originController =
      TextEditingController(text: 'Plaza Bolívar (Centro)');
  final TextEditingController _destController =
      TextEditingController(text: 'Playa Copey');
  final TextEditingController _noteController =
      TextEditingController(text: 'Llevo casco');
  final TextEditingController _fareController =
      TextEditingController(text: '2.50');

  // Estado del flujo: 'idle' -> 'negotiating' -> 'active'
  String rideState = 'idle';

  List<Map<String, dynamic>> driverOffers = [];
  Map<String, dynamic>? acceptedDriver;

  @override
  void initState() {
    super.initState();
    _recalculateDistanceAndPrice();
    _requestGpsLocation();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _noteController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // MATEMÁTICA Y FÓRMULA DE DISTANCIA (Fórmula Haversine en km)
  // -------------------------------------------------------------
  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final double dLon = _degreesToRadians(p2.longitude - p1.longitude);

    final double lat1 = _degreesToRadians(p1.latitude);
    final double lat2 = _degreesToRadians(p2.latitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    // Multiplicador de trazado urbano de Carúpano (curvas de calles ~1.28)
    return (earthRadiusKm * c) * 1.28;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  // -------------------------------------------------------------
  // FÓRMULA DE TARIFA SUGERIDA SEGÚN VEHÍCULO Y DISTANCIA
  // -------------------------------------------------------------
  void _recalculateDistanceAndPrice() {
    final double km = _calculateDistanceKm(_originPoint, _destinationPoint);
    double suggestedPrice = 2.0;

    if (selectedVehicle == 'moto') {
      // Base: $2.00 hasta 2.5 km. Después $0.50 por km adicional
      if (km <= 2.5) {
        suggestedPrice = 2.00;
      } else {
        suggestedPrice = 2.00 + ((km - 2.5) * 0.50);
      }
    } else if (selectedVehicle == 'auto') {
      // Base: $4.00 hasta 3 km. Después $0.80 por km adicional
      if (km <= 3.0) {
        suggestedPrice = 4.00;
      } else {
        suggestedPrice = 4.00 + ((km - 3.0) * 0.80);
      }
    } else if (selectedVehicle == 'auto_ac') {
      // Base: $5.50 hasta 3 km con A/C. Después $1.00 por km adicional
      if (km <= 3.0) {
        suggestedPrice = 5.50;
      } else {
        suggestedPrice = 5.50 + ((km - 3.0) * 1.00);
      }
    }

    // Redondear a múltiplos de $0.50 (estilo Carúpano / Venezuela)
    final double rounded = (suggestedPrice * 2).round() / 2.0;

    setState(() {
      _fareController.text = rounded.toStringAsFixed(2);
    });
  }

  // Al tocar el mapa, mover el pin según el modo activo
  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (_mapTapMode == 'destination') {
        _destinationPoint = point;
        _destController.text =
            'Punto en mapa (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})';
      } else {
        _originPoint = point;
        _originController.text =
            'Punto en mapa (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})';
      }
    });
    _recalculateDistanceAndPrice();
  }

  // Seleccionar un lugar frecuente de Carúpano
  void _selectQuickPlace(Map<String, dynamic> place, bool isDestination) {
    setState(() {
      if (isDestination) {
        _destinationPoint = place['point'] as LatLng;
        _destController.text = place['title'] as String;
      } else {
        _originPoint = place['point'] as LatLng;
        _originController.text = place['title'] as String;
      }
    });
    _recalculateDistanceAndPrice();
    _mapController.move(place['point'] as LatLng, 14.5);
  }

  Future<void> _requestGpsLocation() async {
    setState(() => _isGpsLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        if (mounted) {
          setState(() {
            _originPoint = LatLng(position.latitude, position.longitude);
            _originController.text = 'Mi Ubicación actual (GPS)';
            _isGpsLocating = false;
          });
          _recalculateDistanceAndPrice();
          _mapController.move(_originPoint, 15.0);
        }
        return;
      }
    } catch (e) {
      debugPrint('GPS fallback to Carúpano: $e');
    }
    if (mounted) {
      setState(() => _isGpsLocating = false);
    }
  }

  void _onVehicleChanged(String vehicle) {
    setState(() {
      selectedVehicle = vehicle;
    });
    _recalculateDistanceAndPrice();
  }

  void _adjustFare(double delta) {
    double current = double.tryParse(_fareController.text) ?? 2.50;
    double updated = current + delta;
    if (updated < 1.0) updated = 1.0;
    setState(() {
      _fareController.text = updated.toStringAsFixed(2);
    });
  }

  void _startRideSearch() {
    setState(() {
      rideState = 'negotiating';
      driverOffers = [];
    });

    final double passengerFare = double.tryParse(_fareController.text) ?? 2.50;

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || rideState != 'negotiating') return;
      setState(() {
        driverOffers.add({
          'id': 'd1',
          'name': 'Carlos Rodríguez',
          'rating': 4.9,
          'ridesCount': 342,
          'vehicle': selectedVehicle == 'moto'
              ? 'Bera SBR 150 (Azul)'
              : 'Toyota Corolla (Plata)',
          'plate': 'AE5K82M',
          'eta': '2 min (a 400m)',
          'price': passengerFare,
          'isCounterOffer': false,
        });
      });
    });

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted || rideState != 'negotiating') return;
      setState(() {
        driverOffers.add({
          'id': 'd2',
          'name': 'José Gregorio Farías',
          'rating': 4.8,
          'ridesCount': 189,
          'vehicle': selectedVehicle == 'moto'
              ? 'Empire Keeway (Rojo)'
              : 'Chery Orinoco (Blanco)',
          'plate': 'AB7P91X',
          'eta': '4 min (a 800m)',
          'price': passengerFare + 0.50,
          'isCounterOffer': true,
        });
      });
    });
  }

  void _acceptDriver(Map<String, dynamic> driver) {
    setState(() {
      acceptedDriver = driver;
      rideState = 'active';
    });
  }

  void _resetRide() {
    setState(() {
      rideState = 'idle';
      acceptedDriver = null;
      driverOffers.clear();
    });
  }

  String get _buttonVehicleLabel {
    if (selectedVehicle == 'moto') return 'MOTO';
    if (selectedVehicle == 'auto') return 'AUTO';
    return 'AUTO A/C';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: BeachColors.backgroundSand,
      drawer: _buildInDriveDrawer(),
      appBar: AppBar(
        backgroundColor: BeachColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: BeachColors.textMain, size: 22),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: BeachColors.lagoonBorder, height: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: BeachColors.oceanLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.waves,
                  color: BeachColors.oceanPrimary, size: 18),
            ),
            const SizedBox(width: 9),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carúpano Riders',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: BeachColors.textMain,
                  ),
                ),
                Text(
                  'Modo Pasajero • Carúpano',
                  style: TextStyle(
                    fontSize: 10,
                    color: BeachColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Centrar en mi GPS',
            icon: _isGpsLocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location,
                    color: BeachColors.oceanPrimary, size: 20),
            onPressed: _requestGpsLocation,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // El mapa abarca exactamente el 40% de la altura de la pantalla
          final double mapHeight = constraints.maxHeight * 0.40;

          return Stack(
            children: [
              // 1. MAPA REAL DE CARÚPANO (40% de la pantalla)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: rideState == 'idle' ? mapHeight + 20 : constraints.maxHeight,
                child: _buildInteractiveCarupanoMap(),
              ),

              // 2. PANEL SEGÚN EL ESTADO
              if (rideState == 'idle')
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: mapHeight,
                  child: _buildPassengerForm(),
                ),

              if (rideState == 'negotiating')
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildNegotiationPanel(),
                ),

              if (rideState == 'active')
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildActiveRidePanel(),
                ),
            ],
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // MAPA REAL E INTERACTIVO: TRAZADO DE RUTA, DISTANCIA Y PINES
  // -------------------------------------------------------------
  Widget _buildInteractiveCarupanoMap() {
    final double tripDistance =
        _calculateDistanceKm(_originPoint, _destinationPoint);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _originPoint,
            initialZoom: 14.5,
            minZoom: 11.0,
            maxZoom: 18.0,
            onTap: _onMapTapped,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carupano.riders',
            ),

            // Trazado de Ruta Visual (Línea de viaje en color azul océano)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [
                    _originPoint,
                    LatLng(
                      (_originPoint.latitude + _destinationPoint.latitude) / 2,
                      (_originPoint.longitude + _destinationPoint.longitude) / 2 + 0.002,
                    ),
                    _destinationPoint,
                  ],
                  strokeWidth: 4.5,
                  color: BeachColors.oceanPrimary,
                ),
              ],
            ),

            // Capa de Marcadores (Recogida, Destino y Motos)
            MarkerLayer(
              markers: [
                // 1. PIN DE ORIGEN (Recogida)
                Marker(
                  point: _originPoint,
                  width: 130,
                  height: 48,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: BeachColors.pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: BeachColors.oceanPrimary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trip_origin,
                                color: BeachColors.oceanPrimary, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Recogida',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: BeachColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: BeachColors.oceanPrimary, size: 16),
                    ],
                  ),
                ),

                // 2. PIN DE DESTINO (Llegada)
                Marker(
                  point: _destinationPoint,
                  width: 130,
                  height: 48,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: BeachColors.pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFEF4444), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                color: Color(0xFFEF4444), size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Destino',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: BeachColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: Color(0xFFEF4444), size: 16),
                    ],
                  ),
                ),

                // 3. Marcadores de Mototaxis reales en Carúpano
                ..._nearbyMotos.map((moto) {
                  return Marker(
                    point: moto['point'] as LatLng,
                    width: 120,
                    height: 38,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: BeachColors.pureWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: BeachColors.lagoonBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.two_wheeler,
                                  color: moto['color'] as Color, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '${moto['name']}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: BeachColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Chip flotante con la distancia y tiempo estimado calculado
        Positioned(
          top: 10,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: BeachColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BeachColors.lagoonBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route,
                    color: BeachColors.oceanPrimary, size: 14),
                const SizedBox(width: 5),
                Text(
                  '${tripDistance.toStringAsFixed(1)} km  •  ~${(tripDistance * 3.2).round()} min',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: BeachColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selector flotante para cambiar el punto que quieres mover en el mapa
        Positioned(
          top: 10,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: BeachColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BeachColors.lagoonBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapModeToggle('Recogida', 'origin'),
                const SizedBox(width: 4),
                _buildMapModeToggle('Destino', 'destination'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapModeToggle(String label, String mode) {
    final bool isSelected = _mapTapMode == mode;
    return InkWell(
      onTap: () => setState(() => _mapTapMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? BeachColors.oceanPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? BeachColors.pureWhite : BeachColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // FORMULARIO PRINCIPAL DE PEDIDO
  // -------------------------------------------------------------
  Widget _buildPassengerForm() {
    final double tripDistance =
        _calculateDistanceKm(_originPoint, _destinationPoint);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selector Vehículo: Moto / Auto / Auto A/C
            Row(
              children: [
                Expanded(
                  child: _buildVehicleTab(
                    id: 'moto',
                    title: 'Moto',
                    time: '2 min',
                    icon: Icons.two_wheeler_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVehicleTab(
                    id: 'auto',
                    title: 'Auto',
                    time: '4 min',
                    icon: Icons.directions_car_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVehicleTab(
                    id: 'auto_ac',
                    title: 'Auto A/C',
                    time: '5 min',
                    icon: Icons.ac_unit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips de Destinos Populares de Carúpano (Un solo toque)
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _carupanoPlaces.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final place = _carupanoPlaces[i];
                  return InkWell(
                    onTap: () => _selectQuickPlace(place, true),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: BeachColors.oceanLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: BeachColors.lagoonBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(place['icon'] as IconData,
                              size: 13, color: BeachColors.oceanPrimary),
                          const SizedBox(width: 4),
                          Text(
                            place['title'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: BeachColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Direcciones
            _buildCleanInput(
              icon: Icons.trip_origin,
              iconColor: BeachColors.oceanPrimary,
              controller: _originController,
              hint: 'Punto de recogida',
            ),
            const SizedBox(height: 6),
            _buildCleanInput(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFFEF4444),
              controller: _destController,
              hint: '¿A dónde vas en Carúpano?',
            ),
            const SizedBox(height: 6),
            _buildCleanInput(
              icon: Icons.notes_outlined,
              iconColor: BeachColors.textSecondary,
              controller: _noteController,
              hint: 'Nota: "Llevo casco", "Billete de \$20", etc.',
            ),
            const SizedBox(height: 10),

            // Ofrecer Tarifa (Calculada matemáticamente por km)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: BeachColors.backgroundSand,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BeachColors.lagoonBorder),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tarifa Sugerida',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: BeachColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${tripDistance.toStringAsFixed(1)} km de recorrido',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: BeachColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 22, color: BeachColors.oceanPrimary),
                    onPressed: () => _adjustFare(-0.50),
                    visualDensity: VisualDensity.compact,
                  ),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _fareController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: BeachColors.textMain,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '\$',
                        prefixStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: BeachColors.oceanPrimary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        size: 22, color: BeachColors.oceanPrimary),
                    onPressed: () => _adjustFare(0.50),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Forma de pago
            Row(
              children: [
                const Text(
                  'Pago:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: BeachColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _buildPaymentChip('Pago Móvil', 'pago_movil'),
                const SizedBox(width: 6),
                _buildPaymentChip('Efectivo', 'efectivo'),
              ],
            ),
            const SizedBox(height: 10),

            // Botón Limpio y directo
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _startRideSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BeachColors.oceanPrimary,
                  foregroundColor: BeachColors.pureWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'SOLICITAR $_buttonVehicleLabel POR \$${_fareController.text}',
                  style:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // PANEL DE NEGOCIACIÓN CON CHOFERES
  // -------------------------------------------------------------
  Widget _buildNegotiationPanel() {
    final double myOffer = double.tryParse(_fareController.text) ?? 2.50;

    return Container(
      constraints: const BoxConstraints(maxHeight: 460),
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buscando ofertas...',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: BeachColors.textMain,
                    ),
                  ),
                  Text(
                    'Tu oferta: \$${myOffer.toStringAsFixed(2)} • ${_originController.text} ➔ ${_destController.text}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: BeachColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 20, color: BeachColors.textSecondary),
                onPressed: _resetRide,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            backgroundColor: BeachColors.oceanLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(BeachColors.oceanPrimary),
            minHeight: 2.5,
          ),
          const SizedBox(height: 14),
          if (driverOffers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        BeachColors.oceanPrimary),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Notificando a conductores en Carúpano...',
                    style: TextStyle(
                        fontSize: 11.5, color: BeachColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: driverOffers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final offer = driverOffers[i];
                  return _buildDriverOfferCard(offer);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverOfferCard(Map<String, dynamic> offer) {
    final bool isCounter = offer['isCounterOffer'] == true;
    final double price = offer['price'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCounter ? BeachColors.softAmber : BeachColors.lagoonBorder,
          width: isCounter ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: BeachColors.oceanLight,
            child: const Icon(Icons.person,
                color: BeachColors.oceanPrimary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      offer['name'],
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: BeachColors.textMain,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star,
                        size: 13, color: BeachColors.softAmber),
                    Text(
                      ' ${offer['rating']}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BeachColors.textMain,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${offer['vehicle']} • ${offer['plate']}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: BeachColors.textSecondary,
                  ),
                ),
                Text(
                  'Llega en ${offer['eta']}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: BeachColors.emeraldSuccess,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isCounter
                      ? BeachColors.softAmber
                      : BeachColors.oceanPrimary,
                ),
              ),
              if (isCounter)
                const Text(
                  'Contraoferta',
                  style: TextStyle(
                      fontSize: 8.5,
                      color: BeachColors.softAmber,
                      fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () => _acceptDriver(offer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BeachColors.oceanPrimary,
                    foregroundColor: BeachColors.pureWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Aceptar',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // VIAJE ACTIVO CON PLACA GRANDE
  // -------------------------------------------------------------
  Widget _buildActiveRidePanel() {
    if (acceptedDriver == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: BeachColors.oceanLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.two_wheeler,
                    color: BeachColors.oceanPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'En camino (${acceptedDriver!['eta']})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BeachColors.oceanPrimary,
                    ),
                  ),
                ),
                Text(
                  '\$${acceptedDriver!['price'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BeachColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: BeachColors.oceanLight,
                child: const Icon(Icons.person,
                    color: BeachColors.oceanPrimary, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acceptedDriver!['name'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BeachColors.textMain,
                      ),
                    ),
                    Text(
                      acceptedDriver!['vehicle'],
                      style: const TextStyle(
                          fontSize: 11, color: BeachColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: BeachColors.backgroundSand,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BeachColors.lagoonBorder),
                ),
                child: Column(
                  children: [
                    const Text('PLACA',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: BeachColors.textSecondary)),
                    Text(
                      acceptedDriver!['plate'],
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: BeachColors.textMain),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Llamando al conductor...'),
                        backgroundColor: BeachColors.oceanPrimary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('Llamar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BeachColors.textMain,
                    side: const BorderSide(color: BeachColors.lagoonBorder),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abriendo chat con el conductor...'),
                        backgroundColor: BeachColors.oceanPrimary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BeachColors.textMain,
                    side: const BorderSide(color: BeachColors.lagoonBorder),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _resetRide,
                tooltip: 'Cancelar',
                icon: const Icon(Icons.close, color: Color(0xFFEF4444), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // AUXILIARES
  // -------------------------------------------------------------
  Widget _buildVehicleTab({
    required String id,
    required String title,
    required String time,
    required IconData icon,
  }) {
    final bool isSelected = selectedVehicle == id;
    return InkWell(
      onTap: () => _onVehicleChanged(id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BeachColors.oceanLight : BeachColors.backgroundSand,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? BeachColors.oceanPrimary : BeachColors.lagoonBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? BeachColors.oceanPrimary
                  : BeachColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? BeachColors.oceanPrimary
                    : BeachColors.textMain,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 9.5,
                color: BeachColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanInput({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: BeachColors.backgroundSand,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BeachColors.lagoonBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 12, color: BeachColors.textMain),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle:
                    const TextStyle(color: BeachColors.textMuted, fontSize: 11.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip(String label, String value) {
    final bool isSelected = selectedPayment == value;
    return InkWell(
      onTap: () => setState(() => selectedPayment = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? BeachColors.oceanPrimary
              : BeachColors.backgroundSand,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isSelected
                  ? BeachColors.oceanPrimary
                  : BeachColors.lagoonBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? BeachColors.pureWhite
                : BeachColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInDriveDrawer() {
    return Drawer(
      backgroundColor: BeachColors.pureWhite,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            color: BeachColors.backgroundSand,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: BeachColors.oceanLight,
                  child: Icon(Icons.person,
                      color: BeachColors.oceanPrimary, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Nelson (Pasajero)',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: BeachColors.textMain),
                    ),
                    Text(
                      'Carúpano, Sucre',
                      style: TextStyle(
                          fontSize: 11.5, color: BeachColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: BeachColors.lagoonBorder),
          ListTile(
            leading: const Icon(Icons.sports_motorsports_outlined,
                color: BeachColors.oceanPrimary, size: 22),
            title: const Text('Modo Conductor',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: const Text('Gana dinero haciendo viajes',
                style: TextStyle(fontSize: 11, color: BeachColors.textMuted)),
            onTap: () {
              Navigator.pop(context);
              widget.onSwitchToDriver();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history,
                color: BeachColors.textSecondary, size: 21),
            title: const Text('Mis Viajes',
                style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined,
                color: BeachColors.textSecondary, size: 21),
            title: const Text('Billetera y Pagos',
                style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined,
                color: BeachColors.textSecondary, size: 21),
            title: const Text('Seguridad y Soporte',
                style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: BeachColors.textSecondary, size: 21),
            title: const Text('Acerca de Carúpano Riders',
                style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}