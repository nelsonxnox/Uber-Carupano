import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).catchError((e) {
    debugPrint('Firebase init: $e');
    return null;
  });
  runApp(const CarupanoRidersApp());
}

/// PALETA DE COLORES COSTERA MINIMALISTA (Carúpano Beach Minimal)
class BeachColors {
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color backgroundSand = Color(0xFFF8FAFC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  
  // Azules caribeños suaves (Playa Copey / Carúpano)
  static const Color oceanPrimary = Color(0xFF0284C7);
  static const Color oceanLight = Color(0xFFE0F2FE);
  static const Color cyanAccent = Color(0xFF0EA5E9);
  static const Color lagoonBorder = Color(0xFFE2E8F0);
  
  // Tipografía sobria y legible
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  
  static const Color emeraldSuccess = Color(0xFF10B981);
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
      backgroundColor: const Color(0xFFE2E8F0),
      body: Center(
        child: Container(
          width: 400,
          height: 820,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: BeachColors.pureWhite,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2B48).withOpacity(0.08),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0xFFCBD5E1), width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
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
// PANTALLA PASAJERO CON MENÚ LATERAL (Estilo InDrive)
// -------------------------------------------------------------
class RiderHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToDriver;
  const RiderHomeScreen({super.key, required this.onSwitchToDriver});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedService = 'moto';
  String selectedPayment = 'pago_movil';
  final TextEditingController _originController = TextEditingController(text: 'Plaza Bolívar, Centro');
  final TextEditingController _destController = TextEditingController(text: 'Playa Copey');
  final TextEditingController _refController = TextEditingController(text: 'Frente a la fuente');

  double get estimatedPrice => selectedService == 'moto' ? 2.50 : 5.00;

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
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.waves, color: BeachColors.oceanPrimary, size: 18),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carúpano Riders',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BeachColors.textMain,
                  ),
                ),
                Text(
                  'Modo Pasajero',
                  style: TextStyle(fontSize: 10.5, color: BeachColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: widget.onSwitchToDriver,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: BeachColors.oceanLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.two_wheeler, color: BeachColors.oceanPrimary, size: 14),
                    SizedBox(width: 4),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Vista del Mapa Simulado
            Container(
              height: 250,
              color: const Color(0xFFEFF6FA),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: BeachColors.pureWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: BeachColors.lagoonBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation_outlined, color: BeachColors.oceanPrimary, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Carúpano Centro',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: BeachColors.textMain),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMinimalMarker('Bera Roja', '2 min'),
                            const SizedBox(width: 30),
                            _buildMinimalMarker('Empire Azul', '5 min'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
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
            ),

            // Formulario de Solicitud
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: BeachColors.pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector Mototaxi / Taxi
                  Row(
                    children: [
                      Expanded(
                        child: _buildServiceCard(
                          id: 'moto',
                          title: 'Mototaxi',
                          time: '1 persona • 2 min',
                          price: '\$2.50',
                          icon: Icons.two_wheeler_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildServiceCard(
                          id: 'taxi',
                          title: 'Taxi Carro',
                          time: 'Hasta 4 • 5 min',
                          price: '\$5.00',
                          icon: Icons.directions_car_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Inputs planos minimalistas
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
                    hint: 'Punto de referencia (portón, local)',
                  ),
                  const SizedBox(height: 14),

                  // Forma de pago y Tarifa sugerida
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildPaymentChip('Pago Móvil', 'pago_movil'),
                          const SizedBox(width: 6),
                          _buildPaymentChip('Efectivo', 'efectivo'),
                        ],
                      ),
                      Text(
                        '~\$${estimatedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: BeachColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón de solicitud principal
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => _showRequestDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BeachColors.oceanPrimary,
                        foregroundColor: BeachColors.pureWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'SOLICITAR ${selectedService.toUpperCase()}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
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

  // MENÚ LATERAL ESTILO INDRIVE
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
                  child: Icon(Icons.person, color: BeachColors.oceanPrimary, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Nelson (Pasajero)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: BeachColors.textMain),
                    ),
                    Text(
                      'Carúpano, Sucre',
                      style: TextStyle(fontSize: 11.5, color: BeachColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: BeachColors.lagoonBorder),

          ListTile(
            leading: const Icon(Icons.sports_motorsports_outlined, color: BeachColors.oceanPrimary, size: 22),
            title: const Text('Modo Conductor', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: const Text('Gana dinero haciendo viajes', style: TextStyle(fontSize: 11, color: BeachColors.textMuted)),
            onTap: () {
              Navigator.pop(context);
              widget.onSwitchToDriver();
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.history, color: BeachColors.textSecondary, size: 21),
            title: const Text('Mis Viajes', style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: BeachColors.textSecondary, size: 21),
            title: const Text('Billetera y Pagos', style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined, color: BeachColors.textSecondary, size: 21),
            title: const Text('Seguridad y Soporte', style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: BeachColors.textSecondary, size: 21),
            title: const Text('Acerca de Carúpano Riders', style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
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
          const Icon(Icons.two_wheeler, color: BeachColors.oceanPrimary, size: 13),
          const SizedBox(width: 4),
          Text(
            '$label • $eta',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: BeachColors.textMain),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? BeachColors.oceanLight.withOpacity(0.35) : BeachColors.backgroundSand,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BeachColors.oceanPrimary : BeachColors.lagoonBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? BeachColors.oceanPrimary : BeachColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isSelected ? BeachColors.oceanPrimary : BeachColors.textMain,
                    ),
                  ),
                  Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: BeachColors.textSecondary)),
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
      height: 40,
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
                hintStyle: const TextStyle(color: BeachColors.textMuted, fontSize: 11.5),
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
          color: isSelected ? BeachColors.oceanPrimary : BeachColors.backgroundSand,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? BeachColors.oceanPrimary : BeachColors.lagoonBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Buscando conductores',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: BeachColors.textMain),
        ),
        content: Text(
          'Solicitud enviada a conductores en Carúpano:\n\n'
          '• Recogida: ${_originController.text}\n'
          '• Destino: ${_destController.text}\n'
          '• Referencia: ${_refController.text}\n'
          '• Tarifa base: \$${estimatedPrice.toStringAsFixed(2)}\n'
          '• Método: ${selectedPayment == "pago_movil" ? "Pago Móvil" : "Efectivo"}',
          style: const TextStyle(fontSize: 12, color: BeachColors.textSecondary, height: 1.4),
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
// PANTALLA MODO CONDUCTOR (Minimalista y Funcional)
// -------------------------------------------------------------
class DriverHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToPassenger;
  const DriverHomeScreen({super.key, required this.onSwitchToPassenger});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isOnline = true;
  double driverWallet = 6.50;

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
      key: _scaffoldKey,
      backgroundColor: BeachColors.backgroundSand,
      drawer: _buildDriverDrawer(),
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
                  'Panel Conductor',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: BeachColors.textMain),
                ),
                Text(
                  isOnline ? 'En línea en Carúpano' : 'Pausado',
                  style: const TextStyle(fontSize: 10.5, color: BeachColors.textSecondary),
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
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: BeachColors.backgroundSand,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BeachColors.lagoonBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, color: BeachColors.textSecondary, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Pasajero',
                      style: TextStyle(color: BeachColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: BeachColors.pureWhite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: BeachColors.oceanLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: BeachColors.oceanPrimary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo disponible', style: TextStyle(color: BeachColors.textMuted, fontSize: 9.5)),
                        Text(
                          '\$${driverWallet.toStringAsFixed(2)} USD',
                          style: const TextStyle(color: BeachColors.textMain, fontWeight: FontWeight.w700, fontSize: 13),
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
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.75,
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

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitudes activas (${_rideRequests.length})',
                  style: const TextStyle(color: BeachColors.textMain, fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                const Text('En vivo', style: TextStyle(color: BeachColors.textMuted, fontSize: 10.5)),
              ],
            ),
          ),

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
                        Icon(Icons.nightlight_round_outlined, color: BeachColors.textMuted, size: 36),
                        SizedBox(height: 8),
                        Text('Turno pausado', style: TextStyle(color: BeachColors.textMain, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDrawer() {
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
                  child: Icon(Icons.two_wheeler, color: BeachColors.oceanPrimary, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Carlos (Mototaxista)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: BeachColors.textMain),
                    ),
                    Text(
                      'Bera SBR 150cc • Placa AA123',
                      style: TextStyle(fontSize: 11, color: BeachColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline, color: BeachColors.oceanPrimary, size: 22),
            title: const Text('Volver a Modo Pasajero', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              widget.onSwitchToPassenger();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: BeachColors.textSecondary, size: 21),
            title: const Text('Recargar Saldo de Comisión', style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: BeachColors.textSecondary, size: 21),
            title: const Text('Mis Ganancias de Hoy', style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: BeachColors.textSecondary, size: 21),
            title: const Text('Documentos del Vehículo', style: TextStyle(fontSize: 13, color: BeachColors.textMain)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> item) {
    final double offered = item['offeredPrice'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BeachColors.lagoonBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              Text(
                item['passenger'],
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: BeachColors.textMain),
              ),
              Text(
                '\$${offered.toStringAsFixed(2)}',
                style: const TextStyle(color: BeachColors.oceanPrimary, fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ],
          ),
          Text('A ${item['distance']} • ${item['payment']}', style: const TextStyle(color: BeachColors.textMuted, fontSize: 10.5)),
          const SizedBox(height: 8),
          Text('• ${item['pickup']} ➔ ${item['dropoff']}', style: const TextStyle(fontSize: 11.5, color: BeachColors.textSecondary)),
          Text('Ref: ${item['ref']}', style: const TextStyle(fontSize: 10.5, color: BeachColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () => _acceptRide(item, offered),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BeachColors.oceanPrimary,
                      foregroundColor: BeachColors.pureWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text('Aceptar \$${offered.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () => _acceptRide(item, offered + 0.50),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BeachColors.textMain,
                      side: const BorderSide(color: BeachColors.lagoonBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text('+\$0.50', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Carrera confirmada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: BeachColors.textMain)),
        content: Text(
          'Pasajero: ${item['passenger']}\n\n'
          '• Origen: ${item['pickup']}\n'
          '• Destino: ${item['dropoff']}\n'
          '• Tarifa acordada: \$${agreedPrice.toStringAsFixed(2)}\n'
          '• Comisión (10%): -\$${(agreedPrice * 0.10).toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12, color: BeachColors.textSecondary, height: 1.4),
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
                const SnackBar(content: Text('Ruta hacia el pasajero iniciada'), backgroundColor: BeachColors.oceanPrimary),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BeachColors.oceanPrimary,
              foregroundColor: BeachColors.pureWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Iniciar Ruta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}


