import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sig_proyecto/screens/programacion_academica/programacion_academicaView.dart';
import 'package:sig_proyecto/services/auth/auth_service.dart';
import 'package:sig_proyecto/services/server.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class CrearLicencia extends StatefulWidget {
  final String docenteMateriaId;

  const CrearLicencia({required this.docenteMateriaId, Key? key})
      : super(key: key);

  @override
  State<CrearLicencia> createState() => _CrearLicenciaState();
}

class _CrearLicenciaState extends State<CrearLicencia> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController motivo = TextEditingController();

  bool isLoading = true;
  late String user_id;
  late String token;
  Servidor servidor = Servidor();

  @override
  void initState() {
    super.initState();
    final authservice = context.read<AuthService>();
    user_id = authservice.user.id.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Licencia'),
        foregroundColor: Colors.white, // Color del texto en blanco
      ),
      body: Form(
        key: _formkey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 30),
              TextFormField(
                controller: motivo,
                decoration:
                    const InputDecoration(labelText: 'Motivo de la licencia'),
                style: TextStyle(
                  color:
                      Colors.white, // Color del texto dentro del TextFormField
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, ingresa el motivo de la licencia.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    _submitForm(widget.docenteMateriaId, user_id, token),
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(
      String docenteMateriaId, String userId, String token) async {
    if (_formkey.currentState!.validate()) {
      final uri = Uri.parse('${servidor.baseURL}/adminuser/create-licencia');
      final requestHeaders = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

      // Obtener la fecha actual
      DateTime now = DateTime.now();
      String formattedDate = '${now.day}/${now.month}/${now.year}';

      final body = json.encode({
        'docente_materia_id': docenteMateriaId,
        'motivo': motivo.text,
        'estado': "En espera",
        'fecha': formattedDate,
      });

      final response =
          await http.post(uri, headers: requestHeaders, body: body);

      if (response.statusCode == 200) {
        print('Licencia creada con éxito');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licencia creada con éxito'),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramacionAcademicaView(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un error al crear la licencia'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hubo un error al crear la licencia'),
        ),
      );
    }
  }
}
