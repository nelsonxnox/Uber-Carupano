import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init fallback: $e');
  }
  runApp(const CarupanoRidersApp());
}

/// PALETA DE COLORES COSTERA MINIMALISTA (Carúpano Beach Minimal)
class BeachColors {
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color backgroundSand = Color(0xFFF7FBFD); // Fondo blanco con toque de brisa marina
  static const Color cardSurface = Color(0xFFFFFFFF);
  
  // Azules caribeños suaves y elegantes (Playa Copey / Carúpano)
  static const Color oceanPrimary = Color(0xFF0284C7); // Azul océano sereno
  static const Color oceanLight = Color(0xFFE0F2FE);   // Azul cielo suave para chips y fondos
  static const Color cyanAccent = Color(0xFF0EA5E9);   // Acento de mar
  static const Color lagoonBorder = Color(0xFFE2E8F0);  // Bordes ultra delgados y limpios
  
  // Tipografía balanceada y sobria
  static const Color textMain = Color(0xFF0F172A);     // Slate oscuro elegante
  static const Color textSecondary = Color(0xFF64748B);// Gris marino legible
  static const Color textMuted = Color(0xFF94A3B8);    // Gris claro sutil
  
  // Acentos de estado
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color softAmber = Color(0xFFF59E0B);
}

class CarupanoRidersApp extends StatelessWidget {
  const CarupanoRidersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carúpano Riders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: BeachColors.backgroundSand,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BeachColors.oceanPrimary,
          primary: BeachColors.oceanPrimary,
          surface: BeachColors.cardSurface,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI, -apple-system, BlinkMacSystemFont, Roboto, sans-serif',
      ),
      home: const MainMobileFrameScreen(),
    );
  }
}

class MainMobileFrameScreen extends StatefulWidget {
  const MainMobileFrameScreen({super.key});

  @override
  State<MainMobileFrameScreen> createState() => _MainMobileFrameScreenState();
}

class _MainMobileFrameScreenState extends State<MainMobileFrameScreen> {
  bool isDriverMode = false;

