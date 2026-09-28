import 'package:flutter/material.dart';
import '../../theme/beach_colors.dart';

class OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  final String tag;

  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
  });
}

class AppTutorialModal extends StatefulWidget {
  final VoidCallback onCompleted;

  const AppTutorialModal({super.key, required this.onCompleted});

  @override
  State<AppTutorialModal> createState() => _AppTutorialModalState();
}

class _AppTutorialModalState extends State<AppTutorialModal> {
  int _currentIndex = 0;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      icon: Icons.map_outlined,
      tag: 'PASO 1 • MAPA INTERACTIVO',
      title: 'Elige a dónde quieres ir',
      description:
          'Toca cualquier lugar en el mapa de Carúpano o usa los accesos rápidos (Playa Copey, Plaza Bolívar, Mercado, Terminal) para marcar tu destino.',
    ),
    OnboardingStep(
      icon: Icons.attach_money_rounded,
      tag: 'PASO 2 • TARIFA JUSTA',
      title: 'Propón tu precio sugerido',
      description:
          'La app te sugiere un monto base según la distancia real por calles, pero tú puedes ajustar el precio con los botones + y -.',
    ),
    OnboardingStep(
      icon: Icons.two_wheeler_rounded,
      tag: 'PASO 3 • RADAR DE CHOFERES',
      title: 'Elige al mejor mototaxista',
      description:
          'Los conductores cercanos recibirán tu solicitud. Verás quién acepta o quién te contraoferta para que tú elijas el más rápido o económico.',
    ),
    OnboardingStep(
      icon: Icons.sports_motorsports_outlined,
      tag: 'PASO 4 • ¿QUIERES GANAR DINERO?',
      title: 'Conviértete en Conductor',
      description:
          'Abre el menú lateral cuando quieras y toca "Modo Conductor". Registra tu moto o carro y empieza a recibir carreras de inmediato.',
    ),
  ];

  void _next() {
    if (_currentIndex < _steps.length - 1) {
      setState(() => _currentIndex++);
    } else {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BeachColors.pureWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior de progreso con puntos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: BeachColors.oceanLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    step.tag,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: BeachColors.oceanPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onCompleted,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 24)),
                  child: const Text(
                    'Saltar',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: BeachColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Ícono ilustrativo en burbuja marina
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: BeachColors.backgroundSand,
                shape: BoxShape.circle,
                border: Border.all(color: BeachColors.lagoonBorder, width: 2),
              ),
              child: Icon(
                step.icon,
                size: 38,
                color: BeachColors.oceanPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // Título
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: BeachColors.textMain,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 8),

            // Descripción pedagógica
            Text(
              step.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: BeachColors.textSecondary,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 22),

            // Indicadores de puntitos (dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                final bool isActive = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? BeachColors.oceanPrimary : BeachColors.lagoonBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Botón de Siguiente / Entendido
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BeachColors.oceanPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _next,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentIndex == _steps.length - 1 ? '¡Entendido, empezar!' : 'Siguiente',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _currentIndex == _steps.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )));
  }
}
