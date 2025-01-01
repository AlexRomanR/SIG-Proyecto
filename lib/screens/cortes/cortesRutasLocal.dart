import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:sig_proyecto/screens/cortes/mapaCortes.dart';

class ViewSavedRutasOrdered extends StatefulWidget {
  const ViewSavedRutasOrdered({Key? key}) : super(key: key);

  @override
  State<ViewSavedRutasOrdered> createState() => _ViewSavedRutasOrderedState();
}

class _ViewSavedRutasOrderedState extends State<ViewSavedRutasOrdered> {
  // Mismos datos de 'mapaCortes'
  final LatLng oficinaInicial = const LatLng(-16.3776, -60.9605);
  final LatLng oficinaFinal   = const LatLng(-16.3850, -60.9651);

  Set<String> cutPoints = {}; // IDs de puntos cortados
  Map<int, bool> pointsWithObservation = {}; // Map para observaciones

  @override
  void initState() {
    super.initState();
    _loadCutPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCutPoints();
  }

  Future<void> _loadCutPoints() async {
    final prefs = await SharedPreferences.getInstance();
    // IDs de puntos cortados
    cutPoints = prefs.getStringList('puntos_cortados')?.toSet() ?? {};
    // Cargar observaciones
    final registrosJson = prefs.getString('registros_corte') ?? '[]';
    final List<dynamic> registrosMap = jsonDecode(registrosJson);
    pointsWithObservation = {
      for (var registro in registrosMap)
        registro['codigoUbicacion']: registro['valorMedidor'] != null && registro['valorMedidor'].isNotEmpty
    };
    setState(() {}); // Refrescar la vista
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas (Orden espacial)', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<RutasSinCortar>>(
        future: _loadAndOrderRutas(),
        builder: (context, snapshot) {
          // Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent),
            );
          }
          // Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar rutas: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          // Datos vacíos
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay rutas guardadas',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Rutas con el mismo orden TSP que en mapaCortes
          final rutasOrdenadas = snapshot.data!;

          return ListView.builder(
            itemCount: rutasOrdenadas.length,
            itemBuilder: (context, index) {
              final ruta = rutasOrdenadas[index];
              final isCut = cutPoints.contains(ruta.bscocNcoc.toString());
              final hasObservation = pointsWithObservation[ruta.bscocNcoc] ?? false;
              Color cardColor;
              if (isCut) {
                cardColor = hasObservation ? Colors.green : Colors.orange ;
              } else {
                cardColor = Colors.red;
              }
              return Card(
                elevation: 4,
                color: const Color.fromARGB(255, 29, 29, 29),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: cardColor,
                    child: Text(
                      // Mostramos el índice +1 para simular "Punto 1", "Punto 2", etc.
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    ruta.dNomb.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    if (index == 0) {
                      _irAlMapa(index);
                    } else {
                      // Verificar si el punto anterior (index-1) está cortado
                      final idAnterior = rutasOrdenadas[index - 1].bscocNcoc.toString();
                      final anteriorCortado = cutPoints.contains(idAnterior);

                      if (anteriorCortado) {
                        // El punto anterior está cortado => Se permite
                        _irAlMapa(index);
                      } else {
                        // El punto anterior NO está cortado => Se bloquea
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No puedes acceder a este punto hasta que el anterior esté cortado.'),
                            backgroundColor: Color.fromARGB(255, 255, 129, 97),
                          ),
                        );
                      }
                    }
                  },
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '📍 Lat: ${ruta.bscntlati}, Lon: ${ruta.bscntlogi}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '💵 Importe Mora: ${ruta.bscocImor}',
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                      Text(
                        '🏠 Dirección: ${ruta.dLotes.trim()}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _irAlMapa(int index) {
    final numeroElegido = index + 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => mapaCortes(
          maxPoints: numeroElegido, 
          autoOpenIndex: numeroElegido - 1,
        ),
      ),
    ).then((_) {
      _loadCutPoints(); // Recarga los datos al regresar
    });
  }


  // Carga las rutas desde SharedPreferences y las ordena con el algoritmo TSP.
  Future<List<RutasSinCortar>> _loadAndOrderRutas() async {
    final rutas = await _loadSavedRutas();
    if (rutas.isEmpty) return [];

    // Simulando lo mismo que en mapaCortes: tomas sólo 10
    final rutasLimitadas = rutas.take(10).toList();

    // 1) Construimos la matriz de distancias
    final matrix = await buildDistanceMatrix(rutasLimitadas, oficinaInicial, oficinaFinal);
    // 2) Obtenemos el mejor camino con TSP
    final bestRoute = tsp(matrix);

    // 3) Reordenamos la lista según bestRoute
    //    Recuerda que bestRoute[0] = oficinaInicial y bestRoute[n-1] = oficinaFinal
    List<RutasSinCortar> orderedList = [];
    for (int i = 1; i < bestRoute.length - 1; i++) {
      final index = bestRoute[i] - 1; 
      orderedList.add(rutasLimitadas[index]);
    }

    // Guardar en SharedPreferences con la key "saved_rutas_tsp"
    final prefs = await SharedPreferences.getInstance();

    // Convertimos 'orderedList' a JSON
    final listaOrdenadaJson = jsonEncode(
      orderedList.map((r) => r.toJson()).toList(),
    );

    // Guardamos
    await prefs.setString('saved_rutas_tsp', listaOrdenadaJson);


    return orderedList;
  }
}