  void _toggleMode() {
    setState(() {
      isDriverMode = !isDriverMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF4F8), // Fondo exterior armónico con el mar
      body: Center(
        child: Container(
          width: 395,
          height: 800,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: BeachColors.pureWhite,
            borderRadius: BorderRadius.circular(44),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2B48).withOpacity(0.08),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
            ],
            border: Border.all(color: const Color(0xFFD6E4ED), width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: isDriverMode
                ? DriverHomeScreen(onSwitchToPassenger: _toggleMode)
                : RiderHomeScreen(onSwitchToDriver: _toggleMode),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// PANTALLA PASAJERO (Minimalista Costero)
// -------------------------------------------------------------
class RiderHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToDriver;
  const RiderHomeScreen({super.key, required this.onSwitchToDriver});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String selectedService = 'moto';
  String selectedPayment = 'pago_movil';
  final TextEditingController _originController = TextEditingController(text: 'Plaza Bolívar, Centro');
  final TextEditingController _destController = TextEditingController(text: 'Playa Copey');
  final TextEditingController _refController = TextEditingController(text: 'Frente a la fuente principal');

  double get estimatedPrice => selectedService == 'moto' ? 2.50 : 5.00;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeachColors.backgroundSand,
      appBar: AppBar(
        backgroundColor: BeachColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: BeachColors.lagoonBorder, height: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: BeachColors.oceanLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.waves, color: BeachColors.oceanPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carúpano Riders',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BeachColors.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Sucre • Costa caribeña',
                  style: TextStyle(fontSize: 11, color: BeachColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botón sutil InDrive para cambiar a Modo Conductor
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: widget.onSwitchToDriver,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: BeachColors.oceanLight.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.two_wheeler, color: BeachColors.oceanPrimary, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'Modo Chofer',
                      style: TextStyle(
                        color: BeachColors.oceanPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapa limpio y minimalista
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: const Color(0xFFEFF6FA),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: BeachColors.pureWhite,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: BeachColors.lagoonBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation_outlined, color: BeachColors.oceanPrimary, size: 15),
                              SizedBox(width: 6),
                              Text(
                                'Carúpano Centro',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: BeachColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMinimalMarker('Bera Roja', '3 min'),
                            const SizedBox(width: 40),
                            _buildMinimalMarker('Empire Azul', '6 min'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: BeachColors.pureWhite,
                    foregroundColor: BeachColors.textMain,
                    elevation: 1,
                    onPressed: () {},
                    child: const Icon(Icons.my_location, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta inferior de solicitud (Limpia, blanca, esquinas suaves)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: BeachColors.pureWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: BeachColors.lagoonBorder.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de vehículo moderno
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                        id: 'moto',
                        title: 'Mototaxi',
                        time: '1 persona • 3 min',
                        price: '\$2.50',
                        icon: Icons.two_wheeler_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildServiceCard(
                        id: 'taxi',
                        title: 'Taxi Carro',
                        time: 'Hasta 4 • 6 min',
                        price: '\$5.00',
                        icon: Icons.directions_car_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Campos de dirección con diseño plano
                _buildCleanInput(
                  icon: Icons.circle_outlined,
                  iconColor: BeachColors.oceanPrimary,
                  controller: _originController,
                  hint: 'Punto de recogida',
                ),
                const SizedBox(height: 8),
                _buildCleanInput(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFFEF4444),
                  controller: _destController,
                  hint: '¿A dónde vas en Carúpano?',
                ),
                const SizedBox(height: 8),
                _buildCleanInput(
                  icon: Icons.bookmark_border,
                  iconColor: BeachColors.textMuted,
                  controller: _refController,
                  hint: 'Punto de referencia (portón, local, casa)',
                ),
                const SizedBox(height: 14),

                // Selector de método de pago (Venezuela)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildPaymentChip('Pago Móvil', 'pago_movil'),
                        const SizedBox(width: 8),
                        _buildPaymentChip('Efectivo', 'efectivo'),
                      ],
                    ),
                    Text(
                      '~\$${estimatedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: BeachColors.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botón de acción principal
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showRequestDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BeachColors.oceanPrimary,
                      foregroundColor: BeachColors.pureWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'SOLICITAR ${selectedService.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalMarker(String label, String eta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BeachColors.lagoonBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.two_wheeler, color: BeachColors.oceanPrimary, size: 14),
          const SizedBox(width: 5),
          Text(
            '$label • $eta',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: BeachColors.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String id,
    required String title,
    required String time,
    required String price,
    required IconData icon,
  }) {
    final bool isSelected = selectedService == id;
    return InkWell(
      onTap: () => setState(() => selectedService = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? BeachColors.oceanLight.withOpacity(0.4) : BeachColors.backgroundSand,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? BeachColors.oceanPrimary : BeachColors.lagoonBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? BeachColors.oceanPrimary : BeachColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? BeachColors.oceanPrimary : BeachColors.textMain,
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BeachColors.textSecondary,
                    ),
                  ),
                ],
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
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BeachColors.backgroundSand,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BeachColors.lagoonBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 12.5, color: BeachColors.textMain),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: const TextStyle(color: BeachColors.textMuted, fontSize: 12),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? BeachColors.oceanPrimary : BeachColors.backgroundSand,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? BeachColors.oceanPrimary : BeachColors.lagoonBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: isSelected ? BeachColors.pureWhite : BeachColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BeachColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Buscando conductores',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: BeachColors.textMain),
        ),
        content: Text(
          'Tu solicitud ha sido transmitida a los conductores cercanos en Carúpano.\n\n'
          '• Recogida: ${_originController.text}\n'
          '• Destino: ${_destController.text}\n'
          '• Referencia: ${_refController.text}\n'
          '• Tarifa base: \$${estimatedPrice.toStringAsFixed(2)}\n'
          '• Método: ${selectedPayment == "pago_movil" ? "Pago Móvil" : "Efectivo"}',
          style: const TextStyle(fontSize: 12.5, color: BeachColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: BeachColors.textSecondary, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: BeachColors.oceanPrimary,
              foregroundColor: BeachColors.pureWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Aceptar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// PANTALLA MODO CONDUCTOR (Minimalista, Clara y Profesional)
// -------------------------------------------------------------
class DriverHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToPassenger;
  const DriverHomeScreen({super.key, required this.onSwitchToPassenger});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool isOnline = true;
  double driverWallet = 6.50; // Saldo en dólares

  final List<Map<String, dynamic>> _rideRequests = [
    {
      'id': '1',
      'passenger': 'María González',
      'pickup': 'Hospital Santos Aníbal Dominicci',
      'dropoff': 'Plaza Miranda, Centro',
      'ref': 'Frente a Emergencias',
      'distance': '1.8 km',
      'offeredPrice': 2.00,
      'payment': 'Pago Móvil (Banesco)',
    },
    {
      'id': '2',
      'passenger': 'Carlos Ramírez',
      'pickup': 'Terminal de Pasajeros',
      'dropoff': 'Playa Grande (Entrada)',
      'ref': 'Parada de buses',
      'distance': '4.2 km',
      'offeredPrice': 3.00,
      'payment': 'Efectivo \$',
    },
    {
      'id': '3',
      'passenger': 'Elena Salazar',
      'pickup': 'Av. Perimetral (Traki)',
      'dropoff': 'Canchunchú Viejo',
      'ref': 'Casa rejas negras',
      'distance': '3.5 km',
      'offeredPrice': 2.50,
      'payment': 'Pago Móvil',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeachColors.backgroundSand,
      appBar: AppBar(
        backgroundColor: BeachColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: BeachColors.lagoonBorder, height: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? BeachColors.emeraldSuccess : BeachColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel de Conductor',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BeachColors.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  isOnline ? 'Conectado en Carúpano' : 'Turno pausado',
                  style: const TextStyle(fontSize: 11, color: BeachColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: widget.onSwitchToPassenger,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: BeachColors.backgroundSand,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BeachColors.lagoonBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, color: BeachColors.textSecondary, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'Pasajero',
                      style: TextStyle(
                        color: BeachColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Billetera y Conexión
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: BeachColors.pureWhite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: BeachColors.oceanLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: BeachColors.oceanPrimary, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo disponible', style: TextStyle(color: BeachColors.textMuted, fontSize: 10)),
                        Text(
                          '\$${driverWallet.toStringAsFixed(2)} USD',
                          style: const TextStyle(
                            color: BeachColors.textMain,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      isOnline ? 'En línea' : 'Pausa',
                      style: TextStyle(
                        color: isOnline ? BeachColors.emeraldSuccess : BeachColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isOnline,
                        activeColor: BeachColors.oceanPrimary,
                        onChanged: (val) => setState(() => isOnline = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: BeachColors.lagoonBorder),

          // Título de radar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitudes activas (${_rideRequests.length})',
                  style: const TextStyle(
                    color: BeachColors.textMain,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Text('Actualizado en vivo', style: TextStyle(color: BeachColors.textMuted, fontSize: 11)),
              ],
            ),
          ),

          // Lista de tarjetas minimalistas estilo InDrive
          Expanded(
            child: isOnline
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    itemCount: _rideRequests.length,
                    itemBuilder: (context, index) {
                      final item = _rideRequests[index];
                      return _buildDriverCard(item);
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.nightlight_round_outlined, color: BeachColors.textMuted, size: 40),
                        SizedBox(height: 10),
                        Text(
                          'Turno pausado',
                          style: TextStyle(color: BeachColors.textMain, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Activa el interruptor para recibir viajes.',
                          style: TextStyle(color: BeachColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> item) {
    final double offered = item['offeredPrice'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BeachColors.lagoonBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
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
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: BeachColors.oceanLight,
                    child: Text(
                      item['passenger'][0],
                      style: const TextStyle(
                        color: BeachColors.oceanPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['passenger'],
                        style: const TextStyle(
                          color: BeachColors.textMain,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        'A ${item['distance']} • ${item['payment']}',
                        style: const TextStyle(color: BeachColors.textMuted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '\$${offered.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: BeachColors.oceanPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: BeachColors.lagoonBorder.withOpacity(0.6)),
          const SizedBox(height: 10),

          // Ruta
          Row(
            children: [
              const Icon(Icons.circle, color: BeachColors.oceanPrimary, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['pickup'],
                  style: const TextStyle(color: BeachColors.textMain, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 10),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  item['dropoff'],
                  style: const TextStyle(color: BeachColors.textMain, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 17),
            child: Text(
              'Ref: ${item['ref']}',
              style: const TextStyle(color: BeachColors.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),

          // Botones de acción InDrive minimalistas
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => _acceptRide(item, offered),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BeachColors.oceanPrimary,
                      foregroundColor: BeachColors.pureWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Aceptar \$${offered.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => _acceptRide(item, offered + 0.50),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BeachColors.textMain,
                      side: const BorderSide(color: BeachColors.lagoonBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      '+\$0.50 (\$${(offered + 0.5).toStringAsFixed(2)})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _acceptRide(Map<String, dynamic> item, double agreedPrice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BeachColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Carrera confirmada',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: BeachColors.textMain),
        ),
        content: Text(
          'Pasajero: ${item['passenger']}\n\n'
          '• Origen: ${item['pickup']}\n'
          '• Referencia: ${item['ref']}\n'
          '• Destino: ${item['dropoff']}\n'
          '• Tarifa acordada: \$${agreedPrice.toStringAsFixed(2)}\n'
          '• Comisión plataforma (10%): -\$${(agreedPrice * 0.10).toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12.5, color: BeachColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: BeachColors.textSecondary, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _rideRequests.removeWhere((r) => r['id'] == item['id']);
                driverWallet -= (agreedPrice * 0.10);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ruta hacia el pasajero iniciada'),
                  backgroundColor: BeachColors.oceanPrimary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BeachColors.oceanPrimary,
              foregroundColor: BeachColors.pureWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Iniciar Ruta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}


