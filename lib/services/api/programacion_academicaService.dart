import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/asistencias.dart';
import 'package:http/http.dart' as http;
import 'package:sig_proyecto/models/programacion_academica.dart';
import 'package:sig_proyecto/server.dart';

class ProgramacionAcademicaService extends ChangeNotifier {
  List<Asistencias> asistencias = []; // Lista de asistencias
  late List<ProgramacionAcademica> progAcademica = [];
  bool isLoading = true;
  Server servidor = Server();

  Future<List<ProgramacionAcademica>> loadProgramacionAcademica(
      String userId, String token) async {
    isLoading = true;
    progAcademica = [];

    final resp = await http.get(
      Uri.parse(
          '${servidor.baseURL}adminuser/get-all-docenteMateriasByUser/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (resp.statusCode == 200) {
      final List<dynamic> progAcademicaMap =
          json.decode(utf8.decode(resp.bodyBytes));

      progAcademica = progAcademicaMap
          .map((element) => ProgramacionAcademica.fromMap(element))
          .toList();

      isLoading = false;
      notifyListeners();
      return progAcademica;
    } else {
      isLoading = false;
      notifyListeners();
      throw Exception('Failed to load programacion academica');
    }
  }

  // Método para verificar si ya existe una asistencia para el docente_materia_id y fecha actual
  bool existeAsistencia(String docenteMateriaId, DateTime fechaActual) {
    print('Verificando existencia de asistencia:');
    print('DocenteMateriaId: $docenteMateriaId');
    print(
        'Fecha Actual: ${fechaActual.day}/${fechaActual.month}/${fechaActual.year}');

    bool exists = asistencias.any((asistencia) =>
        asistencia.docenteMaterias.id == docenteMateriaId &&
        asistencia.fecha ==
            '${fechaActual.day}/${fechaActual.month}/${fechaActual.year}');

    print('Existe Asistencia: $exists');

    return exists;
  }
}
