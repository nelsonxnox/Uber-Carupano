import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../theme/beach_colors.dart';

class AddressSearchResult {
  final String title;
  final String subtitle;
  final LatLng point;
  final IconData icon;

  const AddressSearchResult({
    required this.title,
    required this.subtitle,
    required this.point,
    this.icon = Icons.location_on_outlined,
  });
}

class AddressSelectionResult {
  final String originText;
  final LatLng originPoint;
  final String destinationText;
  final LatLng destinationPoint;
  final bool chooseOnMap;
  final String? mapMode; // 'origin' o 'destination'

  const AddressSelectionResult({
    required this.originText,
    required this.originPoint,
    required this.destinationText,
    required this.destinationPoint,
    this.chooseOnMap = false,
    this.mapMode,
  });
}

class AddressSearchScreen extends StatefulWidget {
  final String initialOrigin;
  final String initialDestination;
  final LatLng originPoint;
  final LatLng destinationPoint;
  final bool startWithDestination;
  final List<Map<String, dynamic>> popularPlaces;

  const AddressSearchScreen({
    super.key,
    required this.initialOrigin,
    required this.initialDestination,
    required this.originPoint,
    required this.destinationPoint,
    required this.startWithDestination,
    required this.popularPlaces,
  });

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  late TextEditingController _originController;
  late TextEditingController _destController;
  late LatLng _currentOriginPoint;
  late LatLng _currentDestPoint;
  late String _activeField; // 'origin' o 'destination'

  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  Timer? _debounce;
  bool _isLoading = false;
  List<AddressSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: widget.initialOrigin);
    _destController = TextEditingController(text: widget.initialDestination);
    _currentOriginPoint = widget.originPoint;
    _currentDestPoint = widget.destinationPoint;
    _activeField = widget.startWithDestination ? 'destination' : 'origin';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startWithDestination) {
        _destFocus.requestFocus();
      } else {
        _originFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _originController.dispose();
    _destController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final tempText = _originController.text;
      _originController.text = _destController.text;
      _destController.text = tempText;

      final tempPoint = _currentOriginPoint;
      _currentOriginPoint = _currentDestPoint;
      _currentDestPoint = tempPoint;
    });
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 380), () {
      _executeSearch(trimmed);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() => _isLoading = true);

    final List<AddressSearchResult> results = [];
    final lowerQuery = query.toLowerCase();

    // 1. Filtrado instantáneo en sitios populares de Carúpano
    for (final p in widget.popularPlaces) {
      final title = (p['title'] as String? ?? '').toLowerCase();
      final subtitle = (p['subtitle'] as String? ?? '').toLowerCase();
      if (title.contains(lowerQuery) || subtitle.contains(lowerQuery)) {
        results.add(AddressSearchResult(
          title: p['title'] as String,
          subtitle: p['subtitle'] as String? ?? 'Lugar frecuente de Carúpano',
          point: p['point'] as LatLng,
          icon: (p['icon'] as IconData?) ?? Icons.place,
        ));
      }
    }

    // 2. Consulta en vivo a Nominatim OSM acotada a Carúpano, Sucre, Venezuela
    try {
      final String encoded = Uri.encodeComponent('$query, Carúpano, Venezuela');
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&countrycodes=ve&viewbox=-63.38,10.60,-63.18,10.75&bounded=0&limit=7&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'CarupanoRidersApp/1.0 (contacto@carupanoriders.app)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        for (final item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            final displayName = (item['display_name'] as String? ?? '');
            final parts = displayName.split(',');
            final cleanTitle = parts.isNotEmpty ? parts[0].trim() : query;
            final cleanSubtitle = parts.length > 1
                ? parts.sublist(1, parts.length > 3 ? 3 : parts.length).join(',').trim()
                : 'Carúpano, Sucre';

            final isDuplicate = results.any(
              (r) => (r.point.latitude - lat).abs() < 0.001 && (r.point.longitude - lon).abs() < 0.001,
            );

            if (!isDuplicate) {
              results.add(AddressSearchResult(
                title: cleanTitle,
                subtitle: cleanSubtitle,
                point: LatLng(lat, lon),
                icon: Icons.location_on_outlined,
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error buscando dirección en Nominatim: ');
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _onPlaceSelected(AddressSearchResult item) {
    if (_activeField == 'origin') {
      setState(() {
        _originController.text = item.title;
        _currentOriginPoint = item.point;
      });

      // Si el destino todavía está vacío o genérico, pasamos al destino
      if (_destController.text.trim().isEmpty || _destController.text.contains('Punto en mapa')) {
        setState(() {
          _activeField = 'destination';
          _searchResults = [];
        });
        _destFocus.requestFocus();
      } else {
        // Listo: retornar ambos
        _confirmAndClose();
      }
    } else {
      // Editando Destino
      setState(() {
        _destController.text = item.title;
        _currentDestPoint = item.point;
      });
      _confirmAndClose();
    }
  }

  void _confirmAndClose() {
    Navigator.pop(
      context,
      AddressSelectionResult(
        originText: _originController.text,
        originPoint: _currentOriginPoint,
        destinationText: _destController.text,
        destinationPoint: _currentDestPoint,
      ),
    );
  }

  Future<void> _useCurrentGpsLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) {
        setState(() {
          _originController.text = 'Mi Ubicación actual (GPS)';
          _currentOriginPoint = LatLng(position.latitude, position.longitude);
          _activeField = 'destination';
          _isLoading = false;
        });
        _destFocus.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _originController.text = 'Plaza Bolívar (Centro)';
          _currentOriginPoint = const LatLng(10.6678, -63.2585);
          _activeField = 'destination';
          _isLoading = false;
        });
        _destFocus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    final scaffoldContent = _buildScaffoldContent();

    if (isMobile) {
      return scaffoldContent;
    }

    // En pantallas de escritorio / web ancha, mantenemos el marco móvil idéntico a inDrive
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
                color: const Color(0xFF0F2B48).withValues(alpha: 0.12),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
            ],
            border: Border.all(color: const Color(0xFFD6E4ED), width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: scaffoldContent,
          ),
        ),
      ),
    );
  }

  Widget _buildScaffoldContent() {
    final activeController = _activeField == 'origin' ? _originController : _destController;
    final bool hasQuery = activeController.text.trim().isNotEmpty && _searchResults.isNotEmpty;

    return Scaffold(
      backgroundColor: BeachColors.backgroundSand,
      appBar: AppBar(
        backgroundColor: BeachColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BeachColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ruta de viaje',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: BeachColors.textMain,
          ),
        ),
        actions: [
          if (_originController.text.isNotEmpty && _destController.text.isNotEmpty)
            TextButton(
              onPressed: _confirmAndClose,
              child: const Text(
                'Listo',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: BeachColors.oceanPrimary,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: BeachColors.lagoonBorder, height: 1),
        ),
      ),
      body: Column(
        children: [
          // PANEL SUPERIOR CONECTADO: RECOGIDA + DESTINO (Estilo inDrive)
          Container(
            color: BeachColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BeachColors.backgroundSand,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BeachColors.lagoonBorder, width: 1.2),
              ),
              child: Row(
                children: [
                  // Iconografía conectada vertical con puntos
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BeachColors.pureWhite,
                          border: Border.all(color: BeachColors.oceanPrimary, width: 3),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 24,
                        color: BeachColors.oceanLight,
                      ),
                      const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 16),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Campos de texto para ambos puntos
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Campo 1: ¿De dónde sales? (Recogida)
                        InkWell(
                          onTap: () {
                            setState(() => _activeField = 'origin');
                            _originFocus.requestFocus();
                          },
                          child: Container(
                            height: 34,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: _activeField == 'origin' ? BeachColors.pureWhite : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: _activeField == 'origin'
                                  ? Border.all(color: BeachColors.oceanPrimary, width: 1.2)
                                  : null,
                            ),
                            child: TextField(
                              controller: _originController,
                              focusNode: _originFocus,
                              onTap: () => setState(() => _activeField = 'origin'),
                              onChanged: (val) {
                                setState(() => _activeField = 'origin');
                                _onQueryChanged(val);
                              },
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: BeachColors.textMain),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: '¿De dónde sales? (Recogida)',
                                hintStyle: TextStyle(color: BeachColors.textMuted, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 8, color: BeachColors.lagoonBorder),

                        // Campo 2: ¿A dónde vas? (Destino)
                        InkWell(
                          onTap: () {
                            setState(() => _activeField = 'destination');
                            _destFocus.requestFocus();
                          },
                          child: Container(
                            height: 34,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: _activeField == 'destination' ? BeachColors.pureWhite : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: _activeField == 'destination'
                                  ? Border.all(color: const Color(0xFFEF4444), width: 1.2)
                                  : null,
                            ),
                            child: TextField(
                              controller: _destController,
                              focusNode: _destFocus,
                              onTap: () => setState(() => _activeField = 'destination'),
                              onChanged: (val) {
                                setState(() => _activeField = 'destination');
                                _onQueryChanged(val);
                              },
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: BeachColors.textMain),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: '¿A dónde vas en Carúpano?',
                                hintStyle: TextStyle(color: BeachColors.textMuted, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Botón de Intercambio (Swap ⇅)
                  IconButton(
                    icon: const Icon(Icons.swap_vert, color: BeachColors.oceanPrimary, size: 22),
                    tooltip: 'Invertir ruta',
                    onPressed: _swapLocations,
                  ),
                ],
              ),
            ),
          ),

          // Accesos rápidos: "Elegir en el mapa" y "Mi ubicación actual"
          Container(
            color: BeachColors.pureWhite,
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 14,
                    backgroundColor: BeachColors.oceanLight,
                    child: Icon(Icons.map_outlined, color: BeachColors.oceanPrimary, size: 16),
                  ),
                  title: Text(
                    'Elegir punto en el mapa ()',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: BeachColors.textMain),
                  ),
                  subtitle: const Text(
                    'Toca directamente la calle en el mapa de Carúpano',
                    style: TextStyle(fontSize: 10.5, color: BeachColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16, color: BeachColors.textMuted),
                  onTap: () {
                    Navigator.pop(
                      context,
                      AddressSelectionResult(
                        originText: _originController.text,
                        originPoint: _currentOriginPoint,
                        destinationText: _destController.text,
                        destinationPoint: _currentDestPoint,
                        chooseOnMap: true,
                        mapMode: _activeField,
                      ),
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.my_location, color: BeachColors.oceanPrimary, size: 16),
                  ),
                  title: const Text(
                    'Usar mi ubicación actual (GPS)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: BeachColors.textMain),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16, color: BeachColors.textMuted),
                  onTap: _useCurrentGpsLocation,
                ),
                const Divider(height: 1, color: BeachColors.lagoonBorder),
              ],
            ),
          ),

          // Indicador de Carga
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: BeachColors.oceanLight,
              color: BeachColors.oceanPrimary,
            ),

          // Lista de Resultados de Búsqueda o Lugares Frecuentes
          Expanded(
            child: hasQuery
                ? _buildSearchResultsList()
                : _buildPopularPlacesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _searchResults.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: BeachColors.lagoonBorder, indent: 52),
      itemBuilder: (ctx, i) {
        final item = _searchResults[i];
        return ListTile(
          dense: true,
          onTap: () => _onPlaceSelected(item),
          leading: CircleAvatar(
            radius: 15,
            backgroundColor: BeachColors.oceanLight,
            child: Icon(item.icon, color: BeachColors.oceanPrimary, size: 15),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: BeachColors.textMain),
          ),
          subtitle: Text(
            item.subtitle,
            style: const TextStyle(fontSize: 10.5, color: BeachColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.north_west, color: BeachColors.textMuted, size: 13),
        );
      },
    );
  }

  Widget _buildPopularPlacesList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text(
                'DESTINOS FRECUENTES EN CARÚPANO',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: BeachColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Toca para asignar a ${_activeField == 'origin' ? 'Recogida' : 'Destino'}',
                style: const TextStyle(fontSize: 9.5, color: BeachColors.oceanPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ...widget.popularPlaces.map((place) {
          return ListTile(
            dense: true,
            onTap: () {
              _onPlaceSelected(AddressSearchResult(
                title: place['title'] as String,
                subtitle: place['subtitle'] as String? ?? 'Carúpano, Sucre',
                point: place['point'] as LatLng,
                icon: (place['icon'] as IconData?) ?? Icons.place,
              ));
            },
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: BeachColors.oceanLight,
              child: Icon(
                place['icon'] as IconData? ?? Icons.place,
                color: BeachColors.oceanPrimary,
                size: 15,
              ),
            ),
            title: Text(
              place['title'] as String,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: BeachColors.textMain),
            ),
            subtitle: Text(
              place['subtitle'] as String? ?? 'Carúpano, Sucre',
              style: const TextStyle(fontSize: 10.5, color: BeachColors.textSecondary),
            ),
            trailing: const Icon(Icons.add_circle_outline, color: BeachColors.oceanPrimary, size: 16),
          );
        }),
      ],
    );
  }
}
