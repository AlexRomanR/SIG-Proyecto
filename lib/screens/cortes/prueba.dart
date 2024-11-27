import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Prueba extends StatefulWidget {
  @override
  _PruebaState createState() => _PruebaState();
}

class _PruebaState extends State<Prueba> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String apiKey = 'AIzaSyDPnYs5bEjFjnBD1WsUtuZ6NtQkOAGF1I0'; // Reemplaza con tu clave de API

  // Coordenadas de origen y destino
  LatLng _origin = LatLng(40.748817, -73.985428); // Empire State Building
  LatLng _destination = LatLng(40.689247, -74.044502); // Estatua de la Libertad

  @override
  void initState() {
    super.initState();
    _getDirections();
  }

  Future<void> _getDirections() async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_origin.latitude},${_origin.longitude}&destination=${_destination.latitude},${_destination.longitude}&key=$apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0]['legs'][0];
          print("ruta:");
          print(route['steps']);
          _addMarkers(route);
          _addPolyline(route);
        } else {
          print("No directions found");
        }
      } else {
        print("Error fetching directions");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _addMarkers(dynamic route) {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('origin'),
        position: _origin,
        infoWindow: InfoWindow(title: 'Origen', snippet: 'Empire State Building'),
      ));
      _markers.add(Marker(
        markerId: MarkerId('destination'),
        position: _destination,
        infoWindow: InfoWindow(title: 'Destino', snippet: 'Estatua de la Libertad'),
      ));
    });
  }

  void _addPolyline(dynamic route) {
    List<LatLng> polylineCoordinates = [];
    for (var step in route['steps']) {
      var startLocation = step['start_location'];
      var endLocation = step['end_location'];
      polylineCoordinates.add(LatLng(startLocation['lat'], startLocation['lng']));
      polylineCoordinates.add(LatLng(endLocation['lat'], endLocation['lng']));
    }

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Directions API - Mapa'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _origin,
          zoom: 12,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}