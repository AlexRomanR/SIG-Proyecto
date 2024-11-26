import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/models/rutas_sin_cortar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gestion_asistencia_docente/screens/cortes/registroCorte.dart';



class mapaCortes extends StatelessWidget {
  const mapaCortes({super.key});

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

        return rutas;
      } catch (e) {
        return [];
      }
    }

    return [];
  }

  // Fórmula de Haversine para calcular la distancia entre dos puntos geográficos
  double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radio de la Tierra en km
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distancia en kilómetros
  }

  // Construir la matriz de distancias entre todos los puntos (incluyendo oficina inicial y final)
  List<List<double>> buildDistanceMatrix(List<RutasSinCortar> rutas, LatLng oficinaInicial, LatLng oficinaFinal) {
    final n = rutas.length + 2; // Incluye oficina inicial y final
    final matrix = List.generate(n, (_) => List.filled(n, double.infinity));

    // Distancias entre puntos intermedios
    for (int i = 0; i < rutas.length; i++) {
      for (int j = 0; j < rutas.length; j++) {
        if (i != j) {
          matrix[i + 1][j + 1] = haversineDistance(
            rutas[i].bscntlati,
            rutas[i].bscntlogi,
            rutas[j].bscntlati,
            rutas[j].bscntlogi,
          );
        }
      }
    }

    // Distancias de oficina inicial a los puntos intermedios
    for (int i = 0; i < rutas.length; i++) {
      matrix[0][i + 1] = haversineDistance(
        oficinaInicial.latitude,
        oficinaInicial.longitude,
        rutas[i].bscntlati,
        rutas[i].bscntlogi,
      );
      matrix[i + 1][0] = matrix[0][i + 1]; // Simetría
    }

    // Distancias de los puntos intermedios a oficina final
    for (int i = 0; i < rutas.length; i++) {
      matrix[i + 1][n - 1] = haversineDistance(
        rutas[i].bscntlati,
        rutas[i].bscntlogi,
        oficinaFinal.latitude,
        oficinaFinal.longitude,
      );
      matrix[n - 1][i + 1] = matrix[i + 1][n - 1]; // Simetría
    }

    return matrix;
  }

  // Algoritmo de optimización de ruta completa (TSP: Problema del Viajante de Comercio)
  List<int> tsp(List<List<double>> matrix) {
    final n = matrix.length;
    List<int> route = List.generate(n, (index) => index);
    double minDistance = double.infinity;
    List<int> bestRoute = [];

    // Permutar todos los posibles caminos y calcular la distancia total
    _permute(route, 1, n - 2, matrix, (candidateRoute) {
      double totalDistance = _calculateTotalDistance(candidateRoute, matrix);
      if (totalDistance < minDistance) {
        minDistance = totalDistance;
        bestRoute = List.from(candidateRoute);
      }
    });

    return bestRoute;
  }

  // Función para permutar las rutas y probar diferentes combinaciones
  void _permute(List<int> route, int start, int end, List<List<double>> matrix, Function(List<int>) callback) {
    if (start == end) {
      callback(route);
      return;
    }

    for (int i = start; i <= end; i++) {
      _swap(route, start, i);
      _permute(route, start + 1, end, matrix, callback);
      _swap(route, start, i); // Deshacer el cambio
    }
  }

  // Intercambiar dos elementos en la lista
  void _swap(List<int> route, int i, int j) {
    final temp = route[i];
    route[i] = route[j];
    route[j] = temp;
  }

  // Calcular la distancia total de una ruta
  double _calculateTotalDistance(List<int> route, List<List<double>> matrix) {
    double total = 0;
    for (int i = 0; i < route.length - 1; i++) {
      total += matrix[route[i]][route[i + 1]];
    }
    return total;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Mapa de Cortes', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      centerTitle: true,
    ),
    body: FutureBuilder<List<RutasSinCortar>>(
      future: _loadSavedRutas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent));
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar rutas guardadas', style: TextStyle(color: Colors.red)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay rutas guardadas', style: TextStyle(color: Colors.white)));
        }

        final rutas = snapshot.data!;
        final rutasLimitadas = rutas.take(5).toList(); // Limitar a 5 puntos intermedios

        // Coordenadas de la oficina inicial y final
        final oficinaInicial = LatLng(-16.3776, -60.9605);
        final oficinaFinal = LatLng(-16.3850, -60.9651);

        final distanceMatrix = buildDistanceMatrix(rutasLimitadas, oficinaInicial, oficinaFinal);
        final bestRoute = tsp(distanceMatrix); // Obtener la mejor ruta

        // Crear la ruta óptima (con oficinas inicial y final)
        List<LatLng> routeCoordinates = [];
        routeCoordinates.add(oficinaInicial); // Agregar oficina inicial

        for (int i = 1; i < bestRoute.length - 1; i++) {
          final point = rutasLimitadas[bestRoute[i] - 1];
          routeCoordinates.add(LatLng(point.bscntlati, point.bscntlogi));
        }

        routeCoordinates.add(oficinaFinal); // Agregar oficina final

        // Crear los marcadores
        Set<Marker> markers = {};
        markers.add(Marker(
          markerId: MarkerId('oficina_inicial'),
          position: oficinaInicial,
          infoWindow: InfoWindow(title: 'Oficina Inicial', snippet: 'Lat: -16.3776, Long: -60.9605'),
        ));

        markers.add(Marker(
          markerId: MarkerId('oficina_final'),
          position: oficinaFinal,
          infoWindow: InfoWindow(title: 'Oficina Final', snippet: 'Lat: -16.3850, Long: -60.9651'),
        ));

        // Agregar puntos intermedios
        for (int i = 0; i < rutasLimitadas.length; i++) {
          final point = rutasLimitadas[i];
          markers.add(Marker(
            markerId: MarkerId('punto_${i + 1}'),
            position: LatLng(point.bscntlati, point.bscntlogi),
            infoWindow: InfoWindow(title: 'Punto ${i + 1}'),
            onTap: () {
            // Navegar a la pantalla de RegistroCorte con los datos de la ruta
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => registroCorte(ruta: point),
              ),
              );
            },
          ));
        }

        // Lógica para calcular tiempo estimado y distancia
        double totalDistance = 0.0;
        for (int i = 0; i < routeCoordinates.length - 1; i++) {
          totalDistance += calculateDistance(routeCoordinates[i], routeCoordinates[i + 1]);
        }

        // Establecer valores fijos para el tiempo estimado y puntos cortados, puedes modificar estos valores si los calculas dinámicamente
        String estimatedTime = '1h 30m'; // Aquí se puede usar un cálculo dinámico si lo tienes
        String totalDistanceText = '${totalDistance.toStringAsFixed(2)} km';
        String totalPoints = rutasLimitadas.length.toString();
        String cutPoints = '0'; // Aquí también puedes actualizarlo si tienes los datos de puntos cortados

        return Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: oficinaInicial,
                  zoom: 13,
                ),
                markers: markers,
                polylines: {
                  Polyline(
                    polylineId: PolylineId('ruta_optima'),
                    points: routeCoordinates,
                    color: Colors.blue,
                    width: 5,
                  ),
                },
              ),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    'Tiempo Estimado: $estimatedTime',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Distancia Total: $totalDistanceText',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Total de Puntos: $totalPoints',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Puntos Cortados: $cutPoints',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

