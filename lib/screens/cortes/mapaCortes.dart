import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:sig_proyecto/models/registro_corte.dart';
// import 'package:sig_proyecto/screens/login/home_screen.dart'; 
// ^ Puedes importar si necesitas esa pantalla para tu botón de "Menú Principal"

class mapaCortes extends StatefulWidget {
  final int? maxPoints; 
  final int? autoOpenIndex; 
  const mapaCortes({Key? key, this.maxPoints, this.autoOpenIndex}) : super(key: key);

  @override
  _MapaCortesState createState() => _MapaCortesState();
}

class _MapaCortesState extends State<mapaCortes> {
  // --------------------------------
  // Atributos del mapa
  // --------------------------------
  final String apiKey = 'AIzaSyDF_Edk_GpqMZC87nE6MZExdlp-AecW4qo';
  LatLng oficinaInicial = LatLng(-16.3776, -60.9605);

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<RutasSinCortar> pointsMap = []; // Puntos en ruta
  List<RegistroCorte> registros = [];
  BitmapDescriptor? startIcon;
  BitmapDescriptor? endIcon;
  List<LatLng> polylinePoints = [];

  String estimatedTime = '';
  String totalDistanceText = '';
  String totalPoints = '';
  String cutPoints = '0';

  // --------------------------------
  // Atributos para mostrar/ocultar el form
  // --------------------------------
  bool showHalfForm = false;
  RutasSinCortar? selectedRuta; // El punto (ruta) seleccionado

  // --------------------------------
  // Atributos del formulario
  // --------------------------------
  final TextEditingController _textController = TextEditingController();
  String _selectedOption = 'Ninguna';
  String? _fotoBase64;
  File? _fotoFile;

  @override
  void initState() {
    super.initState();
    _loadDataAndBuildRoute();
    _cargarRegistros();
  }

