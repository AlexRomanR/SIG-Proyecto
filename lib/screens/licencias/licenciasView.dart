import 'package:flutter/material.dart';
import 'package:sig_proyecto/screens/licencias/licenciasEditar.dart';
import 'package:sig_proyecto/services/api/licenciasService.dart';
import 'package:sig_proyecto/services/server.dart';
import 'package:provider/provider.dart';
import 'package:sig_proyecto/services/auth/auth_service.dart';
import 'package:http/http.dart' as http;

class LicenciasView extends StatefulWidget {
  const LicenciasView({Key? key}) : super(key: key);

  @override
  _LicenciasViewState createState() => _LicenciasViewState();
}

class _LicenciasViewState extends State<LicenciasView> {
  late LicenciasService licenciasService;
  late String userId;
  late String token;
  Servidor servidor = Servidor();

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    userId = authService.user.id.toString();

    licenciasService = LicenciasService();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await licenciasService.loadLicencias(userId, token);
    } catch (e) {
      // Manejar el error aquí
      print('Error loading licencias: $e');
    }
  }

  Future<void> _deleteLicencia(int licenciaId, String token) async {
    final uri =
        Uri.parse('${servidor.baseURL}/adminuser/delete-licencia/$licenciaId');
    final requestHeaders = {
      'Authorization': 'Bearer $token',
    };

    print('URI para eliminar licencia: $uri');

    final response = await http.delete(uri, headers: requestHeaders);

    print('StatusCode: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Licencia eliminada exitosamente'),
        ),
      );
      // Actualizar la lista de licencias después de eliminar
      await licenciasService.loadLicencias(userId, token);
      setState(() {}); // Forzar la actualización de la interfaz
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar la licencia'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LicenciasService>(
      create: (_) => licenciasService,
      child: Consumer<LicenciasService>(
        builder: (context, licenciasService, child) {
          if (licenciasService.isLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Licencias'),
              foregroundColor: Colors.white, // Color del texto en blanco
            ),
            body: ListView.builder(
              itemCount: licenciasService.licencias.length,
              itemBuilder: (context, index) {
                final licencia = licenciasService.licencias[index];
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
                          'Motivo: ${licencia.motivo}',
                          style: TextStyle(color: Colors.white),
                        ),
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
                                text: licencia.estado,
                                style: TextStyle(
                                  color: licencia.estado == 'Rechazado'
                                      ? Colors.red
                                      : licencia.estado == 'En espera'
                                          ? Color.fromARGB(255, 253, 238, 31)
                                          : licencia.estado == 'Aceptado'
                                              ? Colors.green
                                              : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Fecha: ${licencia.fecha}',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Docente: ${licencia.docenteMaterias.docente.name}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Materia: ${licencia.docenteMaterias.materia.nombre}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Horario: ${licencia.docenteMaterias.horarioInicio} - ${licencia.docenteMaterias.horarioFin}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Día: ${licencia.docenteMaterias.dia}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Grupo: ${licencia.docenteMaterias.grupo}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Carrera: ${licencia.docenteMaterias.carrera.nombre}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Aula: ${licencia.docenteMaterias.aula.numero}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Módulo: ${licencia.docenteMaterias.modulo.numero}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Facultad: ${licencia.docenteMaterias.facultad.nombre}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditarLicencia(id: licencia.id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteLicencia(licencia.id, token),
                            ),
                          ],
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
