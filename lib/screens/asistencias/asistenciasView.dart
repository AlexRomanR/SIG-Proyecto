import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/services/api/asistenciasService.dart';
import 'package:provider/provider.dart';

import 'package:gestion_asistencia_docente/services/auth/auth_service.dart';

class AsistenciasView extends StatefulWidget {
  const AsistenciasView({Key? key}) : super(key: key);

  @override
  _AsistenciasViewState createState() => _AsistenciasViewState();
}

class _AsistenciasViewState extends State<AsistenciasView> {
  late AsistenciasService asistenciasService;
  late String userId;
  late String token;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    userId = authService.user.id.toString();
    asistenciasService = AsistenciasService();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await asistenciasService.loadAsistencias(userId, token);
    } catch (e) {
      // Handle error here
      print('Error loading asistencias: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AsistenciasService>(
      create: (_) => asistenciasService,
      child: Consumer<AsistenciasService>(
        builder: (context, asistenciasService, child) {
          if (asistenciasService.isLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Asistencias'),
              foregroundColor: Colors.white, // Color del texto en blanco
            ),
            body: ListView.builder(
              itemCount: asistenciasService.asistencias.length,
              itemBuilder: (context, index) {
                final asistencia = asistenciasService.asistencias[index];
                return Card(
                  color: Colors.grey[900],
                  elevation: 4.0,
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Materia: ${asistencia.docenteMaterias.materia.nombre}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Docente: ${asistencia.docenteMaterias.docente.name}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Horario: ${asistencia.docenteMaterias.horarioInicio} - ${asistencia.docenteMaterias.horarioFin}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Día: ${asistencia.docenteMaterias.dia}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Grupo: ${asistencia.docenteMaterias.grupo}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Carrera: ${asistencia.docenteMaterias.carrera.nombre}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Aula: ${asistencia.docenteMaterias.aula.numero}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Módulo: ${asistencia.docenteMaterias.modulo.numero}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Facultad: ${asistencia.docenteMaterias.facultad.nombre}',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Estado: ',
                                style: TextStyle(
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255)),
                              ),
                              TextSpan(
                                text: asistencia.estado,
                                style: TextStyle(
                                  color: asistencia.estado == 'Retraso'
                                      ? Colors.red
                                      : asistencia.estado == 'Puntual'
                                          ? Colors.green
                                          : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Hora Marcada: ${asistencia.horaMarcada}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Fecha: ${asistencia.fecha}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
