import 'package:flutter/material.dart';

void main() {
  runApp(const CarupanoRidersApp());
}

class CarupanoRidersApp extends StatelessWidget {
  const CarupanoRidersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carúpano Riders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          primary: const Color(0xFFFF9800),
        ),
        useMaterial3: true,
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
  // false = Modo Pasajero, true = Modo Conductor (estilo InDrive)
  bool isDriverMode = false;

  void _toggleMode() {
    setState(() {
      isDriverMode = !isDriverMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: Container(
          width: 395,
          height: 800,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0xFF333333), width: 8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: isDriverMode
                ? DriverHomeScreen(onSwitchToPassenger: _toggleMode)
                : RiderHomeScreen(onSwitchToDriver: _toggleMode),
          ),
        ),
      ),
    );
  }
}

class RiderHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToDriver;
  const RiderHomeScreen({super.key, required this.onSwitchToDriver});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String selectedService = 'moto';
  String selectedPayment = 'pago_movil';
  final TextEditingController _originController = TextEditingController(text: 'Plaza Colón, Centro');
  final TextEditingController _destController = TextEditingController(text: 'Playa Grande, El Peñón');
  final TextEditingController _refController = TextEditingController(text: 'Frente a la panadería');

  double get estimatedPrice => selectedService == 'moto' ? 2.50 : 5.00;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.two_wheeler, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carúpano Riders',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  'Modo Pasajero 🚶‍♂️',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botón InDrive para cambiar a Modo Conductor
          TextButton.icon(
            onPressed: widget.onSwitchToDriver,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFF3CD),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.sports_motorsports, color: Color(0xFF856404), size: 18),
            label: const Text(
              'Modo Chofer',
              style: TextStyle(color: Color(0xFF856404), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: const Color(0xFFE2E8F0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 20),
                              SizedBox(width: 6),
                              Text('GPS: Carúpano Centro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDriverMarker('🏍️ Moto 1', '3 min'),
                            const SizedBox(width: 30),
                            _buildDriverMarker('🏍️ Moto 2', '5 min'),
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
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    onPressed: () {},
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceOption(
                        id: 'moto',
                        title: 'Mototaxi',
                        subtitle: 'Rápido',
                        price: '\$2.50',
                        icon: Icons.two_wheeler,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildServiceOption(
                        id: 'taxi',
                        title: 'Taxi Carro',
                        subtitle: 'Cómodo',
                        price: '\$5.00',
                        icon: Icons.local_taxi,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildAddressInput(
                  icon: Icons.trip_origin,
                  iconColor: Colors.green,
                  controller: _originController,
                  hint: 'Punto de recogida (Ej: Plaza Colón)',
                ),
                const SizedBox(height: 8),
                _buildAddressInput(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  controller: _destController,
                  hint: '¿A dónde vas? (Ej: Playa Grande)',
                ),
                const SizedBox(height: 8),
                _buildAddressInput(
                  icon: Icons.info_outline,
                  iconColor: Colors.orange,
                  controller: _refController,
                  hint: 'Punto de referencia (Portón, comercio)',
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('📱 Pago Móvil', style: TextStyle(fontSize: 12)),
                          selected: selectedPayment == 'pago_movil',
                          onSelected: (val) => setState(() => selectedPayment = 'pago_movil'),
                          selectedColor: const Color(0xFFFFE082),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('💵 Efectivo', style: TextStyle(fontSize: 12)),
                          selected: selectedPayment == 'efectivo',
                          onSelected: (val) => setState(() => selectedPayment = 'efectivo'),
                          selectedColor: const Color(0xFFFFE082),
                        ),
                      ],
                    ),
                    Text(
                      '~\$${estimatedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showRequestDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'PEDIR ${selectedService.toUpperCase()} AHORA',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildDriverMarker(String name, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text(time, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildServiceOption({
    required String id,
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
  }) {
    final bool isSelected = selectedService == id;
    return GestureDetector(
      onTap: () => setState(() => selectedService = id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8E1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB300) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.grey.shade600, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(price, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInput({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Buscando Chofer! 🏍️'),
        content: Text(
          'Solicitud enviada a los conductores cercanos en Carúpano.\n\n'
          '📍 Recogida: ${_originController.text}\n'
          '🏁 Destino: ${_destController.text}\n'
          '📌 Ref: ${_refController.text}\n'
          '💰 Tarifa: \$${estimatedPrice.toStringAsFixed(2)}\n'
          '💳 Pago: ${selectedPayment == "pago_movil" ? "Pago Móvil" : "Efectivo"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar Viaje', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300), foregroundColor: Colors.black),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// PANTALLA MODO CONDUCTOR / MOTOTAXISTA (Estilo InDrive)
// -------------------------------------------------------------
class DriverHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToPassenger;
  const DriverHomeScreen({super.key, required this.onSwitchToPassenger});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool isOnline = true;
  double driverWallet = 4.80; // Saldo de comisiones en dólares

  // Lista simulada de solicitudes abiertas en Carúpano estilo InDrive
  final List<Map<String, dynamic>> _rideRequests = [
    {
      'id': '1',
      'passenger': 'María González',
      'pickup': 'Hospital Santos Aníbal Dominicci',
      'dropoff': 'Plaza Miranda, Centro',
      'ref': 'Portón de Emergencias, franela azul',
      'distance': '1.8 km',
      'offeredPrice': 2.00,
      'payment': 'Pago Móvil (Banesco)',
      'type': 'Mototaxi',
    },
    {
      'id': '2',
      'passenger': 'Carlos Ramírez',
      'pickup': 'Terminal de Pasajeros de Carúpano',
      'dropoff': 'Playa Grande (Entrada Caserío)',
      'ref': 'Frente a la parada de buses',
      'distance': '4.2 km',
      'offeredPrice': 3.00,
      'payment': 'Efectivo $',
      'type': 'Mototaxi',
    },
    {
      'id': '3',
      'passenger': 'Elena Salazar',
      'pickup': 'Av. Perimetral (Frente a Traki)',
      'dropoff': 'Canchunchú Viejo',
      'ref': 'Casa rejas negras con mata de mango',
      'distance': '3.5 km',
      'offeredPrice': 2.50,
      'payment': 'Pago Móvil',
      'type': 'Mototaxi',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262A34),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel del Chofer 🏍️',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isOnline ? 'En línea (Carúpano)' : 'Desconectado',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botón para volver a Modo Pasajero
          TextButton.icon(
            onPressed: widget.onSwitchToPassenger,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF333846),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.person, color: Colors.amber, size: 18),
            label: const Text(
              'Pasajero',
              style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra de estado de conexión y Billetera de comisiones
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF262A34),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Saldo de recarga de comisiones
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo comisión', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Text(
                          '\$${driverWallet.toStringAsFixed(2)} USD',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),

                // Switch En línea / Desconectado
                Row(
                  children: [
                    Text(
                      isOnline ? 'CONECTADO' : 'PAUSADO',
                      style: TextStyle(
                        color: isOnline ? Colors.greenAccent : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Switch(
                      value: isOnline,
                      activeColor: const Color(0xFFFFB300),
                      onChanged: (val) {
                        setState(() {
                          isOnline = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Título de solicitudes abiertas
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitudes Cercanas (${_rideRequests.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Text('Orden: Más recientes', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),

          // Lista de carreras estilo InDrive con botón aceptar / contraofertar
          Expanded(
            child: isOnline
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    itemCount: _rideRequests.length,
                    itemBuilder: (context, index) {
                      final item = _rideRequests[index];
                      return _buildInDriveRequestCard(item);
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.power_settings_new, color: Colors.grey, size: 50),
                        SizedBox(height: 10),
                        Text(
                          'Estás desconectado',
                          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Activa el interruptor arriba para recibir carreras.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInDriveRequestCard(Map<String, dynamic> item) {
    final double offered = item['offeredPrice'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF262A34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF383D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: Pasajero, distancia y precio ofrecido
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.amber,
                    child: Text(
                      item['passenger'][0],
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['passenger'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'A ${item['distance']} • ${item['payment']}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B382A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${offered.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF383D4D), height: 18),

          // Ruta y Referencia
          Row(
            children: [
              const Icon(Icons.trip_origin, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['pickup'],
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['dropoff'],
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ref: ${item['ref']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botones de acción estilo InDrive: Aceptar o Contraofertar
          Row(
            children: [
              // Botón Aceptar la tarifa del pasajero
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () {
                    _acceptRide(item, offered);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'ACEPTAR \$${offered.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botón Contraofertar +$0.50
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    _acceptRide(item, offered + 0.50);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF555D75)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    '+\$0.50 (\$${(offered + 0.5).toStringAsFixed(2)})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
        backgroundColor: const Color(0xFF262A34),
        title: const Text('¡Carrera Asignada! 🎉', style: TextStyle(color: Colors.white)),
        content: Text(
          'Vas a buscar a ${item['passenger']}.\n\n'
          '📍 Origen: ${item['pickup']}\n'
          '📌 Ref: ${item['ref']}\n'
          '🏁 Destino: ${item['dropoff']}\n'
          '💰 Precio acordado: \$${agreedPrice.toStringAsFixed(2)}\n'
          '💳 Método: ${item['payment']}\n'
          '📉 Comisión app (10%): -\$${(agreedPrice * 0.10).toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white54)),
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
                  content: Text('Navegación hacia el pasajero iniciada'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300), foregroundColor: Colors.black),
            child: const Text('Iniciar Ruta'),
          ),
        ],
      ),
    );
  }
}