/// -------------- Funciones y métodos auxiliares (mismas que en mapaCortes) -------------- ///
Future<List<RutasSinCortar>> _loadSavedRutas() async {
  final prefs = await SharedPreferences.getInstance();

  // Lee el JSON principal
  final rutasJson = prefs.getString('saved_rutas');
  // Lee la lista de IDs seleccionados
  final selectedList = prefs.getStringList('rutas_seleccionadas') ?? [];

  // Convierte los IDs seleccionados a int y guárdalos en un Set para filtrar
  final selectedIDs = selectedList.map((id) => int.parse(id)).toSet();

  if (rutasJson != null) {
    try {
      final List<dynamic> rutasList = jsonDecode(rutasJson);

      // Mapea cada elemento JSON a tu modelo RutasSinCortar
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
      }).where((ruta) {
        // Filtra coordenadas inválidas
        return !(ruta.bscntlati == 0.0 && ruta.bscntlogi == 0.0);
      }).toList();

      // Si la lista de seleccionados NO está vacía,
      // filtramos las rutas cuyo bscocNcoc esté en selectedIDs.
      if (selectedIDs.isNotEmpty) {
        return rutas.where((r) => selectedIDs.contains(r.bscocNcoc)).toList();
      } else {
        // Si no hay selecciones, podríamos devolver todo.
        // O podrías devolver [] según tu necesidad.
        return rutas;
      }
    } catch (e) {
      print('Error al deserializar rutas: $e');
      return [];
    }
  }

  return [];
}

Future<double> getDirectionsDistance(LatLng origin, LatLng destination) async {
  final String apiKey = 'AIzaSyDF_Edk_GpqMZC87nE6MZExdlp-AecW4qo'; // Reemplaza con tu clave
  final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        // Distancia en metros -> kilómetros
        return data['routes'][0]['legs'][0]['distance']['value'] / 1000.0;
      }
    }
    return double.infinity;
  } catch (e) {
    print('Error al obtener distancia: $e');
    return double.infinity;
  }
}

/// Construye la matriz de distancias usando la Directions API, igual que en tu mapaCortes.
Future<List<List<double>>> buildDistanceMatrix(
    List<RutasSinCortar> rutas, 
    LatLng oficinaInicial,
    LatLng oficinaFinal
) async {
  final n = rutas.length + 2;
  final matrix = List.generate(n, (_) => List.filled(n, double.infinity));

  for (int i = 0; i < n; i++) {
    for (int j = i + 1; j < n; j++) {
      LatLng origin;
      LatLng destination;

      if (i == 0) {
        // start -> rutas
        origin = oficinaInicial;
        if (j == n - 1) {
          // Skip start -> end
          continue;
        }
        destination = LatLng(rutas[j - 1].bscntlati, rutas[j - 1].bscntlogi);
      } else if (j == n - 1) {
        // rutas -> end
        origin = LatLng(rutas[i - 1].bscntlati, rutas[i - 1].bscntlogi);
        destination = oficinaFinal;
      } else {
        // rutas intermedias
        origin = LatLng(rutas[i - 1].bscntlati, rutas[i - 1].bscntlogi);
        destination = LatLng(rutas[j - 1].bscntlati, rutas[j - 1].bscntlogi);
      }

      final distance = await getDirectionsDistance(origin, destination);
      matrix[i][j] = distance;
      matrix[j][i] = distance; 
    }
  }

  // Forzamos infinity entre start y end directos
  matrix[0][n - 1] = double.infinity;
  matrix[n - 1][0] = double.infinity;

  return matrix;
}

/// TSP: Igual que en tu código de mapaCortes
List<int> tsp(List<List<double>> matrix) {
  final n = matrix.length;
  List<int> route = List.generate(n, (index) => index);
  double minDistance = double.infinity;
  List<int> bestRoute = [];

  _permute(route, 1, n - 2, matrix, (candidateRoute) {
    double totalDistance = _calculateTotalDistance(candidateRoute, matrix);
    if (totalDistance < minDistance) {
      minDistance = totalDistance;
      bestRoute = List.from(candidateRoute);
    }
  });

  return bestRoute;
}

/// Permutamos rutas [1..n-2], manteniendo fijo 0 y n-1.
void _permute(List<int> route, int start, int end, List<List<double>> matrix,
    Function(List<int>) callback) {
  if (start == end) {
    callback(route);
    return;
  }
  for (int i = start; i <= end; i++) {
    _swap(route, start, i);
    _permute(route, start + 1, end, matrix, callback);
    _swap(route, start, i);
  }
}

void _swap(List<int> route, int i, int j) {
  final temp = route[i];
  route[i] = route[j];
  route[j] = temp;
}

double _calculateTotalDistance(List<int> route, List<List<double>> matrix) {
  double total = 0;
  for (int i = 0; i < route.length - 1; i++) {
    total += matrix[route[i]][route[i + 1]];
  }
  return total;
}
