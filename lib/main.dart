import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/beach_colors.dart';
import 'screens/passenger/rider_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';

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
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('app_is_driver_mode') ?? false;
      if (mounted) {
        setState(() {
          isDriverMode = saved;
          _isLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoaded = true);
    }
  }

  Future<void> _toggleMode() async {
    final next = !isDriverMode;
    setState(() {
      isDriverMode = next;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_is_driver_mode', next);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(
        backgroundColor: BeachColors.backgroundSand,
        body: Center(child: CircularProgressIndicator(color: BeachColors.oceanPrimary)),
      );
    }

    final screenWidget = isDriverMode
        ? DriverHomeScreen(onSwitchToPassenger: _toggleMode)
        : RiderHomeScreen(onSwitchToDriver: _toggleMode);

    final size = MediaQuery.of(context).size;
    final isDesktopWeb = kIsWeb && size.width > 500;

    if (!isDesktopWeb) {
      // En celular / APK nativo o navegador móvil: pantalla completa nativa
      return screenWidget;
    }

    // En navegador de escritorio: marco simulador de teléfono elegante
    return Scaffold(
      backgroundColor: const Color(0xFFEDF4F8),
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
            child: screenWidget,
          ),
        ),
      ),
    );
  }
}

