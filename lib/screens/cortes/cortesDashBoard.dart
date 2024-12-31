import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sig_proyecto/screens/cortes/ImportCortesFromServer.dart';
import 'package:sig_proyecto/screens/cortes/cortesRutasLocalSinOrden.dart';
import 'package:sig_proyecto/screens/cortes/mapaCortes.dart';
import 'package:sig_proyecto/screens/cortes/registroCorteLista.dart';
import 'package:sig_proyecto/services/api/rutasService.dart';
import 'package:sig_proyecto/models/registro_corte.dart'; // Modelo de RegistroCorte

class CortesDashboardView extends StatefulWidget {
  const CortesDashboardView({super.key});

  @override
  State<CortesDashboardView> createState() => _CortesDashboardViewState();
}

class _CortesDashboardViewState extends State<CortesDashboardView> {
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
      registros =
          registrosMap.map((map) => RegistroCorte.fromMap(map)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard de Cortes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            _buildButton(
              context: context,
              text: "Importar cortes desde el servidor",
              icon: Icons.cloud_download,
              color: Colors.blueAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportCortesFromServerView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildButton(
              context: context,
              text: "Registrar cortes",
              icon: Icons.edit_note,
              color: Colors.greenAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const mapaCortes(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildButton(
              context: context,
              text: "Lista para cortes",
              icon: Icons.cloud_upload,
              color: Color.fromARGB(255, 214, 231, 113),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewSavedRutasSinOrden()
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildButton(
              context: context,
              text: "Exportar cortes al servidor",
              icon: Icons.list_alt,
              color: Color.fromARGB(255, 233, 133, 75),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListaRegistrosScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        side: BorderSide(color: color, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      icon: Icon(icon, color: color, size: 24),
      label: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
