import 'package:flutter/material.dart';
import '../../theme/beach_colors.dart';
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



