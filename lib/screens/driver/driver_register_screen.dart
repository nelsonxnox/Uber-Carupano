import 'package:flutter/material.dart';
import '../../theme/beach_colors.dart';
import '../../services/driver_profile_service.dart';

class DriverRegisterScreen extends StatefulWidget {
  final VoidCallback onProfileSaved;
  const DriverRegisterScreen({super.key, required this.onProfileSaved});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();

  String _vehicleType = 'moto';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final existing = DriverProfileService().currentProfile;
    if (existing != null) {
      _nameController.text = existing.fullName;
      _phoneController.text = existing.phone;
      _vehicleType = existing.vehicleType;
      _modelController.text = existing.vehicleModel;
      _colorController.text = existing.vehicleColor;
      _plateController.text = existing.vehiclePlate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final service = DriverProfileService();
    final existing = service.currentProfile;
    final id = existing?.id ?? 'driver_${DateTime.now().millisecondsSinceEpoch}';

    final profile = DriverProfile(
      id: id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicleType: _vehicleType,
      vehicleModel: _modelController.text.trim(),
      vehicleColor: _colorController.text.trim(),
      vehiclePlate: _plateController.text.trim().toUpperCase(),
    );

    await service.saveProfile(profile);

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onProfileSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeachColors.backgroundSand,
      appBar: AppBar(
        backgroundColor: BeachColors.pureWhite,
        elevation: 1,
        title: const Text(
          'Registro de Conductor',
          style: TextStyle(
            color: BeachColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: BeachColors.oceanLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      size: 38,
                      color: BeachColors.oceanPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    '¡Configura tu perfil de chofer!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BeachColors.textMain,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Estos datos los verá el pasajero cuando aceptes un viaje en Carúpano',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: BeachColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Datos Personales',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: BeachColors.oceanPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre y Apellido',
                    hintText: 'Ej. Nelson Hernández',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: BeachColors.pureWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BeachColors.lagoonBorder),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono (Pago Móvil / WhatsApp)',
                    hintText: '0414-1234567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: BeachColors.pureWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BeachColors.lagoonBorder),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa un número telefónico';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                const Text(
                  'Datos del Vehículo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: BeachColors.oceanPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _vehicleType = 'moto'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _vehicleType == 'moto'
                                ? BeachColors.oceanPrimary
                                : BeachColors.pureWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _vehicleType == 'moto'
                                  ? BeachColors.oceanPrimary
                                  : BeachColors.lagoonBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.two_wheeler,
                                color: _vehicleType == 'moto'
                                    ? Colors.white
                                    : BeachColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Moto',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _vehicleType == 'moto'
                                      ? Colors.white
                                      : BeachColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _vehicleType = 'auto'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _vehicleType == 'auto'
                                ? BeachColors.oceanPrimary
                                : BeachColors.pureWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _vehicleType == 'auto'
                                  ? BeachColors.oceanPrimary
                                  : BeachColors.lagoonBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: _vehicleType == 'auto'
                                    ? Colors.white
                                    : BeachColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Carro',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _vehicleType == 'auto'
                                      ? Colors.white
                                      : BeachColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: _vehicleType == 'moto'
                        ? 'Modelo de Moto (ej. Bera SBR 150, Empire Keeway)'
                        : 'Modelo de Auto (ej. Chevrolet Aveo, Toyota Corolla)',
                    prefixIcon: const Icon(Icons.speed_outlined),
                    filled: true,
                    fillColor: BeachColors.pureWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BeachColors.lagoonBorder),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa el modelo del vehículo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _colorController,
                        decoration: InputDecoration(
                          labelText: 'Color',
                          hintText: 'Azul, Rojo, Negro...',
                          prefixIcon: const Icon(Icons.color_lens_outlined),
                          filled: true,
                          fillColor: BeachColors.pureWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BeachColors.lagoonBorder),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Color requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Placa',
                          hintText: 'AE5K82M',
                          prefixIcon: const Icon(Icons.pin_outlined),
                          filled: true,
                          fillColor: BeachColors.pureWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BeachColors.lagoonBorder),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Placa requerida';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BeachColors.emeraldSuccess,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Guardar Perfil y Comenzar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
