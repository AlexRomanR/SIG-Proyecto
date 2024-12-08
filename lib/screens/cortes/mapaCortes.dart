import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sig_proyecto/screens/cortes/registroCorte.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:sig_proyecto/models/registro_corte.dart';

class mapaCortes extends StatefulWidget {

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

  // Function to get distance from Directions API
  Future<double> getDirectionsDistance(LatLng origin, LatLng destination) async {
    final String apiKey = 'AIzaSyDPnYs5bEjFjnBD1WsUtuZ6NtQkOAGF1I0';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          // Distance comes in meters, convert to kilometers
          
          return data['routes'][0]['legs'][0]['distance']['value'] / 1000.0;
        }
      }
      return double.infinity;
    } catch (e) {
      return double.infinity;
    }
  }

  // Modified matrix building function
  Future<List<List<double>>> buildDistanceMatrix(
      List<RutasSinCortar> rutas, LatLng oficinaInicial, LatLng oficinaFinal) async {
    final n = rutas.length + 2;
    final matrix = List.generate(n, (_) => List.filled(n, double.infinity));

    // Get all distances using Directions API
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        LatLng origin;
        LatLng destination;

        // Handle start point (oficinaInicial)
        if (i == 0) {
          origin = oficinaInicial;
          if (j == n - 1) {
            // Skip direct path from start to end
            continue;
          }
          destination = LatLng(rutas[j - 1].bscntlati, rutas[j - 1].bscntlogi);
        }
        // Handle end point (oficinaFinal)
        else if (j == n - 1) {
          destination = oficinaFinal;
          origin = LatLng(rutas[i - 1].bscntlati, rutas[i - 1].bscntlogi);
        }
        // Handle intermediate points
        else {
          origin = LatLng(rutas[i - 1].bscntlati, rutas[i - 1].bscntlogi);
          destination = LatLng(rutas[j - 1].bscntlati, rutas[j - 1].bscntlogi);
        }

        final distance = await getDirectionsDistance(origin, destination);
        matrix[i][j] = distance;
        matrix[j][i] = distance; // Matrix is symmetric
      }
    }

    // Force infinity for direct start-to-end path
    matrix[0][n - 1] = double.infinity;
    matrix[n - 1][0] = double.infinity;

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
  final String apiKey = 'AIzaSyDPnYs5bEjFjnBD1WsUtuZ6NtQkOAGF1I0';
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  String estimatedTime = '';
  String totalDistanceText = '';
  String totalPoints = '';
  String cutPoints = '0';
  LatLng oficinaInicial = LatLng(-16.3776, -60.9605);
  List<RegistroCorte> registros = [];

  @override
  void initState() {
    super.initState();
    _loadDataAndBuildRoute();
    _cargarRegistros();
    print(registros);
  }

  Future<void> _loadDataAndBuildRoute() async {
    final rutas = await _loadSavedRutas();
    final cutPoints = await _loadCutPoints();
    if (rutas.isEmpty) {
      return;
    }

    final rutasLimitadas = rutas.take(10).toList();
    final oficinaInicial = LatLng(-16.3776, -60.9605);
    final oficinaFinal = LatLng(-16.3850, -60.9651);

    final distanceMatrix = await buildDistanceMatrix(rutasLimitadas, oficinaInicial, oficinaFinal);
    final bestRoute = tsp(distanceMatrix);

    List<LatLng> routeCoordinates = [];
    routeCoordinates.add(oficinaInicial);

    for (int i = 1; i < bestRoute.length - 1; i++) {
      final point = rutasLimitadas[bestRoute[i] - 1];
      routeCoordinates.add(LatLng(point.bscntlati, point.bscntlogi));
    }

    routeCoordinates.add(oficinaFinal);

    List<RutasSinCortar> pointsMap = [];
    for (int i = 1; i < bestRoute.length - 1; i++) {
      final point = rutasLimitadas[bestRoute[i] - 1];
      pointsMap.add(point);
    }

    Set<Marker> markersTemp = {};
    
    // Cargar imágenes para marcadores
    BitmapDescriptor startIcon = await createBitmapDescriptor('assets/utils/start.png');
    BitmapDescriptor endIcon = await createBitmapDescriptor('assets/utils/end.png');

    markersTemp.add(Marker(
      markerId: MarkerId('oficina_inicial'),
      position: oficinaInicial,
      infoWindow: InfoWindow(title: 'Oficina Inicial'),
      icon: startIcon,
    ));

    markersTemp.add(Marker(
      markerId: MarkerId('oficina_final'),
      position: oficinaFinal,
      infoWindow: InfoWindow(title: 'Oficina Final'),
      icon: endIcon,
    ));

    for (int i = 0; i < pointsMap.length; i++) {
      final point = pointsMap[i];
     
      bool isCut = registros.any((registro) => registro.codigoUbicacion == point.bscocNcoc);
      bool hasValue = false;
      
      if (isCut) {
        // Get the specific registro for this point
        final registro = registros.firstWhere(
          (registro) => registro.codigoUbicacion == point.bscocNcoc,
          orElse: () => RegistroCorte(
            codigoUbicacion: 0,
            usuarioRelacionado: 0,
            codigoFijo: 0,
            nombre: '',
            medidorSerie: '',
            numeroMedidor: '',
            fechaCorte: DateTime.now(),
          ),
        );
        
        // Check if it has valorMedidor (not null and not empty)
        hasValue = registro.valorMedidor != null && registro.valorMedidor!.isNotEmpty;
        print('Point ${point.bscocNcoc} - hasValue: $hasValue - valorMedidor: ${registro.valorMedidor}');
      }
  
      markersTemp.add(Marker(
        markerId: MarkerId('punto_${i + 1}'),
        position: LatLng(point.bscntlati, point.bscntlogi),
        infoWindow: InfoWindow(title: 'Punto ${i + 1}'),
        icon: await createCustomMarkerWithNumber(i + 1, isCut, hasValue),
        onTap: isCut ? null : () {
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
    final waypointsString = 'optimize:false|' + waypoints.join('|');

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

  Future<void> _cargarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    final registrosJson = prefs.getString('registros_corte') ?? '[]';
    final List<dynamic> registrosMap = jsonDecode(registrosJson);

    setState(() {
      registros =
          registrosMap.map((map) => RegistroCorte.fromMap(map)).toList();
    });
  }



  Future<BitmapDescriptor> createBitmapDescriptor(String assetPath) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    final Uint8List uint8List = byteData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(uint8List, targetWidth: 100, targetHeight: 100);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedByteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedUint8List = resizedByteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resizedUint8List);
  }

  Future<BitmapDescriptor> createCustomMarkerWithNumber(int number, bool isCut, bool hasValue) async {
    // Create a TextPainter to draw the number
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          fontSize: 40,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Create a picture recorder and canvas
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Draw the circle background
    final Paint circlePaint = Paint()..color = isCut 
        ? (hasValue ? Colors.green : Colors.orange)  // If cut, check if has value
        : Colors.red;                                // If not cut, red
    canvas.drawCircle(
      Offset(30, 30),  // Center of the circle
      30,              // Radius of the circle
      circlePaint,
    );

    // Draw the number in the center of the circle
    textPainter.paint(
      canvas,
      Offset(
        30 - textPainter.width / 2,
        30 - textPainter.height / 2,
      ),
    );

    // Convert to image
    final ui.Image image = await pictureRecorder.endRecording().toImage(60, 60);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
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
                      zoom: 20,
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
