import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:sig_proyecto/screens/login/home_screen.dart';
import 'package:sig_proyecto/models/registro_corte.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sig_proyecto/screens/cortes/cortesDashBoard.dart';
import 'package:sig_proyecto/services/api/rutasService.dart';

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
      registros =
          registrosMap.map((map) => RegistroCorte.fromMap(map)).toList();
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
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Lista de registros
            registros.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text(
                        'No hay registros guardados',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: registros.length,
                      itemBuilder: (context, index) {
                        final registro = registros[index];
                        return Card(
                          elevation: 4,
                          color:
                              Color.fromARGB(255, 29, 29, 29), // Color oscuro
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.lightBlue,
                              child: Icon(Icons.device_hub,
                                  color: Colors.white), // Ícono personalizado
                            ),
                            title: Text(
                              'Ubicación: ${registro.codigoUbicacion}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  '📌 Código Fijo: ${registro.codigoFijo}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '👤 Nombre: ${registro.nombre}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '🔢 Serie Medidor: ${registro.medidorSerie}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '🔄 Número Medidor: ${registro.numeroMedidor}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '📅 Fecha Corte: ${registro.fechaCorte}',
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '💧 Valor Medidor: ${registro.valorMedidor}',
                                  style: TextStyle(
                                    color: Colors.lightGreen,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            // Botones fijos
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildButton(
                    context: context,
                    text: "Exportar cortes al servidor",
                    icon: Icons.cloud_upload,
                    color: Colors.orangeAccent,
                    onPressed: () async {
                      final rutasService = RutasService();
                      await rutasService.exportarCortesAlServidor(registros);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Registros exportados al servidor.')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    context: context,
                    text: "Volver al Menú",
                    icon: Icons.list_alt,
                    color: Colors.redAccent,
                    onPressed: () {
                      Navigator.pop(context); 
                    },
                  ),
                ],
              ),
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
