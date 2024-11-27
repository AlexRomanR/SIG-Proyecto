import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sig_proyecto/screens/cortes/registroCorte.dart';

class mapaCortes extends StatelessWidget {

  const mapaCortes({super.key});


  @override
  _MapaCortesState createState() => _MapaCortesState();
}
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
        }).where((ruta) {
          return !(ruta.bscntlati == 0.0 && ruta.bscntlogi == 0.0);
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
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distancia en kilómetros
  }

  // Construir la matriz de distancias entre todos los puntos (incluyendo oficina inicial y final)
  List<List<double>> buildDistanceMatrix(
      List<RutasSinCortar> rutas, LatLng oficinaInicial, LatLng oficinaFinal) {
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
  void _permute(List<int> route, int start, int end, List<List<double>> matrix,
      Function(List<int>) callback) {
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

class _MapaCortesState extends State<mapaCortes> {
  String apiKey = 'AIzaSyDPnYs5bEjFjnBD1WsUtuZ6NtQkOAGF1I0'; // Reemplaza con tu clave de API
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  String estimatedTime = '';
  String totalDistanceText = '';
  String totalPoints = '';
  String cutPoints = '0';
  LatLng oficinaInicial = LatLng(-16.3776, -60.9605);

  @override
  void initState() {
    super.initState();
    _loadDataAndBuildRoute();
  }

  Future<void> _loadDataAndBuildRoute() async {
    final rutas = await _loadSavedRutas();
    final cutPoints = await _loadCutPoints(); // Cargar puntos cortados
    if (rutas.isEmpty) {
      return;
    }

    final rutasLimitadas = rutas.take(10).toList();

    final oficinaInicial = LatLng(-16.3776, -60.9605);
    final oficinaFinal = LatLng(-16.3850, -60.9651);

    final distanceMatrix = buildDistanceMatrix(rutasLimitadas, oficinaInicial, oficinaFinal);
    final bestRoute = tsp(distanceMatrix);

    List<LatLng> routeCoordinates = [];
    routeCoordinates.add(oficinaInicial);

    for (int i = 1; i < bestRoute.length - 1; i++) {
      final point = rutasLimitadas[bestRoute[i] - 1];
      routeCoordinates.add(LatLng(point.bscntlati, point.bscntlogi));
    }

    routeCoordinates.add(oficinaFinal);

    Set<Marker> markersTemp = {};
    markersTemp.add(Marker(
      markerId: MarkerId('oficina_inicial'),
      position: oficinaInicial,
      infoWindow: InfoWindow(title: 'Oficina Inicial'),
    ));

    markersTemp.add(Marker(
      markerId: MarkerId('oficina_final'),
      position: oficinaFinal,
      infoWindow: InfoWindow(title: 'Oficina Final'),
    ));

    for (int i = 0; i < rutasLimitadas.length; i++) {
      final point = rutasLimitadas[i];
      bool isCut = cutPoints.contains(point.bscocNcoc.toString());
  
      markersTemp.add(Marker(
        markerId: MarkerId('punto_${i + 1}'),
        position: LatLng(point.bscntlati, point.bscntlogi),
        infoWindow: InfoWindow(title: 'Punto ${i + 1}'),
        icon: isCut
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: isCut
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => registroCorte(ruta: point),
                  ),

                ).then((_) {
                  _loadDataAndBuildRoute();
                });
              },
      ));
    }

    List<String> waypoints = [];
    for (int i = 1; i < routeCoordinates.length - 1; i++) {
      waypoints.add('${routeCoordinates[i].latitude},${routeCoordinates[i].longitude}');
    }
    
    // Agregar 'optimize:true' para que Google optimice el orden de los waypoints
    final waypointsString = 'optimize:true|' + waypoints.join('|');

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${routeCoordinates.first.latitude},${routeCoordinates.first.longitude}&destination=${routeCoordinates.last.latitude},${routeCoordinates.last.longitude}&waypoints=$waypointsString&key=$apiKey');

try {
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'OK') {
      final route = data['routes'][0];

      // Obtener el nuevo orden de los waypoints
      List<dynamic> waypointOrder = route['waypoint_order'];

      // Reorganizar los puntos y marcadores según el nuevo orden
      List<LatLng> optimizedRouteCoordinates = [routeCoordinates.first];
      for (int index in waypointOrder) {
        optimizedRouteCoordinates.add(routeCoordinates[index + 1]);
      }
      optimizedRouteCoordinates.add(routeCoordinates.last);

      // Decodificar la polilínea
      String encodedPolyline = route['overview_polyline']['points'];
      List<LatLng> polylinePoints = decodePolyline(encodedPolyline);

      // Calcular distancia total y tiempo estimado
      double totalDistance = 0.0;
      double totalDuration = 0.0;
      for (var leg in route['legs']) {
        totalDistance += leg['distance']['value'];
        totalDuration += leg['duration']['value'];
      }
      String totalDistanceText = (totalDistance / 1000).toStringAsFixed(2) + ' km';
      int hours = totalDuration ~/ 3600;
      int minutes = (totalDuration % 3600) ~/ 60;
      String estimatedTime = '${hours}h ${minutes}m';

      // Actualizar la interfaz de usuario
      setState(() {
        markers = markersTemp;
        polylines.add(Polyline(
          polylineId: PolylineId('ruta_optima'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        ));
        this.estimatedTime = estimatedTime;
        this.totalDistanceText = totalDistanceText;
        this.totalPoints = rutasLimitadas.length.toString();
        this.cutPoints = cutPoints.length.toString(); 
      });
    } else {
      print("No se encontraron direcciones");
    }
  } else {
    print("Error al obtener direcciones");
  }
} catch (e) {
  print("Error: $e");
}
  }

  // Aquí irían tus funciones _loadSavedRutas, buildDistanceMatrix, tsp, etc.

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }


  Future<Set<String>> _loadCutPoints() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cutPoints = prefs.getStringList('puntos_cortados') ?? [];
    return cutPoints.toSet();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Cortes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: markers.isEmpty
          ? Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: oficinaInicial,
                      zoom: 13,
                    ),
                    markers: markers,
                    polylines: polylines,
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
            ),
    );
  }
}