// Función para calcular la distancia entre dos puntos
double calculateDistance(LatLng start, LatLng end) {
  const double radius = 6371; // Radio de la Tierra en km
  double lat1 = start.latitude * (3.14159265359 / 180);
  double lon1 = start.longitude * (3.14159265359 / 180);
  double lat2 = end.latitude * (3.14159265359 / 180);
  double lon2 = end.longitude * (3.14159265359 / 180);

  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  double a = (sin(dLat / 2) * sin(dLat / 2)) +
      cos(lat1) * cos(lat2) * (sin(dLon / 2) * sin(dLon / 2));
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return radius * c; // Distancia en km
}

}


// class mapaCortes extends StatelessWidget {
//   const mapaCortes({super.key});
  

// Future<List<RutasSinCortar>> _loadSavedRutas() async {
//   final prefs = await SharedPreferences.getInstance();
//   final rutasJson = prefs.getString('saved_rutas');

//   if (rutasJson != null) {
//     try {
//       final List<dynamic> rutasList = jsonDecode(rutasJson);

//       // Convertir los datos de manera segura
//       final rutas = rutasList.map((ruta) {
//         return RutasSinCortar(
//           bscocNcoc: int.parse(ruta['bscocNcoc'].toString()), // Convertir a int
//           bscntCodf: int.parse(ruta['bscntCodf'].toString()), // Convertir a int
//           bscocNcnt: int.parse(ruta['bscocNcnt'].toString()), // Convertir a int
//           dNomb: ruta['dNomb'] ?? '', // Manejar nulos
//           bscocNmor: int.parse(ruta['bscocNmor'].toString()), // Convertir a int
//           bscocImor: double.parse(ruta['bscocImor'].toString()), // Convertir a double
//           bsmednser: ruta['bsmednser'] ?? '', // Manejar nulos
//           bsmedNume: ruta['bsmedNume'] ?? '', // Manejar nulos
//           bscntlati: double.parse(ruta['bscntlati'].toString()), // Convertir a double
//           bscntlogi: double.parse(ruta['bscntlogi'].toString()), // Convertir a double
//           dNcat: ruta['dNcat'] ?? '', // Manejar nulos
//           dCobc: ruta['dCobc'] ?? '', // Manejar nulos
//           dLotes: ruta['dLotes'] ?? '', // Manejar nulos
//         );
//       }).toList();

