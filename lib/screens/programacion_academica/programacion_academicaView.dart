import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/asistencias.dart';
import 'package:sig_proyecto/screens/licencias/licenciasCrear.dart';
import 'package:sig_proyecto/services/api/asistenciasService.dart';
import 'package:sig_proyecto/services/api/programacion_academicaService.dart';
import 'package:sig_proyecto/services/server.dart';
import 'package:provider/provider.dart';
import 'package:sig_proyecto/services/auth/auth_service.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';

class ProgramacionAcademicaView extends StatefulWidget {
  const ProgramacionAcademicaView({super.key});

  @override
  State<ProgramacionAcademicaView> createState() =>
      _ProgramacionAcademicaViewState();
}

class _ProgramacionAcademicaViewState extends State<ProgramacionAcademicaView> {
  late ProgramacionAcademicaService programacionAcademicaService;
  late AsistenciasService asistenciasService;

  late String userId;
  late String token;
  Servidor servidor = Servidor();
  DateTime?
      lastPressedTime; // Variable para almacenar la última vez que se presionó el botón

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    userId = authService.user.id.toString();
    programacionAcademicaService = ProgramacionAcademicaService();
    asistenciasService = AsistenciasService();
    _loadAsistencias();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await programacionAcademicaService.loadProgramacionAcademica(
          userId, token);
    } catch (e) {
      // Maneja el error aquí
      print('Error loading programacion academica: $e');
    }
  }

  Future<void> _loadAsistencias() async {
    try {
      await asistenciasService.loadAsistencias(userId, token);
      print(
          'Asistencias cargadas exitosamente: ${asistenciasService.asistencias}');
    } catch (e) {
      print('Error cargando asistencias: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProgramacionAcademicaService>(
      create: (_) => programacionAcademicaService,
      child: Consumer<ProgramacionAcademicaService>(
        builder: (context, programacionAcademicaService, child) {
          if (programacionAcademicaService.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Programación Académica'),
              foregroundColor: Colors.white, // Color del texto en blanco
            ),
            body: ListView.builder(
              itemCount: programacionAcademicaService.progAcademica.length,
              itemBuilder: (context, index) {
                final prog = programacionAcademicaService.progAcademica[index];
                final DateTime now = DateTime.now();

                // Convertir las horas de inicio y fin a DateTime
                final horarioInicio = TimeOfDay(
                  hour: int.parse(prog.horarioInicio.split(':')[0]),
                  minute: int.parse(prog.horarioInicio.split(':')[1]),
                );
                final horarioFin = TimeOfDay(
                  hour: int.parse(prog.horarioFin.split(':')[0]),
                  minute: int.parse(prog.horarioFin.split(':')[1]),
                );

                // Convertir TimeOfDay a DateTime para comparación
                final start = DateTime(now.year, now.month, now.day,
                    horarioInicio.hour, horarioInicio.minute);
                final end = DateTime(now.year, now.month, now.day,
                    horarioFin.hour, horarioFin.minute);

                // Verificar si la hora actual está dentro del rango
                final bool isWithinTimeRange =
                    now.isAfter(start) && now.isBefore(end);

                // Convertir el día de la semana a String
                final String todayDay = [
                  'Lunes',
                  'Martes',
                  'Miércoles',
                  'Jueves',
                  'Viernes',
                  'Sábado',
                  'Domingo'
                ][now.weekday - 1];

                // Verificar si el día actual coincide con el día de la programación
                final bool isSameDay = prog.dia == todayDay;

                // Parsear la ubicación del módulo
                final List<double> moduloLocation =
                    _parseLocation(prog.modulo.ubicacion);
                final double moduloLatitude = moduloLocation[0];
                final double moduloLongitude = moduloLocation[1];

                return FutureBuilder<Position>(
                  future: _determinePosition(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    final userPosition = snapshot.data!;
                    final double distance = _calculateDistance(
                      userPosition.latitude,
                      userPosition.longitude,
                      moduloLatitude,
                      moduloLongitude,
                    );

                    final bool isWithinDistance = distance <= 70;

                    return Card(
                      color:
                          Colors.grey[900], // Fondo negro claro de la tarjeta
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Materia: ${prog.materia.nombre}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Docente: ${prog.docente.name}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Horario: ${prog.horarioInicio} - ${prog.horarioFin}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Día: ${prog.dia}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Grupo: ${prog.grupo}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Carrera: ${prog.carrera.nombre}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Aula: ${prog.aula.numero}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Módulo: ${prog.modulo.numero}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Facultad: ${prog.facultad.nombre}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Row(
                              children: [
                                if (isSameDay && isWithinTimeRange)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.library_books,
                                      color: Color.fromARGB(255, 52, 155, 66),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CrearLicencia(
                                            docenteMateriaId:
                                                prog.id.toString(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (isSameDay && isWithinTimeRange)
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _submitForm(prog.id.toString(),
                                          prog.modulo.ubicacion, userId, token);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitForm(String docenteMateriaId, String moduloUbicacion,
      String userId, String Token) async {
    final DateTime now = DateTime.now();
    final String formattedDate = '${now.day}/${now.month}/${now.year}';
    final String formattedTime = '${now.hour}:${now.minute}';

    final uri = Uri.parse('${servidor.baseURL}/adminuser/create-asistencia');
    final requestHeaders = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final body = json.encode({
      'docente_materia_id': docenteMateriaId,
      'estado': "Puntual",
      'fecha': formattedDate,
      'hora_marcada': formattedTime,
    });

    try {
      final asistenciasService = AsistenciasService();

      final asistenciasFiltradas = await asistenciasService.loadAsistencias(
          userId, Token); // todas las asistencias

      print('Todas las asistencias:');
      print(
          'Cantidad de asistencias: ${asistenciasService.asistencias.length}');

      asistenciasFiltradas.forEach((asistencia) {
        print('Fecha: ${asistencia.fecha}, Estado: ${asistencia.estado}');
        // Puedes imprimir más detalles de la asistencia según tu estructura de datos
      });

      // Verifica si ya existe una asistencia para este prog.id y fecha actual
      bool existeAsistencia = asistenciasFiltradas.any((asistencia) =>
          (asistencia.fecha == formattedDate) &&
          (asistencia.docenteMaterias.id.toString() == docenteMateriaId));

      if (existeAsistencia) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe una asistencia registrada para hoy'),
          ),
        );
        return;
      }

      // Verifica si el usuario está dentro de la distancia del módulo
      final userPosition = await _determinePosition();
      final isWithinDistance =
          _isWithinDistance(userPosition, moduloUbicacion, 20);

      if (!isWithinDistance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No está cerca del módulo para marcar asistencia'),
          ),
        );
        return;
      }

      final response =
          await http.post(uri, headers: requestHeaders, body: body);

      if (response.statusCode == 200) {
        print('Asistencia creada con éxito');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asistencia creada con éxito'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un error al crear la asistencia'),
          ),
        );
      }
    } catch (e) {
      print('Error al enviar la asistencia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hubo un error al crear la asistencia'),
        ),
      );
    }
  }

  // Método para calcular si la ubicación del usuario está dentro de la distancia requerida del módulo
  bool _isWithinDistance(Position userPosition, String moduloUbicacion,
      double distanciaRequeridaMetros) {
    final List<String> parts = moduloUbicacion.split(',');
    final double moduloLat = double.parse(parts[0]);
    final double moduloLng = double.parse(parts[1]);

    // Mostrar en la consola los valores obtenidos para depuración
    print('userPosition: ${userPosition.latitude}, ${userPosition.longitude}');
    print('moduloLat: $moduloLat');
    print('moduloLng: $moduloLng');

    double distanciaEnMetros = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      moduloLat,
      moduloLng,
    );

    return distanciaEnMetros <= distanciaRequeridaMetros;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  double _calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
  }

  List<double> _parseLocation(String location) {
    final parts = location.split(',');
    final latitude = double.parse(parts[0]);
    final longitude = double.parse(parts[1]);
    return [latitude, longitude];
  }
}
