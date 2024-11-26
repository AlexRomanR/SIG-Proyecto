import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/models/rutas_sin_cortar.dart';
import 'package:gestion_asistencia_docente/screens/login/home_screen.dart';
import 'package:gestion_asistencia_docente/models/registro_corte.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListaRegistrosScreen extends StatefulWidget {
  const ListaRegistrosScreen({Key? key}) : super(key: key);

  @override
  _ListaRegistrosScreenState createState() => _ListaRegistrosScreenState();
}

class _ListaRegistrosScreenState extends State<ListaRegistrosScreen> {
  List<RegistroCorte> registros = [];

  @override
  void initState() {
    super.initState();
    _cargarRegistros();
  }

  Future<void> _cargarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    final registrosJson = prefs.getString('registros_corte') ?? '[]';
    final List<dynamic> registrosMap = jsonDecode(registrosJson);

    setState(() {
      registros = registrosMap
          .map((map) => RegistroCorte.fromMap(map))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Registros de Corte'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: registros.isEmpty
          ? const Center(
              child: Text(
                'No hay registros guardados',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final registro = registros[index];
                return Card(
                  color: Colors.black26,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      'Ubicación: ${registro.codigoUbicacion}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código Fijo: ${registro.codigoFijo}',
                            style: const TextStyle(color: Colors.grey)),
                        Text('Nombre: ${registro.nombre}',
                            style: const TextStyle(color: Colors.grey)),
                        Text('Serie Medidor: ${registro.medidorSerie}',
                            style: const TextStyle(color: Colors.grey)),
                        Text('Número Medidor: ${registro.numeroMedidor}',
                            style: const TextStyle(color: Colors.grey)),
                        Text('Fecha Corte: ${registro.fechaCorte}',
                            style: const TextStyle(color: Colors.grey)),    
                        Text('Valor Medidor: ${registro.valorMedidor}',
                            style: const TextStyle(color: Colors.lightGreen)),  
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}