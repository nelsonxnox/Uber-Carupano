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

  String selectedVehicle = 'moto'; // 'moto', 'auto', 'auto_ac'
  String selectedPayment = 'pago_movil'; // 'pago_movil', 'efectivo'

  final TextEditingController _originController =
      TextEditingController(text: 'Plaza Bolívar, Centro');
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
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _noteController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  void _onVehicleChanged(String vehicle) {
    setState(() {
      selectedVehicle = vehicle;
      if (vehicle == 'moto') _fareController.text = '2.50';
      if (vehicle == 'auto') _fareController.text = '4.50';
      if (vehicle == 'auto_ac') _fareController.text = '6.00';
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

  void _startRideSearch() {
    setState(() {
      rideState = 'negotiating';
      driverOffers = [];
    });

    final double passengerFare = double.tryParse(_fareController.text) ?? 2.50;

    // Simular que choferes cercanos en Carúpano responden en segundos
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
                  'Modo Pasajero',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: BeachColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. MAPA VISIBLE CON MOTOTAXIS EN CARÚPANO
          Positioned.fill(
            bottom: rideState == 'idle' ? 330 : null,
            child: _buildCarupanoMap(),
          ),

          // 2. PANEL SEGÚN EL ESTADO
          if (rideState == 'idle')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
      ),
    );
  }

  // -------------------------------------------------------------
  // MAPA VISUAL CON MOTOS DISPONIBLES EN CARÚPANO
  // -------------------------------------------------------------
  Widget _buildCarupanoMap() {
    return Container(
      color: const Color(0xFFE2EDF4),
      child: Stack(
        children: [
          // Fondo de calles sutiles
          CustomPaint(
            size: Size.infinite,
            painter: _CarupanoStreetPainter(),
          ),

          // Etiqueta de ubicación del pasajero (GPS)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: BeachColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BeachColors.lagoonBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location,
                        color: BeachColors.oceanPrimary, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      _originController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: BeachColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Mototaxi 1 cercano (Bera Azul)
          Positioned(
            top: 110,
            left: 60,
            child: _buildMotoMarker(
              name: 'Bera SBR (Azul)',
              time: '2 min',
              color: BeachColors.oceanPrimary,
            ),
          ),

          // Mototaxi 2 cercano (Empire Roja)
          Positioned(
            top: 150,
            right: 50,
            child: _buildMotoMarker(
              name: 'Empire Keeway',
              time: '4 min',
              color: const Color(0xFFE11D48),
            ),
          ),

          // Mototaxi 3 (Bera Negra)
          Positioned(
            top: 200,
            left: 120,
            child: _buildMotoMarker(
              name: 'Bera 150',
              time: '3 min',
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotoMarker({
    required String name,
    required String time,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: BeachColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.two_wheeler, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                '$name • $time',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: BeachColors.textMain,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_drop_down, color: BeachColors.pureWhite, size: 14),
      ],
    );
  }

  // -------------------------------------------------------------
  // FORMULARIO PRINCIPAL DE PEDIDO
  // -------------------------------------------------------------
  Widget _buildPassengerForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
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
          const SizedBox(height: 12),

          // Direcciones
          _buildCleanInput(
            icon: Icons.trip_origin,
            iconColor: BeachColors.oceanPrimary,
            controller: _originController,
            hint: 'Punto de recogida',
          ),
          const SizedBox(height: 7),
          _buildCleanInput(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFFEF4444),
            controller: _destController,
            hint: '¿A dónde vas?',
          ),
          const SizedBox(height: 7),
          _buildCleanInput(
            icon: Icons.notes_outlined,
            iconColor: BeachColors.textSecondary,
            controller: _noteController,
            hint: 'Nota: "Llevo casco", etc.',
          ),
          const SizedBox(height: 12),

          // Ofrecer Tarifa (Input Numérico)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: BeachColors.backgroundSand,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BeachColors.lagoonBorder),
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ofrecer Tarifa',
                      style: TextStyle(
                        fontSize: 11,
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
          const SizedBox(height: 10),

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
          const SizedBox(height: 12),

          // Botón Corregido: Limpio y directo
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
                'SOLICITAR $_buttonVehicleLabel POR \$${_fareController.text}',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
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

// Dibujador de líneas sutiles tipo calles en el mapa de Carúpano
class _CarupanoStreetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD6E4EE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Calle principal
    path.moveTo(0, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.4);

    // Avenida Bolívar / Costanera
    path.moveTo(size.width * 0.25, 0);
    path.lineTo(size.width * 0.25, size.height);

    // Intersección Plaza
    path.moveTo(size.width * 0.75, 0);
    path.lineTo(size.width * 0.75, size.height);

    // Diagonal Playa Copey
    path.moveTo(0, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}