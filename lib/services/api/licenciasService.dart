import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/licencias.dart';
import 'package:http/http.dart' as http;
import 'package:sig_proyecto/server.dart';

class LicenciasService extends ChangeNotifier {
  late List<Licencias> licencias = [];
  bool isLoading = true;
  Server servidor = Server();

  Future<List<Licencias>> loadLicencias(String userId, String token) async {
    isLoading = true;
    licencias = [];

    final resp = await http.get(
      Uri.parse(
          '${servidor.baseURL}adminuser/get-licencias-by-docente/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (resp.statusCode == 200) {
      final List<dynamic> licenciasMap =
          json.decode(utf8.decode(resp.bodyBytes));

      licencias =
          licenciasMap.map((element) => Licencias.fromMap(element)).toList();

      isLoading = false;
      notifyListeners();
      return licencias;
    } else {
      isLoading = false;
      notifyListeners();
      throw Exception('Failed to load Asistencias');
    }
  }
}