//       print('Datos cargados correctamente: $rutas');
//       return rutas;
//     } catch (e) {
//       print('Error al deserializar las rutas guardadas: $e');
//       return [];
//     }
//   }

//   print('No se encontraron rutas guardadas');
//   return [];
// }

//   // Fórmula de Haversine para calcular la distancia entre dos puntos geográficos
//   double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
//     const R = 6371; // Radio de la Tierra en km
//     final dLat = (lat2 - lat1) * (pi / 180);
//     final dLon = (lon2 - lon1) * (pi / 180);

//     final a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);

//     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return R * c; // Distancia en kilómetros
//   }

//   // Construir la matriz de distancias entre los puntos
//   List<List<double>> buildDistanceMatrix(List<RutasSinCortar> rutas) {
//     final n = rutas.length;
//     final matrix = List.generate(n, (_) => List.filled(n, double.infinity));

//     for (int i = 0; i < n; i++) {
//       for (int j = 0; j < n; j++) {
//         if (i != j) {
//           matrix[i][j] = haversineDistance(
//             rutas[i].bscntlati,
//             rutas[i].bscntlogi,
//             rutas[j].bscntlati,
//             rutas[j].bscntlogi,
//           );
//         }
//       }
//     }
//     return matrix;
//   }

//   // Algoritmo de Dijkstra para encontrar la ruta más corta entre un par de puntos
//   List<int> dijkstra(List<List<double>> graph, int start) {
//     final n = graph.length;
//     final distances = List.filled(n, double.infinity);
//     final visited = List.filled(n, false);
//     final previous = List.filled(n, -1);

//     distances[start] = 0;

//     for (int _ = 0; _ < n; _++) {
//       int u = -1;
//       for (int i = 0; i < n; i++) {
//         if (!visited[i] && (u == -1 || distances[i] < distances[u])) {
//           u = i;
//         }
//       }

//       if (distances[u] == double.infinity) break;

//       visited[u] = true;

//       for (int v = 0; v < n; v++) {
//         if (graph[u][v] != double.infinity && distances[u] + graph[u][v] < distances[v]) {
//           distances[v] = distances[u] + graph[u][v];
//           previous[v] = u;
//         }
//       }
//     }

