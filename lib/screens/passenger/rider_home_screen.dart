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
  String selectedService = 'moto';
  String selectedPayment = 'pago_movil';
  final TextEditingController _originController = TextEditingController(text: 'Plaza Bolívar, Centro');
  final TextEditingController _destController = TextEditingController(text: 'Playa Copey');
  final TextEditingController _refController = TextEditingController(text: 'Frente a la fuente principal');

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
            // Vista del Mapa Simulado de Carúpano
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

            // Formulario de Solicitud (Limpio y ordenado)
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
                          price: '\.50',
                          icon: Icons.two_wheeler_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildServiceCard(
                          id: 'taxi',
                          title: 'Taxi Carro',
                          time: 'Hasta 4 • 5 min',
                          price: '\.00',
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
                        '~\{estimatedPrice.toStringAsFixed(2)}',
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
                        'SOLICITAR ',
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
            ' • ',
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
          '• Recogida: \n'
          '• Destino: \n'
          '• Referencia: \n'
          '• Tarifa base: \{estimatedPrice.toStringAsFixed(2)}\n'
          '• Método: ',
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