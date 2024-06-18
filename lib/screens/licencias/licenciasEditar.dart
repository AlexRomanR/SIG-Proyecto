import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/models/licencias.dart';
import 'package:gestion_asistencia_docente/screens/licencias/licenciasView.dart';
import 'package:gestion_asistencia_docente/services/api/licenciasService.dart';
import 'package:gestion_asistencia_docente/services/auth/auth_service.dart';
import 'package:gestion_asistencia_docente/services/server.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;

class EditarLicencia extends StatefulWidget {
  final int id;

  const EditarLicencia({required this.id, super.key});

  @override
  State<EditarLicencia> createState() => _EditarLicenciaState();
}

class _EditarLicenciaState extends State<EditarLicencia> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController motivo = TextEditingController();

  late LicenciasService licenciasService;

  bool isLoading = true;
  late String user_id;
  late String token;
  Servidor servidor = Servidor();
  Licencias? licencia;

  @override
  void initState() {
    final authservice = context.read<AuthService>();
    user_id = authservice.user.id.toString();
    token = authservice.token!;
    licenciasService = LicenciasService();
    _loadLicencias();
    super.initState();
  }

  //filtra para saber que educación especifica se editara
  Future<void> _loadLicencias() async {
    final licencias = await licenciasService.loadLicencias(user_id, token);
    final licenciaFiltrada = licencias.firstWhere((r) => r.id == widget.id);

    if (licenciaFiltrada != null) {
      setState(() {
        licencia = licenciaFiltrada;
        motivo.text = licencia!.motivo;
        isLoading = false;
      });
    } else {
      // Manejar el caso donde no se encontró la educación
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Licencia no encontrada'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar su licencia'),
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
                    return 'Por favor, ingrese un nombre.';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formkey.currentState!.validate()) {
      final uri = Uri.parse(
          '${servidor.baseURL}/adminuser/update-licencia/${widget.id}');
      final requestHeaders = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

      final body = json.encode({
        'motivo': motivo.text,
        'estado': licencia!.estado, // Mantener el mismo estado
        'fecha': licencia!.fecha, // Mantener la misma fecha
        'docente_materia_id': licencia!
            .docenteMaterias.id, // Mantener el mismo docente_materia_id
      });

      final response = await http.put(uri, headers: requestHeaders, body: body);

      if (response.statusCode == 200) {
        print('Licencia actualizada con éxito');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licencia actualizada con éxito'),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LicenciasView(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un error al actualizar la licencia'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa el formulario correctamente'),
        ),
      );
    }
  }
}