//     return previous;
//   }

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Text(
//           'Mapa de Cortes',
//           style: TextStyle(color: Colors.white),
//        ),
//       backgroundColor: Colors.black,
//       centerTitle: true,
//     ),
//     body: FutureBuilder<List<RutasSinCortar>>(
//       future: _loadSavedRutas(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent));
//         } else if (snapshot.hasError) {
//           return const Center(
//             child: Text(
//               'Error al cargar rutas guardadas',
//               style: TextStyle(color: Colors.red),
//             ),
//           );
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(
//             child: Text(
//               'No hay rutas guardadas',
//               style: TextStyle(color: Colors.white),
//             ),
//           );
//         }

//         final rutas = snapshot.data!;

//         // Limitar a los primeros 5 puntos
//         final rutasLimitadas = rutas.take(5).toList();

//         final distanceMatrix = buildDistanceMatrix(rutasLimitadas);

//         // Calcular la ruta más corta entre los puntos seleccionados
//         List<LatLng> routeCoordinates = [];
        
//         // Añadir oficina inicial a la ruta
//         routeCoordinates.add(LatLng(-16.3776, -60.9605)); // Oficina Inicial
        
//         // Conectar los puntos entre sí
//         for (int i = 0; i < rutasLimitadas.length; i++) {
//           routeCoordinates.add(LatLng(rutasLimitadas[i].bscntlati, rutasLimitadas[i].bscntlogi));
//         }

//         // Añadir oficina final a la ruta
//         routeCoordinates.add(LatLng(-16.3850, -60.9651)); // Oficina Final

//         // Crear los marcadores para los puntos seleccionados
//         final Set<Marker> markers = rutasLimitadas.map((ruta) {
//           return Marker(
//             markerId: MarkerId(ruta.dNomb),
//             position: LatLng(ruta.bscntlati, ruta.bscntlogi),
//             infoWindow: InfoWindow(
//               title: ruta.dNomb,
//               snippet: 'Latitud: ${ruta.bscntlati}, Longitud: ${ruta.bscntlogi}',
//             ),
//             onTap: () {
//             // Navegar a la pantalla de RegistroCorte con los datos de la ruta
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => registroCorte(ruta: ruta),
//               ),
//               );
//             },
//           );
//         }).toSet();

//         // Crear los marcadores para la oficina inicial y final
//         LatLng oficinaInicial = LatLng(-16.3776, -60.9605); // Oficina Inicial
//         LatLng oficinaFinal = LatLng(-16.3850, -60.9651); // Oficina Final

//         markers.add(Marker(
//           markerId: MarkerId('oficina_inicial'),
//           position: oficinaInicial,
//           infoWindow: InfoWindow(
//             title: 'Oficina Inicial',
//             snippet: 'Lat: -16.37768, Long: -60.9605',
//           ),
//         ));

//         markers.add(Marker(
//           markerId: MarkerId('oficina_final'),
//           position: oficinaFinal,
//           infoWindow: InfoWindow(
//             title: 'Oficina Final',
//             snippet: 'Lat: -16.3850, Long: -60.9651',
//           ),
//         ));

//         // Mostrar el mapa con la ruta completa (PolyLine) entre los puntos
//         return Column(
//           children: [
//             Expanded(
//               child: GoogleMap(
//                 initialCameraPosition: CameraPosition(
//                   target: LatLng(rutasLimitadas.first.bscntlati, rutasLimitadas.first.bscntlogi), // Posición inicial
//                   zoom: 13.0,
//                 ),
//                 markers: markers,
//                 polylines: {
//                   Polyline(
//                     polylineId: PolylineId('ruta_completa'),
//                     points: routeCoordinates,
//                     color: Colors.blue,
//                     width: 5,
//                   ),
//                 },
//               ),
//             ),
//             Container(
//               color: Colors.black,
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: [
//                   Text(
//                     'Tiempo Estimado: 1h 30m',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                   Text(
//                     'Distancia Total: 15 km',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                   Text(
//                     'Total de Puntos: 5',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                   Text(
//                     'Puntos Cortados: 0',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     ),
//   );
// }

// }

//-----------------------------------------------------------------------------------------

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:gestion_asistencia_docente/models/rutas_sin_cortar.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class mapaCortes extends StatelessWidget {
//   const mapaCortes({super.key});

//   final String googleMapsApiKey = "AIzaSyD3lieHZEb-3gArERwjSGqjBGXLxT3ZtcA"; // Reemplaza con tu clave de API

//   // Cargar las rutas guardadas desde SharedPreferences
//   Future<List<RutasSinCortar>> _loadSavedRutas() async {
//     final prefs = await SharedPreferences.getInstance();
//     final rutasJson = prefs.getString('saved_rutas');
//     if (rutasJson != null) {
//       try {
//         final List<dynamic> rutasList = jsonDecode(rutasJson);
//         return rutasList.map((ruta) {
//           return RutasSinCortar(
//             bscocNcoc: int.parse(ruta['bscocNcoc'].toString()),
//             bscntCodf: int.parse(ruta['bscntCodf'].toString()),
//             bscocNcnt: int.parse(ruta['bscocNcnt'].toString()),
//             dNomb: ruta['dNomb'] ?? '',
//             bscocNmor: int.parse(ruta['bscocNmor'].toString()),
//             bscocImor: double.parse(ruta['bscocImor'].toString()),
//             bsmednser: ruta['bsmednser'] ?? '',
//             bsmedNume: ruta['bsmedNume'] ?? '',
//             bscntlati: double.parse(ruta['bscntlati'].toString()),
//             bscntlogi: double.parse(ruta['bscntlogi'].toString()),
//             dNcat: ruta['dNcat'] ?? '',
//             dCobc: ruta['dCobc'] ?? '',
//             dLotes: ruta['dLotes'] ?? '',
//           );
//         }).toList();
//       } catch (e) {
//         print('Error al deserializar las rutas guardadas: $e');
//         return [];
//       }
//     }
//     return [];
//   }

//   // Función para obtener direcciones usando la API de Google Directions
//   Future<double> _getDistance(LatLng origin, LatLng destination) async {
//     try {
//       final url = Uri.parse(
//           'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleMapsApiKey');

//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         // Verificar si la respuesta contiene rutas
//         if (data['status'] == 'OK') {
//           final distance = data['routes'][0]['legs'][0]['distance']['value']; // en metros
//           return distance / 1000; // Convertir de metros a kilómetros
//         } else {
//           // Manejar el caso cuando no hay rutas disponibles
//           print('Error en la API de Google Directions: ${data['status']}');
//           throw Exception('No se encontraron rutas');
//         }
//       } else {
//         // Si la respuesta no es 200 OK
//         print('Error en la respuesta de la API: ${response.statusCode}');
//         throw Exception('Error en la solicitud a la API');
//       }
//     } catch (e) {
//       print('Error al obtener distancia: $e');
//       throw Exception('Error al obtener distancia');
//     }
//   }

//   // Algoritmo de Dijkstra para encontrar la ruta más corta entre un par de puntos
//   List<int> dijkstra(List<List<double>> graph, int start) {
//     final n = graph.length;
//     final distances = List.filled(n, double.infinity);
//     final visited = List.filled(n, false);
//     final previous = List.filled(n, -1);

//     distances[start] = 0;

//     for (int _ = 0; _ < n; _++) {
//       int u = -1;
//       for (int i = 0; i < n; i++) {
//         if (!visited[i] && (u == -1 || distances[i] < distances[u])) {
//           u = i;
//         }
//       }

//       if (distances[u] == double.infinity) break;

//       visited[u] = true;

//       for (int v = 0; v < n; v++) {
//         if (graph[u][v] != double.infinity && distances[u] + graph[u][v] < distances[v]) {
//           distances[v] = distances[u] + graph[u][v];
//           previous[v] = u;
//         }
//       }
//     }

//     return previous;
//   }

//   // Optimizar el recorrido de los puntos (con oficina inicial y final) usando Dijkstra
//   Future<List<LatLng>> _getOptimizedRoute(LatLng oficinaInicial, List<LatLng> puntos) async {
//     final n = puntos.length + 2;
//     List<LatLng> allPoints = [oficinaInicial] + puntos + [LatLng(-16.3850, -60.9651)]; // Oficina Final
//     List<List<double>> distanceMatrix = List.generate(n, (_) => List.filled(n, double.infinity));

//     // Obtener las distancias entre todos los puntos
//     for (int i = 0; i < n; i++) {
//       for (int j = i + 1; j < n; j++) {
//         try {
//           final distance = await _getDistance(allPoints[i], allPoints[j]);
//           distanceMatrix[i][j] = distance;
//           distanceMatrix[j][i] = distance;
//         } catch (e) {
//           print('Error calculando distancia entre ${allPoints[i]} y ${allPoints[j]}: $e');
//           // Establecer distancias a infinito en caso de error
//           distanceMatrix[i][j] = double.infinity;
//           distanceMatrix[j][i] = double.infinity;
//         }
//       }
//     }

//     // Aplicar el algoritmo de Dijkstra para encontrar el camino más corto
//     List<int> previous = dijkstra(distanceMatrix, 0); // Start at oficinaInicial

//     // Reconstruir la ruta óptima
//     List<LatLng> optimizedRoute = [];
//     int current = n - 1; // Start from the last point (office final)
//     while (current != -1) {
//       optimizedRoute.add(allPoints[current]);
//       current = previous[current];
//     }

//     optimizedRoute = optimizedRoute.reversed.toList();
//     return optimizedRoute;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mapa de Cortes'),
//         backgroundColor: Colors.black,
//       ),
//       body: FutureBuilder<List<RutasSinCortar>>(
//         future: _loadSavedRutas(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent));
//           } else if (snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 'Error al cargar rutas guardadas',
//                 style: TextStyle(color: Colors.red),
//               ),
//             );
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(
//               child: Text(
//                 'No hay rutas guardadas',
//                 style: TextStyle(color: Colors.white),
//               ),
//             );
//           }

//           final rutas = snapshot.data!;

//           // Limitar a los primeros 5 puntos
//           final rutasLimitadas = rutas.take(5).toList();

//           // Obtener las coordenadas de los puntos
//           List<LatLng> routeCoordinates = [];

//           // Añadir oficina inicial a la ruta
//           LatLng oficinaInicial = LatLng(-16.3776, -60.9605); // Oficina Inicial

//           // Añadir los puntos de rutas
//           for (var ruta in rutasLimitadas) {
//             routeCoordinates.add(LatLng(ruta.bscntlati, ruta.bscntlogi));
//           }

//           // Obtener la ruta optimizada
//           return FutureBuilder<List<LatLng>>(
//             future: _getOptimizedRoute(oficinaInicial, routeCoordinates),
//             builder: (context, routeSnapshot) {
//               if (routeSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               } else if (routeSnapshot.hasError) {
//                 return Center(child: Text('Error al obtener la ruta: ${routeSnapshot.error}'));
//               } else if (!routeSnapshot.hasData || routeSnapshot.data!.isEmpty) {
//                 return const Center(child: Text('No se pudo calcular la ruta.'));
//               }

//               final optimizedRoute = routeSnapshot.data!;

//               // Crear los marcadores para los puntos seleccionados
//               final Set<Marker> markers = rutasLimitadas.map((ruta) {
//                 return Marker(
//                   markerId: MarkerId(ruta.dNomb),
//                   position: LatLng(ruta.bscntlati, ruta.bscntlogi),
//                   infoWindow: InfoWindow(
//                     title: ruta.dNomb,
//                     snippet: 'Lat: ${ruta.bscntlati}, Long: ${ruta.bscntlogi}',
//                   ),
//                 );
//               }).toSet();

//               markers.add(Marker(
//                 markerId: MarkerId('oficina_inicial'),
//                 position: oficinaInicial,
//                 infoWindow: InfoWindow(title: 'Oficina Inicial'),
//               ));

//               markers.add(Marker(
//                 markerId: MarkerId('oficina_final'),
//                 position: LatLng(-16.3850, -60.9651), // Oficina Final
//                 infoWindow: InfoWindow(title: 'Oficina Final'),
//               ));

//               return GoogleMap(
//                 initialCameraPosition: CameraPosition(
//                   target: optimizedRoute.first,
//                   zoom: 13.0,
//                 ),
//                 markers: markers,
//                 polylines: {
//                   Polyline(
//                     polylineId: PolylineId('ruta_completa'),
//                     points: optimizedRoute,
//                     color: Colors.blue,
//                     width: 5,
//                   ),
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



