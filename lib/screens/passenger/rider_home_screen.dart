import 'package:flutter/material.dart';
import '../../theme/beach_colors.dart';

class RiderHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToDriver;
  const RiderHomeScreen({super.key, required this.onSwitchToDriver});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Filtros del documento (Paso 3): Mototaxi, Auto, Auto con A/C
  String selectedVehicle = 'moto'; // 'moto', 'auto', 'auto_ac'
  String selectedPayment = 'pago_movil'; // 'pago_movil', 'efectivo'

  // Direcciones y notas (Paso 1 y 3)
  final TextEditingController _originController =
      TextEditingController(text: 'Plaza Bolívar, Centro');
  final TextEditingController _destController =
      TextEditingController(text: 'Playa Copey');
  final TextEditingController _noteController =
      TextEditingController(text: 'Frente a la fuente principal');

  // Input numérico para proponer tarifa (Paso 2)
  late TextEditingController _fareController;

  // Estado del flujo del viaje (Paso 4, 5, 6, 7)
  // 'idle' = formulario normal
  // 'negotiating' = bottom sheet buscando y evaluando ofertas
  // 'active' = chofer aceptado, en camino (Live Tracking)
  String rideState = 'idle';

  // Ofertas simuladas recibidas de choferes en Carúpano (Paso 5)
  List<Map<String, dynamic>> driverOffers = [];
  Map<String, dynamic>? acceptedDriver;

  @override
  void initState() {
    super.initState();
    _fareController = TextEditingController(text: '2.50');
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _noteController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  // Precios base sugeridos según vehículo
  void _onVehicleChanged(String vehicle) {
    setState(() {
      selectedVehicle = vehicle;
      if (vehicle == 'moto') {
        _fareController.text = '2.50';
      } else if (vehicle == 'auto') {
        _fareController.text = '4.50';
      } else if (vehicle == 'auto_ac') {
        _fareController.text = '6.00';
      }
    });
  }

  void _adjustFare(double delta) {
    double current = double.tryParse(_fareController.text) ?? 2.50;
    double updated = current + delta;
    if (updated < 1.0) updated = 1.0;
    setState(() {
      _fareController.text = updated.toStringAsFixed(2);
    });
  }

  // Iniciar la búsqueda (Paso 4: Emitir solicitud)
  void _startRideSearch() {
    setState(() {
      rideState = 'negotiating';
      driverOffers = [];
    });

    final double passengerFare = double.tryParse(_fareController.text) ?? 2.50;

    // Simulamos que los choferes van respondiendo en tiempo real (Paso 4 y 5)
    Future.delayed(const Duration(milliseconds: 900), () {
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
          'price': passengerFare, // Acepta la tarifa propuesta
          'isCounterOffer': false,
        });
      });
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted || rideState != 'negotiating') return;
      setState(() {
        driverOffers.add({
          'id': 'd2',
          'name': 'José Gregorio Farías',
          'rating': 4.8,
          'ridesCount': 189,
          'vehicle': selectedVehicle == 'moto'
              ? 'Empire Keeway 150 (Rojo)'
              : 'Chery Orinoco (Blanco)',
          'plate': 'AB7P91X',
          'eta': '4 min (a 900m)',
          'price': passengerFare + 0.50, // Contraoferta +$0.50
          'isCounterOffer': true,
        });
      });
    });
  }

  // Aceptar chofer seleccionado (Paso 6)
  void _acceptDriver(Map<String, dynamic> driver) {
    setState(() {
      acceptedDriver = driver;
      rideState = 'active'; // Paso 7: Live Tracking
    });
  }

  // Cancelar viaje o volver al inicio
  void _resetRide() {
    setState(() {
      rideState = 'idle';
      acceptedDriver = null;
      driverOffers.clear();
    });
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
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Modo Pasajero',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: BeachColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. MAPA DE FONDO (Paso 1 del documento)
          Positioned.fill(
            bottom: rideState == 'idle' ? 385 : null,
            child: _buildCarupanoMapBackground(),
          ),

          // 2. CONTENIDO SEGÚN EL ESTADO
          if (rideState == 'idle')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildPassengerRequestForm(),
            ),

          if (rideState == 'negotiating')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildNegotiationBottomSheet(),
            ),

          if (rideState == 'active')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActiveTripPanel(),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MAPA MINIMALISTA DE CARÚPANO (Paso 1)
  // -------------------------------------------------------------
  Widget _buildCarupanoMapBackground() {
    return Container(
      color: const Color(0xFFEBF3F8),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: BeachColors.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BeachColors.lagoonBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation_outlined,
                          color: BeachColors.oceanPrimary, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        _originController.text.isNotEmpty
                            ? _originController.text
                            : 'Carúpano Centro',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          color: BeachColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMinimalMarker('Bera Azul', '2 min'),
                    const SizedBox(width: 25),
                    _buildMinimalMarker('Empire Roja', '4 min'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: FloatingActionButton.small(
              backgroundColor: BeachColors.pureWhite,
              foregroundColor: BeachColors.textMain,
              elevation: 1,
              onPressed: () {},
              child: const Icon(Icons.my_location, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalMarker(String label, String eta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BeachColors.lagoonBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.two_wheeler,
              color: BeachColors.oceanPrimary, size: 13),
          const SizedBox(width: 4),
          Text(
            '$label • $eta',
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: BeachColors.textMain),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FORMULARIO PRINCIPAL: PASO 1, 2 Y 3 DEL DOCUMENTO
  // -------------------------------------------------------------
  Widget _buildPassengerRequestForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // PASO 3: Selector de Vehículo (Mototaxi, Auto, Auto con AC)
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
            const SizedBox(height: 14),

            // PASO 1: Origen y Destino
            _buildCleanInput(
              icon: Icons.trip_origin,
              iconColor: BeachColors.oceanPrimary,
              controller: _originController,
              hint: 'Punto de recogida (GPS)',
            ),
            const SizedBox(height: 8),
            _buildCleanInput(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFFEF4444),
              controller: _destController,
              hint: '¿A dónde vas en Carúpano?',
            ),
            const SizedBox(height: 8),

            // PASO 3: Notas u Opciones Adicionales
            _buildCleanInput(
              icon: Icons.notes_outlined,
              iconColor: BeachColors.textSecondary,
              controller: _noteController,
              hint: 'Nota: "Llevo casco", "Billete de \$20", etc.',
            ),
            const SizedBox(height: 14),

            // PASO 2: Proponer la Tarifa (Input Numérico Central)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: BeachColors.backgroundSand,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BeachColors.oceanLight),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Ofrecer Tarifa',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: BeachColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Tú decides el precio',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: BeachColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Botón menos
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 22, color: BeachColors.oceanPrimary),
                    onPressed: () => _adjustFare(-0.50),
                    visualDensity: VisualDensity.compact,
                  ),
                  // Input numérico editable
                  SizedBox(
                    width: 76,
                    child: TextField(
                      controller: _fareController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
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
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // Botón más
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        size: 22, color: BeachColors.oceanPrimary),
                    onPressed: () => _adjustFare(0.50),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Método de Pago (Pago Móvil / Efectivo)
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
            const SizedBox(height: 14),

            // PASO 4: Botón de Solicitar y desplegar negociación
            SizedBox(
              width: double.infinity,
              height: 46,
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
                  'SOLICITAR $selectedVehicle.toUpperCase() POR \$${_fareController.text}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // PASO 4 Y 5: BOTTOM SHEET DE NEGOCIACIÓN DINÁMICA
  // -------------------------------------------------------------
  Widget _buildNegotiationBottomSheet() {
    final double myOffer = double.tryParse(_fareController.text) ?? 2.50;

    return Container(
      constraints: const BoxConstraints(maxHeight: 480),
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior con botón cancelar
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
          const SizedBox(height: 12),

          // Indicador de pulso de búsqueda
          LinearProgressIndicator(
            backgroundColor: BeachColors.oceanLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(BeachColors.oceanPrimary),
            minHeight: 2.5,
          ),
          const SizedBox(height: 14),

          // Lista de ofertas en tiempo real
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
                    'Notificando a conductores cercanos en Carúpano...',
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

  // Tarjeta de cada chofer interesado (Paso 5)
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: BeachColors.oceanLight,
                child: const Icon(Icons.person,
                    color: BeachColors.oceanPrimary, size: 22),
              ),
              const SizedBox(width: 10),
              // Datos del chofer
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
                      '${offer['vehicle']} • Placa: ${offer['plate']}',
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
              // Precio y botón Aceptar (Paso 6)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 17,
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
                          fontSize: 9,
                          color: BeachColors.softAmber,
                          fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () => _acceptDriver(offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BeachColors.oceanPrimary,
                        foregroundColor: BeachColors.pureWhite,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PASO 7: MODO VIAJE ACTIVO (LIVE TRACKING)
  // -------------------------------------------------------------
  Widget _buildActiveTripPanel() {
    if (acceptedDriver == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de estado "En camino"
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu conductor está en camino',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BeachColors.oceanPrimary,
                        ),
                      ),
                      Text(
                        'Llegada estimada en ${acceptedDriver!['eta']}',
                        style: const TextStyle(
                            fontSize: 10.5, color: BeachColors.textMain),
                      ),
                    ],
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
          const SizedBox(height: 14),

          // Placa grande y datos del vehículo
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: BeachColors.oceanLight,
                child: const Icon(Icons.person,
                    color: BeachColors.oceanPrimary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acceptedDriver!['name'],
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: BeachColors.textMain,
                      ),
                    ),
                    Text(
                      acceptedDriver!['vehicle'],
                      style: const TextStyle(
                          fontSize: 11.5, color: BeachColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // PLACA GRANDE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: BeachColors.backgroundSand,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BeachColors.lagoonBorder),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PLACA',
                      style: TextStyle(
                        fontSize: 8.5,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: BeachColors.textSecondary,
                      ),
                    ),
                    Text(
                      acceptedDriver!['plate'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: BeachColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botones de acción rápida (Llamar, Chat, Cancelar)
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
                  label: const Text('Llamar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BeachColors.textMain,
                    side: const BorderSide(color: BeachColors.lagoonBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abriendo chat interno con el conductor...'),
                        backgroundColor: BeachColors.oceanPrimary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BeachColors.textMain,
                    side: const BorderSide(color: BeachColors.lagoonBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _resetRide,
                tooltip: 'Cancelar viaje',
                icon: const Icon(Icons.close, color: Color(0xFFEF4444), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // COMPONENTES AUXILIARES
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
                style:
                    TextStyle(fontSize: 11, color: BeachColors.textMuted)),
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
                style:
                    TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined,
                color: BeachColors.textSecondary, size: 21),
            title: const Text('Billetera y Pagos',
                style:
                    TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined,
                color: BeachColors.textSecondary, size: 21),
            title: const Text('Seguridad y Soporte',
                style:
                    TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: BeachColors.textSecondary, size: 21),
            title: const Text('Acerca de Carúpano Riders',
                style:
                    TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}