import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:gestion_asistencia_docente/models/user.dart';
import 'package:gestion_asistencia_docente/services/server.dart';

import 'package:http/http.dart' as http;


class AuthService extends ChangeNotifier {
  bool _isloggedIn = false;
  User? _user;
  String? _token;
  


  bool get authentificate => _isloggedIn;
  User get user => _user!;
  String? get token => _token;  // Agregar el getter para el token

  Servidor servidor = Servidor();

  final _storage = const FlutterSecureStorage();



Future<String> login(String email, String password, String device_name) async {
  try {
    final response = await http.post(
      Uri.parse('${servidor.baseURL}/auth/token'),
      headers: {
        'Content-Type': 'application/json',  
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_name': device_name, 
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      String token = response.body.toString();
      print('Token obtenido: $token');
      
   
      if (token != null && token.isNotEmpty) {
        try {
          tryToken(token);
          return 'correcto';
        } catch (e) {
          print('Error en tryToken: $e');
          return 'Error en tryToken';
        }
      } else {
        return 'Token vacío';
      }
    } else {
      print('Error: ${response.statusCode} ${response.reasonPhrase}');
      return 'Ocurrió un error';
    }
  } catch (e) {
    print('Error: $e');
    return 'error en login';
  }
}



void tryToken(String? token) async {
  if (token == null) {
    print('Token is null');
    return;
  } else {
    try {
      final response = await http.get(
        Uri.parse('${servidor.baseURL}/adminuser/get-userToken'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Print the response status and body for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          var decodedBody = jsonDecode(response.body);
          print('Decoded response body: $decodedBody');

          _isloggedIn = true;
          _user = User.fromJson(decodedBody);
          _token = token;

          // TODO: cache del teléfono
          storageToken(token);

          notifyListeners();
        } catch (e) {
          print('Error decoding response body or initializing User: $e');
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized: ${response.body}');
      } else if (response.statusCode == 403) {
        print('Forbidden: ${response.body}');
      } else {
        print('Error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error en tryTokenx222: $e'); // Imprime la excepción para identificar el error
    }
  }
}


  void storageToken(String token) async {
    _storage.write(key: 'token', value: token);

  }

  void logut() async {
    try {
         final response = await http.get(Uri.parse('${servidor.baseURL}/auth/invalidate'),
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