  Future<List<RutasSinCortar>> _loadOrderedRutas() async {
    final prefs = await SharedPreferences.getInstance();
    final rutasTspJson = prefs.getString('saved_rutas_tsp');
    if (rutasTspJson == null) return [];

    try {
      final List<dynamic> list = jsonDecode(rutasTspJson);
      final rutas = list.map((item) {
        return RutasSinCortar(
          bscocNcoc: item['bscocNcoc'] as int,
          bscntCodf: item['bscntCodf'] as int,
          bscocNcnt: item['bscocNcnt'] as int,
          dNomb:     item['dNomb'] ?? '',
          bscocNmor: item['bscocNmor'] as int,
          bscocImor: item['bscocImor'] as double,
          bsmednser: item['bsmednser'] ?? '',
          bsmedNume: item['bsmedNume'] ?? '',
          bscntlati: item['bscntlati'] as double,
          bscntlogi: item['bscntlogi'] as double,
          dNcat:     item['dNcat'] ?? '',
          dCobc:     item['dCobc'] ?? '',
          dLotes:    item['dLotes'] ?? '',
        );
      }).where((ruta) {
        return !(ruta.bscntlati == 0.0 && ruta.bscntlogi == 0.0);
      }).toList();

      return rutas;
    } catch (e) {
      print('Error deserializando TSP: $e');
      return [];
    }
  }
  // CARGA DE DATOS Y MARCADORES
  Future<void> _loadDataAndBuildRoute() async {
    final maxPoints = widget.maxPoints ?? 0;
    // 1) Cargar rutas (puedes usar _loadOrderedRutas si lo deseas)
    List<RutasSinCortar> rutas = await _loadSavedRutas();
    if (maxPoints > 0) {
      rutas = await _loadOrderedRutas();
      print('ordenado xd');
    } else {
      rutas = await _loadSavedRutas();
    }

    if (rutas.isEmpty) return;

    // 2) Actualizar la cantidad de puntos ya cortados
    final cutPoints = await _loadCutPoints();
    setState(() {
      this.cutPoints = cutPoints.length.toString();
    });

    // 3) Tomar un subset
    List<RutasSinCortar> rutasLimitadas;
    if (maxPoints > 0 && maxPoints <= rutas.length) {
      rutasLimitadas = rutas.take(maxPoints).toList();
    } else {
      rutasLimitadas = rutas.take(10).toList(); // Ejemplo, limit 10
    }

    // 4) Calcular TSP
    final oficinaFinal = LatLng(-16.3850, -60.9651);
    final distanceMatrix =
        await buildDistanceMatrix(rutasLimitadas, oficinaInicial, oficinaFinal);
    final bestRoute = tsp(distanceMatrix);

    // 5) Construir la ruta de puntos
    List<LatLng> routeCoordinates = [];
    routeCoordinates.add(oficinaInicial);
    List<RutasSinCortar> tempPointsMap = [];
    for (int i = 1; i < bestRoute.length - 1; i++) {
      final point = rutasLimitadas[bestRoute[i] - 1];
      routeCoordinates.add(LatLng(point.bscntlati, point.bscntlogi));
      tempPointsMap.add(point);
    }
    routeCoordinates.add(oficinaFinal);

    // 6) Cargar íconos
    BitmapDescriptor sIcon = await createBitmapDescriptor('assets/utils/start.png');
    BitmapDescriptor eIcon = await createBitmapDescriptor('assets/utils/end.png');

    // 7) Pedir la polyline a Google Directions
    List<String> waypoints = [];
    for (int i = 1; i < routeCoordinates.length - 1; i++) {
      waypoints.add('${routeCoordinates[i].latitude},${routeCoordinates[i].longitude}');
    }
    final waypointsString = 'optimize:false|' + waypoints.join('|');

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${routeCoordinates.first.latitude},${routeCoordinates.first.longitude}'
        '&destination=${routeCoordinates.last.latitude},${routeCoordinates.last.longitude}'
        '&waypoints=$waypointsString'
        '&key=$apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          String encodedPolyline = route['overview_polyline']['points'];
          List<LatLng> tempPolylinePoints = decodePolyline(encodedPolyline);

          // Distancia total
          double totalDistance = 0.0;
          for (var leg in route['legs']) {
            totalDistance += leg['distance']['value'];
          }
          String distText = (totalDistance / 1000).toStringAsFixed(2) + ' km';

          // Tiempo estimado (ej. con velocidad 15 km/h)
          final double speedKmh = 15.0;
          double hours = (totalDistance / 1000) / speedKmh; 
          int estimatedHours = hours.floor();
          int estimatedMinutes = ((hours - estimatedHours) * 60).round();
          String timeText = '${estimatedHours}h ${estimatedMinutes}m';

          // Actualizar estado
          setState(() {
            this.pointsMap = tempPointsMap;
            this.startIcon = sIcon;
            this.endIcon = eIcon;
            this.polylinePoints = tempPolylinePoints;
            this.estimatedTime = timeText;
            this.totalDistanceText = distText;
            this.totalPoints = rutasLimitadas.length.toString();

            polylines = {
              Polyline(
                polylineId: PolylineId('ruta_optima'),
                points: this.polylinePoints,
                color: Colors.blue,
                width: 5,
              )
            };
          });
          if (widget.autoOpenIndex != null) {
            final indexToOpen = widget.autoOpenIndex!;
            if (indexToOpen >= 0 && indexToOpen < pointsMap.length) {
              final rutaToCheck = pointsMap[indexToOpen];
              final cutPointsSet = await _loadCutPoints();

              // Verificamos si el punto está cortado
              if (!cutPointsSet.contains(rutaToCheck.bscocNcoc.toString())) {
                setState(() {
                  selectedRuta = rutaToCheck; // Seleccionamos la ruta
                  showHalfForm = true;        // Mostramos el formulario
                });
              }
            }
          }

          // Finalmente, refrescar marcadores
          _refrescarMarcadores();
        }
      }
    } catch (e) {
      print("Error: $e");
    }
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
          // Quitar lat=0, lon=0
          return !(ruta.bscntlati == 0.0 && ruta.bscntlogi == 0.0);
        }).toList();
        return rutas;
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<void> _cargarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    final registrosJson = prefs.getString('registros_corte') ?? '[]';
    final List<dynamic> registrosMap = jsonDecode(registrosJson);

    setState(() {
      registros = registrosMap.map((map) => RegistroCorte.fromMap(map)).toList();
    });
  }

  Future<Set<String>> _loadCutPoints() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cutPoints = prefs.getStringList('puntos_cortados') ?? [];
    return cutPoints.toSet();
  }

  // DISTANCIAS Y TSP
  Future<List<List<double>>> buildDistanceMatrix(List<RutasSinCortar> rutas,
      LatLng oficinaInicial, LatLng oficinaFinal) async {
    final n = rutas.length + 2;
    final matrix = List.generate(n, (_) => List.filled(n, double.infinity));

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        LatLng origin;
        LatLng destination;

        if (i == 0) {
          origin = oficinaInicial;
          if (j == n - 1) {
            continue;
          }
          destination = LatLng(rutas[j - 1].bscntlati, rutas[j - 1].bscntlogi);
        } else if (j == n - 1) {
          destination = oficinaFinal;
          origin = LatLng(rutas[i - 1].bscntlati, rutas[i - 1].bscntlogi);
        } else {
          origin = LatLng(rutas[i - 1].bscntlati, rutas[i - 1].bscntlogi);
          destination = LatLng(rutas[j - 1].bscntlati, rutas[j - 1].bscntlogi);
        }

        final distance = await getDirectionsDistance(origin, destination);
        matrix[i][j] = distance;
        matrix[j][i] = distance; // Simétrica
      }
    }
    // Forzar infinito de start->end directo
    matrix[0][n - 1] = double.infinity;
    matrix[n - 1][0] = double.infinity;

    return matrix;
  }

  Future<double> getDirectionsDistance(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return data['routes'][0]['legs'][0]['distance']['value'] / 1000.0;
        }
      }
      return double.infinity;
    } catch (e) {
      return double.infinity;
    }
  }

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

  void _permute(List<int> route, int start, int end,
      List<List<double>> matrix, Function(List<int>) callback) {
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

  // CREAR MARCADORES
  Future<void> _refrescarMarcadores() async {
    final cutPointsSet = await _loadCutPoints();
    if (startIcon == null || endIcon == null) return;

    Set<Marker> markersTemp = {};

    // Marcador de inicio
    markersTemp.add(Marker(
      markerId: MarkerId('oficina_inicial'),
      position: oficinaInicial,
      infoWindow: InfoWindow(title: 'Oficina Inicial'),
      icon: startIcon!,
    ));

    // Marcador final
    final oficinaFinal = LatLng(-16.3850, -60.9651);
    markersTemp.add(Marker(
      markerId: MarkerId('oficina_final'),
      position: oficinaFinal,
      infoWindow: InfoWindow(title: 'Oficina Final'),
      icon: endIcon!,
    ));

    // Marcadores de puntos
    for (int i = 0; i < pointsMap.length; i++) {
      final point = pointsMap[i];
      bool isCut = cutPointsSet.contains(point.bscocNcoc.toString());
      bool hasValue = false;

      if (isCut) {
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
        hasValue = registro.valorMedidor != null && registro.valorMedidor!.isNotEmpty;
      }

      final customIcon = await createCustomMarkerWithNumber(i + 1, isCut, hasValue);

      markersTemp.add(Marker(
        markerId: MarkerId('punto_${i + 1}'),
        position: LatLng(point.bscntlati, point.bscntlogi),
        infoWindow: InfoWindow(title: 'Punto ${i + 1}'),
        icon: customIcon,
onTap: () {
  // Permitir abrir el formulario si:
  // 1. El punto no está cortado, o
  // 2. El punto está cortado pero tiene observación
  if (!isCut || !hasValue) {
    setState(() {
      selectedRuta = point;
      showHalfForm = true;
      // Limpiamos los campos del formulario
      _selectedOption = 'Ninguna';
      _textController.clear();
      _fotoBase64 = null;
      _fotoFile = null;
    });
  } else {
    // Mostrar mensaje si no se puede abrir el formulario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'El punto ${i + 1} ya está cortado y no tiene observación.',
        ),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
},

      ));
    }

    int cutCount = pointsMap
        .where((p) => cutPointsSet.contains(p.bscocNcoc.toString()))
        .length;

    setState(() {
      markers = markersTemp;
      this.cutPoints = cutCount.toString();
    });
  }

  // CREAR ÍCONO DE MARCADOR
  Future<BitmapDescriptor> createBitmapDescriptor(String assetPath) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    final Uint8List uint8List = byteData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(
      uint8List,
      targetWidth: 100,
      targetHeight: 100,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedByteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedUint8List = resizedByteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resizedUint8List);
  }

  Future<BitmapDescriptor> createCustomMarkerWithNumber(
      int number, bool isCut, bool hasValue) async {
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

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint circlePaint = Paint()
      ..color = isCut
          ? (hasValue ? Colors.green : Colors.orange)
          : Colors.red;
    canvas.drawCircle(Offset(30, 30), 30, circlePaint);

    textPainter.paint(
      canvas,
      Offset(
        30 - textPainter.width / 2,
        30 - textPainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(60, 60);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // DECODE POLYLINE
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

  // LÓGICA DEL FORM (la mitad inferior)
  Future<void> _tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      setState(() {
        _fotoBase64 = base64Encode(bytes);
        _fotoFile = File(foto.path);
      });
    }
  }

  Future<void> _guardarRegistro() async {
    if (selectedRuta == null) return; // No hay ruta seleccionada

    final ruta = selectedRuta!;
    final String? valorMedidor =
        _selectedOption == 'Ninguna' ? _textController.text : null;
    final String? observacion =
        _selectedOption == 'Observacion' ? _textController.text : null;

    final nuevoRegistro = RegistroCorte(
      codigoUbicacion: ruta.bscocNcoc,
      usuarioRelacionado: ruta.bscocNcnt,
      codigoFijo: ruta.bscntCodf,
      nombre: ruta.dNomb,
      medidorSerie: ruta.bsmednser,
      numeroMedidor: ruta.bsmedNume,
      valorMedidor: valorMedidor,
      observacion: observacion,
      fechaCorte: DateTime.now(),
      fotoBase64: _fotoBase64,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final registrosJson = prefs.getString('registros_corte') ?? '[]';
      final List<dynamic> registrosPrevios = jsonDecode(registrosJson);

      registrosPrevios.add(nuevoRegistro.toMap());
      await prefs.setString('registros_corte', jsonEncode(registrosPrevios));

      // Guardar también el punto como cortado
      List<String> puntosCortados = prefs.getStringList('puntos_cortados') ?? [];
      String codigoUbicacionStr = ruta.bscocNcoc.toString();
      if (!puntosCortados.contains(codigoUbicacionStr)) {
        puntosCortados.add(codigoUbicacionStr);
        await prefs.setStringList('puntos_cortados', puntosCortados);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Registro guardado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      // Ocultar panel y refrescar
      setState(() {
        showHalfForm = false;
        // Limpieza de variables
        selectedRuta = null;
      });
      await _cargarRegistros();
      await _refrescarMarcadores();
    } catch (e) {
      print('Error al guardar el registro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el registro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cerrarForm() {
    // Oculta el panel
    setState(() {
      showHalfForm = false;
      selectedRuta = null;
    });
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Cortes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // MITAD (O PARTE) SUPERIOR: MAPA
          Expanded(
            child: markers.isEmpty
                ? Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: oficinaInicial,
                      zoom: 17, // Ajusta zoom según tu necesidad
                    ),
                    markers: markers,
                    polylines: polylines,
                  ),
          ),
          // MITAD INFERIOR (el formulario) solo si showHalfForm = true
          if (showHalfForm)
            Container(
              color: Colors.black,
              height: MediaQuery.of(context).size.height * 0.5, // 50% pantalla
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: _buildRegistroCorteForm(),
              ),
            )
          else
            // Si NO hay formulario, mostramos un pequeño panel de info
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

  /// Construye el formulario de registro en la mitad inferior
  Widget _buildRegistroCorteForm() {
    if (selectedRuta == null) {
      // En caso de que no haya ruta seleccionada (safety)
      return const SizedBox.shrink();
    }

    final ruta = selectedRuta!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón para cerrar
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: _cerrarForm,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registro de Corte',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        Divider(color: Colors.white),

        // Información de la ruta
        Text(
          'Información de la Ruta:',
          style: TextStyle(
            color: Colors.lightBlueAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _infoText('📍 Nombre: ${ruta.dNomb}'),
        _infoText('🔢 Código Ubicación: ${ruta.bscocNcoc}'),
        _infoText('🧾 Código Fijo: ${ruta.bscntCodf}'),
        _infoText('📄 Medidor Serie: ${ruta.bsmednser}'),
        _infoText('🔢 Número de Medidor: ${ruta.bsmedNume}'),

        // Si ya existe foto
        if (_fotoFile != null) ...[
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  '📷 Foto',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.file(_fotoFile!, fit: BoxFit.cover),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        Text(
          'Digite Lectura:',
          style: TextStyle(
            color: Colors.lightBlueAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButton<String>(
          value: _selectedOption,
          dropdownColor: Colors.black87,
          style: TextStyle(color: Colors.white),
          items: ['Ninguna', 'Observacion'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedOption = newValue!;
              _textController.clear();
            });
          },
        ),

        const SizedBox(height: 10),
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: _selectedOption == 'Ninguna'
                ? 'Valor del Medidor'
                : 'Observación',
            labelStyle: TextStyle(color: Colors.white),
            hintText: _selectedOption == 'Ninguna'
                ? 'Ingrese el valor del medidor'
                : 'Ingrese la observación',
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlueAccent),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(color: Colors.white),
        ),

        const SizedBox(height: 20),
        // Botón para guardar
        Center(
          child: ElevatedButton.icon(
            onPressed: _guardarRegistro,
            icon: Icon(Icons.save),
            label: Text('Guardar Corte'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(200, 50),
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Botón para tomar foto
        Center(
          child: ElevatedButton.icon(
            onPressed: _tomarFoto,
            icon: Icon(Icons.camera_alt),
            label: Text('Tomar Foto'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(200, 50),
              backgroundColor: Colors.blueAccent.shade700,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _infoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
