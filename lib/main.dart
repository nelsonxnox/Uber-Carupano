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

class MainMobileFrameScreen extends StatelessWidget {
  const MainMobileFrameScreen({super.key});

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
            child: const RiderHomeScreen(),
          ),
        ),
      ),
    );
  }
}

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

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
                  'Sucre, Venezuela 🇻🇪',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
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

