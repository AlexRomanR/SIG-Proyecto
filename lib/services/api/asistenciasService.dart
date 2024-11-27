import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/asistencias.dart';
import 'package:http/http.dart' as http;
import 'package:sig_proyecto/server.dart';

class AsistenciasService extends ChangeNotifier {
  late List<Asistencias> asistencias = [];
  bool isLoading = true;
  Server servidor = Server();

  Future<List<Asistencias>> loadAsistencias(String userId, String token) async {
    isLoading = true;
    asistencias = [];

    final resp = await http.get(
      Uri.parse(
          '${servidor.baseURL}adminuser/get-asistencias-by-docente/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (resp.statusCode == 200) {
      final List<dynamic> asistenciasMap =
          json.decode(utf8.decode(resp.bodyBytes));

      asistencias = asistenciasMap
          .map((element) => Asistencias.fromMap(element))
          .toList();

      isLoading = false;
      notifyListeners();
      return asistencias;
    } else {
      isLoading = false;
      notifyListeners();
      throw Exception('Failed to load Asistencias');
    }
  }

  bool existeAsistencia(String docenteMateriaId, DateTime fechaActual) {
    final formattedDate =
        '${fechaActual.day}/${fechaActual.month}/${fechaActual.year}';
    print(
        'Comparando asistencias para docenteMateriaId: $docenteMateriaId y fecha: $formattedDate');

    // Verifica que asistencias tenga elementos
    if (asistencias.isEmpty) {
      print('La lista de asistencias está vacía.');
      return false;
    }

    // Imprime cada asistencia que se está comparando
    asistencias.forEach((asistencia) {
      print(
          'Asistencia: ${asistencia.docenteMaterias.id} - ${asistencia.fecha}');
    });

    // Asegúrate de que formattedDate y docenteMateriaId sean exactamente iguales a como están en las asistencias
    return asistencias.any((asistencia) =>
        asistencia.docenteMaterias.id == docenteMateriaId &&
        asistencia.fecha == formattedDate);
  }
}
