import 'package:flutter/material.dart';
import '../../services/trip_history_service.dart';
import '../../theme/beach_colors.dart';

class DriverFinancesSheet extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverFinancesSheet({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  static Future<void> show(
    BuildContext context, {
    required String driverId,
    required String driverName,
  }) {
    final isDesktopWeb = MediaQuery.of(context).size.width > 500;

    if (isDesktopWeb) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SizedBox(
            width: 480,
            height: 660,
            child: Material(
              color: BeachColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: DriverFinancesSheet(
                driverId: driverId,
                driverName: driverName,
              ),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Material(
        color: Colors.transparent,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Material(
            color: BeachColors.pureWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: DriverFinancesSheet(
              driverId: driverId,
              driverName: driverName,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<DriverFinancesSheet> createState() => _DriverFinancesSheetState();
}

class _DriverFinancesSheetState extends State<DriverFinancesSheet> {
  final TripHistoryService _historyService = TripHistoryService();

  // Tasa de cambio referencial (Bs por USD) para ayuda de cálculo
  final double _usdToBsRate = 45.0;

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month  $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _historyService,
      builder: (context, _) {
        final trips = _historyService.trips;
        final totalGross = _historyService.totalGrossEarnings;
        final totalComm = _historyService.totalCommission;
        final totalNet = _historyService.totalNetEarnings;
        final isLimitExceeded = totalComm >= TripHistoryService.maxDebtLimit;

        return Scaffold(
          backgroundColor: BeachColors.pureWhite,
          body: Column(
            children: [
              // ─── Header ───
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                decoration: const BoxDecoration(
                  color: BeachColors.pureWhite,
                  border: Border(bottom: BorderSide(color: BeachColors.lagoonBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BeachColors.oceanLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: BeachColors.oceanPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finanzas y Billetera',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: BeachColors.textMain,
                            ),
                          ),
                          Text(
                            'Comisión de plataforma: 5% por viaje',
                            style: TextStyle(
                              fontSize: 11,
                              color: BeachColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: BeachColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ─── Contenido Scrolleable ───
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. TARJETA PRINCIPAL: Comisión pendiente por pagar a la App
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLimitExceeded
                              ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
                              : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLimitExceeded ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'COMISIÓN POR PAGAR (5%)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: isLimitExceeded ? const Color(0xFF991B1B) : const Color(0xFF166534),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isLimitExceeded ? const Color(0xFFEF4444) : BeachColors.emeraldSuccess,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isLimitExceeded ? '⚠️ Límite Excedido' : '🟢 Al día',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '\$${totalComm.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: isLimitExceeded ? const Color(0xFFB91C1C) : const Color(0xFF14532D),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'USD',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: BeachColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '≈ Bs. ${(totalComm * _usdToBsRate).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: BeachColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '📅 Fecha de corte: Todos los viernes 11:59 PM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: BeachColors.textSecondary,
                            ),
                          ),
                          if (isLimitExceeded) ...[
                            const SizedBox(height: 6),
                            const Text(
                              '⚠️ Superaste el límite de \$10.00 USD. Realiza tu abono para seguir recibiendo carreras.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.payment_rounded, size: 16),
                              label: const Text(
                                'Reportar Pago de Comisión (Pago Móvil)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLimitExceeded ? const Color(0xFFDC2626) : BeachColors.oceanPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showPaymentReportDialog(context, totalComm),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. RESUMEN: Ganancias brutas vs netas
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: BeachColors.backgroundSand,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: BeachColors.lagoonBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cobrado Bruto',
                                  style: TextStyle(fontSize: 11, color: BeachColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${totalGross.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: BeachColors.textMain,
                                  ),
                                ),
                                const Text(
                                  'Total pasajeros',
                                  style: TextStyle(fontSize: 9.5, color: BeachColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: BeachColors.backgroundSand,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: BeachColors.lagoonBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tu Ganancia Neta',
                                  style: TextStyle(fontSize: 11, color: BeachColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${totalNet.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: BeachColors.emeraldSuccess,
                                  ),
                                ),
                                const Text(
                                  '95% para ti',
                                  style: TextStyle(fontSize: 9.5, color: BeachColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 3. TÍTULO DE DETALLE DE VIAJES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Desglose por Viaje',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: BeachColors.textMain,
                          ),
                        ),
                        Text(
                          '${trips.length} viajes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: BeachColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4. LISTA DE VIAJES CON DESCUENTO DE 5%
                    if (trips.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.directions_bike_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'Aún no tienes viajes registrados esta semana.',
                              style: TextStyle(fontSize: 12, color: BeachColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ...trips.map((t) => _buildTripFinanceCard(t)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripFinanceCard(CompletedTrip trip) {
    final dateStr = _formatDate(trip.timestamp);
    final netEarned = trip.price - trip.commissionAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeachColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BeachColors.lagoonBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  trip.passengerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BeachColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 10.5, color: BeachColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${trip.pickupAddress} ➔ ${trip.dropoffAddress}',
            style: const TextStyle(fontSize: 11, color: BeachColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: BeachColors.lagoonBorder),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cobrado:', style: TextStyle(fontSize: 9.5, color: BeachColors.textMuted)),
                  Text(
                    '\$${trip.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: BeachColors.textMain),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Comisión App (5%):', style: TextStyle(fontSize: 9.5, color: Color(0xFFDC2626))),
                  Text(
                    '-\$${trip.commissionAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Tu Ganancia:', style: TextStyle(fontSize: 9.5, color: BeachColors.emeraldSuccess)),
                  Text(
                    '+\$${netEarned.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: BeachColors.emeraldSuccess),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentReportDialog(BuildContext context, double currentCommission) {
    final refController = TextEditingController();
    final amountController = TextEditingController(
      text: currentCommission > 0 ? currentCommission.toStringAsFixed(2) : '1.00',
    );
    String selectedBank = 'Banco de Venezuela';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: BeachColors.oceanPrimary),
              SizedBox(width: 8),
              Text('Reportar Pago Móvil', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos para tu Pago Móvil:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                      SizedBox(height: 4),
                      Text('• Banco: Banco de Venezuela (0102)', style: TextStyle(fontSize: 11)),
                      Text('• Teléfono: 0412-1234567', style: TextStyle(fontSize: 11)),
                      Text('• Cédula: V-28.123.456', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Monto en USD abonado:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Banco emisor:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedBank,
                  isDense: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Banco de Venezuela', child: Text('Banco de Venezuela', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Banesco', child: Text('Banesco', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Mercantil', child: Text('Mercantil', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Bancaribe', child: Text('Bancaribe', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'Otro Banco', child: Text('Otro Banco', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedBank = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Número de Referencia (últimos 4 a 6 dígitos):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: refController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ej. 849201',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: BeachColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BeachColors.emeraldSuccess,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final ref = refController.text.trim();
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (ref.isEmpty || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa un monto válido y la referencia bancaria.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final ok = await _historyService.reportCommissionPayment(
                  driverId: widget.driverId,
                  amountUsd: amt,
                  reference: ref,
                  bank: selectedBank,
                );

                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Reporte de pago de \$$amt USD enviado con éxito. Saldo actualizado.'),
                      backgroundColor: BeachColors.emeraldSuccess,
                    ),
                  );
                }
              },
              child: const Text('Confirmar Pago', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
