import 'package:flutter/material.dart';
import '../../theme/beach_colors.dart';
import '../../services/auth_service.dart';

class WelcomeRegisterScreen extends StatefulWidget {
  final VoidCallback onRegistrationSuccess;

  const WelcomeRegisterScreen({super.key, required this.onRegistrationSuccess});

  @override
  State<WelcomeRegisterScreen> createState() => _WelcomeRegisterScreenState();
}

class _WelcomeRegisterScreenState extends State<WelcomeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoginMode = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _quickFillWithGoogle() {
    setState(() {
      if (_nameController.text.isEmpty) _nameController.text = 'Nelson Blanco';
      if (_emailController.text.isEmpty) _emailController.text = 'nelson@gmail.com';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ ¡Conectado con Google! Ingresa tu teléfono para continuar.'),
        backgroundColor: BeachColors.emeraldSuccess,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final rawPhone = _phoneController.text.trim();
    final fullPhone = rawPhone.startsWith('+58') ? rawPhone : '+58 $rawPhone';

    await AuthService().registerPassenger(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: fullPhone,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onRegistrationSuccess();
    }
  }

  Future<void> _submitLogin() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Por favor ingresa tu número de teléfono.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = await AuthService().loginWithPhone(rawPhone);

    if (mounted) {
      setState(() => _isSaving = false);
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ¡Bienvenido de nuevo, ${user.fullName}!'),
            backgroundColor: BeachColors.emeraldSuccess,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onRegistrationSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No se encontró ninguna cuenta registrada con este número. Por favor regístrate.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeachColors.backgroundSand,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Logotipo / Emblema Costero Minimalista
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: BeachColors.oceanLight,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: BeachColors.lagoonBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: BeachColors.oceanPrimary.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.waves_rounded,
                      color: BeachColors.oceanPrimary,
                      size: 38,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'MoviCarúpano',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: BeachColors.textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tu transporte rápido y seguro en Carúpano',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: BeachColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Selector de Pestañas: Registrarse vs Iniciar Sesión
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: BeachColors.pureWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BeachColors.lagoonBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLoginMode = false),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLoginMode ? BeachColors.oceanPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Crear Cuenta',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: !_isLoginMode ? FontWeight.bold : FontWeight.w600,
                                    color: !_isLoginMode ? Colors.white : BeachColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLoginMode = true),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLoginMode ? BeachColors.oceanPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _isLoginMode ? FontWeight.bold : FontWeight.w600,
                                    color: _isLoginMode ? Colors.white : BeachColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tarjeta Contenedora Principal
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: BeachColors.pureWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BeachColors.lagoonBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isLoginMode ? Icons.login_rounded : Icons.person_add_outlined,
                              size: 18,
                              color: BeachColors.oceanPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isLoginMode ? 'Acceder a tu Cuenta' : 'Crear Perfil de Pasajero',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: BeachColors.textMain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoginMode
                              ? 'Ingresa tu número de teléfono registrado para entrar.'
                              : 'Ingresa tus datos para comenzar a pedir carreras.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: BeachColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (!_isLoginMode) ...[
                          // Botón de Inicio Rápido con Google
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: BeachColors.pureWhite,
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _quickFillWithGoogle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          color: Color(0xFFEA4335),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Continuar con Google',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: BeachColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              const Expanded(child: Divider(color: BeachColors.lagoonBorder, height: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'o completa manualmente',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: BeachColors.textSecondary.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: BeachColors.lagoonBorder, height: 1)),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Campo 1: Nombre Completo
                          const Text(
                            'NOMBRE Y APELLIDO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: BeachColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Ej: Nelson Gómez',
                              hintStyle: const TextStyle(
                                  fontSize: 12.5, color: BeachColors.textMuted),
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: BeachColors.textSecondary, size: 20),
                              filled: true,
                              fillColor: BeachColors.backgroundSand,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: BeachColors.lagoonBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: BeachColors.lagoonBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: BeachColors.oceanPrimary, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (_isLoginMode) return null;
                              if (val == null || val.trim().length < 3) {
                                return 'Ingresa tu nombre completo';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),
                        ],

                        // Campo: Teléfono Móvil (Visible tanto en registro como en login)
                        const Text(
                          'NÚMERO DE TELÉFONO (PAGO MÓVIL / SMS)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: BeachColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '0412 1234567',
                            hintStyle: const TextStyle(
                                fontSize: 12.5, color: BeachColors.textMuted),
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: BeachColors.lagoonBorder, width: 1.2),
                                ),
                              ),
                              child: const Text(
                                '+58',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: BeachColors.textMain,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            filled: true,
                            fillColor: BeachColors.backgroundSand,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: BeachColors.lagoonBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: BeachColors.lagoonBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: BeachColors.oceanPrimary, width: 1.5),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().length < 7) {
                              return 'Ingresa tu número (Ej: 0412 1234567)';
                            }
                            return null;
                          },
                        ),

                        if (!_isLoginMode) ...[
                          const SizedBox(height: 16),

                          // Campo: Correo Electrónico
                          const Text(
                            'CORREO ELECTRÓNICO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: BeachColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'ejemplo@correo.com',
                              hintStyle: const TextStyle(
                                  fontSize: 12.5, color: BeachColors.textMuted),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: BeachColors.textSecondary, size: 20),
                              filled: true,
                              fillColor: BeachColors.backgroundSand,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: BeachColors.lagoonBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: BeachColors.lagoonBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: BeachColors.oceanPrimary, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (_isLoginMode) return null;
                              if (val == null || !val.contains('@') || !val.contains('.')) {
                                return 'Ingresa un correo electrónico válido';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Botón de Acción Principal (Registro o Login)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BeachColors.oceanPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isSaving
                                ? null
                                : (_isLoginMode ? _submitLogin : _submitRegistration),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLoginMode ? 'Entrar a mi Cuenta' : 'Empezar a Viajar',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 18, color: Colors.white),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Enlace para alternar entre Registro e Iniciar Sesión
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                              });
                            },
                            child: Text(
                              _isLoginMode
                                  ? '¿No tienes cuenta aún? Regístrate aquí'
                                  : '¿Ya estás registrado? Inicia sesión aquí',
                              style: const TextStyle(
                                fontSize: 12,
                                color: BeachColors.oceanPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _isLoginMode
                        ? 'Al iniciar sesión podrás ver tus viajes completados, saldo y solicitar o prestar servicios.'
                        : 'Al registrarte podrás pedir mototaxis y taxis en Carúpano y negociar tu tarifa directamente con los conductores.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: BeachColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
