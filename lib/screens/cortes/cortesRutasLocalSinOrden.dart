import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // para LatLng
import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sig_proyecto/screens/cortes/cortesRutasLocal.dart';
class ViewSavedRutasSinOrden extends StatefulWidget {
  const ViewSavedRutasSinOrden({Key? key}) : super(key: key);

  @override
  State<ViewSavedRutasSinOrden> createState() => _ViewSavedRutasSinOrdenState();
}

class _ViewSavedRutasSinOrdenState extends State<ViewSavedRutasSinOrden> {
  final LatLng oficinaInicial = const LatLng(-16.3776, -60.9605);
  Set<int> selectedNcocs = {};

  // Lista local donde guardaremos las rutas cargadas
  List<RutasSinCortar> _rutas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedRutasOnce();
  }

  Future<void> _loadSavedRutasOnce() async {
    try {
      final routes = await _loadSavedRutas(); // la misma función que ya tienes
      setState(() {
        _rutas = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar rutas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Guardadas (sin orden)', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.done, color: Colors.white),
            onPressed: _saveSelectedRoutes,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.lightBlueAccent),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_rutas.isEmpty) {
      return const Center(
        child: Text('No hay rutas guardadas', style: TextStyle(color: Colors.white)),
      );
    }

    // Si ya tenemos la lista en _rutas, la usamos para construir el ListView
    return ListView.builder(
      itemCount: _rutas.length,
      itemBuilder: (context, index) {
        final ruta = _rutas[index];
        final ncocId = ruta.bscocNcoc;

        final dist = _calculateDistance(
          oficinaInicial.latitude,
          oficinaInicial.longitude,
          ruta.bscntlati,
          ruta.bscntlogi,
        );

        final isSelected = selectedNcocs.contains(ncocId);

        return Card(
          elevation: 4,
          color: const Color.fromARGB(255, 29, 29, 29),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Checkbox(
              activeColor: Colors.lightBlueAccent,
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedNcocs.add(ncocId);
                  } else {
                    selectedNcocs.remove(ncocId);
                  }
                });
              },
            ),
            title: Text(
              ruta.dNomb.trim(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '📍 Lat: ${ruta.bscntlati}, Lon: ${ruta.bscntlogi}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '💵 Importe Mora: ${ruta.bscocImor}',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
                Text(
                  'Distancia: ${dist.toStringAsFixed(2)} km',
                  style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSelectedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedList = selectedNcocs.map((id) => id.toString()).toList();
    await prefs.setStringList('rutas_seleccionadas', selectedList);

    // Rediriges a la siguiente pantalla
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewSavedRutasOrdered()),
    );
  }

  // Tu misma función de cargar JSON
  Future<List<RutasSinCortar>> _loadSavedRutas() async {
    final prefs = await SharedPreferences.getInstance();
    final rutasJson = prefs.getString('saved_rutas');

    if (rutasJson != null) {
      try {
        final List<dynamic> rutasList = jsonDecode(rutasJson);
        final rutas = rutasList.map((ruta) {
          return RutasSinCortar(
            bscocNcoc: int.parse(ruta['bscocNcoc'].toString()),
            bscntCodf: int.parse(ruta['bscntCodf'].toString()),
            bscocNcnt: int.parse(ruta['bscocNcnt'].toString()),
            dNomb: ruta['dNomb'] ?? '',
            bscocNmor: int.parse(ruta['bscocNmor'].toString()),
            bscocImor: double.parse(ruta['bscocImor'].toString()),
            bsmednser: ruta['bsmednser'] ?? '',
            bsmedNume: ruta['bsmedNume'] ?? '',
            bscntlati: double.parse(ruta['bscntlati'].toString()),
            bscntlogi: double.parse(ruta['bscntlogi'].toString()),
            dNcat: ruta['dNcat'] ?? '',
            dCobc: ruta['dCobc'] ?? '',
            dLotes: ruta['dLotes'] ?? '',
          );
        }).toList();

        final rutasFiltradas = rutas.where((r) {
          return !(r.bscntlati == 0.0 && r.bscntlogi == 0.0);
        }).toList();

        return rutasFiltradas;
      } catch (e) {
        print('Error al deserializar las rutas guardadas: $e');
        return [];
      }
    }
    print('No se encontraron rutas guardadas');
    return [];
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radio de la Tierra en km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;
}
