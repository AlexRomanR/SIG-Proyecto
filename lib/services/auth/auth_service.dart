import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:sig_proyecto/models/user.dart';
import 'package:sig_proyecto/services/server.dart';

import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  bool _isloggedIn = false;
  User? _user;
  String? _token;

  bool get authentificate => _isloggedIn;
  User get user => _user!;

  Servidor servidor = Servidor();

  final _storage = const FlutterSecureStorage();

  Future<String> login(String username, String password) async {
    // Construir el cuerpo XML para la solicitud SOAP
    String soapBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <ValidarLoginPassword xmlns="http://tempuri.org/">
      <lsLogin>$username</lsLogin>
      <lsPassword>$password</lsPassword>
    </ValidarLoginPassword>
  </soap:Body>
</soap:Envelope>''';

    try {
      // Realizar la solicitud HTTP POST
      final response = await http.post(
        Uri.parse('${servidor.baseURL}/wsVarios/wsAd.asmx'),
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '"http://tempuri.org/ValidarLoginPassword"',
        },
        body: soapBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Procesar la respuesta XML
        final responseBody = response.body;
        if (responseBody.contains('<ValidarLoginPasswordResult>')) {
          // Extraer el resultado
          final startTag = '<ValidarLoginPasswordResult>';
          final endTag = '</ValidarLoginPasswordResult>';
          final result = responseBody.substring(
            responseBody.indexOf(startTag) + startTag.length,
            responseBody.indexOf(endTag),
          );

          print('Result obtenido: $result');

          if (result.startsWith('OK|')) {
            await trySession();

            return 'Login exitoso';
          } else {
            return 'Credenciales incorrectas';
          }
        } else {
          return 'Formato de respuesta inesperado';
        }
      } else {
        return 'Error ${response.statusCode}: ${response.reasonPhrase}';
      }
    } catch (e) {
      print('Error en login: $e');
      return 'Error en login';
    }
  }

  Future<void> trySession() async {
    // Valor fijo
    const String fixedSessionValue = 'WEB|152|6272';

    // Construir el cuerpo SOAP para la solicitud
    String soapBody = '''<?xml version="1.0" encoding="utf-8"?>
  <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
      <GBOFN_ObtenerRegistroPorCUsuario xmlns="http://tempuri.org/">
        <lsCusr>$fixedSessionValue</lsCusr>
      </GBOFN_ObtenerRegistroPorCUsuario>
    </soap:Body>
  </soap:Envelope>''';

    try {
      final response = await http.post(
        Uri.parse('${servidor.baseURL}/wsVarios/wsGB.asmx'),
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '"http://tempuri.org/GBOFN_ObtenerRegistroPorCUsuario"',
        },
        body: soapBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Procesar la respuesta XML
        final responseBody = response.body;

        // Extraer el valor de <GBOFN_ObtenerRegistroPorCUsuarioResult>
        final startTag = '<GBOFN_ObtenerRegistroPorCUsuarioResult>';
        final endTag = '</GBOFN_ObtenerRegistroPorCUsuarioResult>';
        final result = responseBody.substring(
          responseBody.indexOf(startTag) + startTag.length,
          responseBody.indexOf(endTag),
        );

        print('Session ID obtenido: $result');

        if (result.isNotEmpty) {
          await _storage.write(key: 'session_id', value: result);
          _isloggedIn = true;
          notifyListeners();
        } else {
          print('El valor de session_id está vacío');
        }
      } else {
        print('Error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error en trySession: $e');
    }
  }

  void storageToken(String token) async {
    _storage.write(key: 'token', value: token);
  }

  void logut() async {
    try {
      final response = await http.get(
          Uri.parse('${servidor.baseURL}/auth/invalidate'),
          headers: {'Authorization': 'Bearer $_token'});
      cleanUp();
      notifyListeners();
    } catch (e) {}
  }

  void cleanUp() async {
    _user = null;
    _isloggedIn = false;
    // TODO: cache del tefono

    await _storage.delete(key: 'token');
  }
}
