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

  Future<void> _eliminarRutasAsociadas() async {
    final prefs = await SharedPreferences.getInstance();

    // Obtener IDs de las rutas asociadas a los registros de corte
    final rutasAsociadas = registros.map((r) => r.codigoUbicacion.toString()).toSet();

    // Filtrar y actualizar rutas_seleccionadas
    final rutasSeleccionadas = prefs.getStringList('rutas_seleccionadas') ?? [];
    final rutasSeleccionadasFiltradas = rutasSeleccionadas.where((ruta) => !rutasAsociadas.contains(ruta)).toList();
    await prefs.setStringList('rutas_seleccionadas', rutasSeleccionadasFiltradas);

    // Filtrar y actualizar saved_rutas_tsp
    final savedRutasTspJson = prefs.getString('saved_rutas_tsp');
    if (savedRutasTspJson != null) {
      final List<dynamic> savedRutasTsp = jsonDecode(savedRutasTspJson);
      final savedRutasTspFiltradas = savedRutasTsp.where((ruta) => !rutasAsociadas.contains(ruta['bscocNcoc'].toString())).toList();
      await prefs.setString('saved_rutas_tsp', jsonEncode(savedRutasTspFiltradas));
    }

    // Filtrar y actualizar saved_rutas
    final savedRutasJson = prefs.getString('saved_rutas');
    if (savedRutasJson != null) {
      final List<dynamic> savedRutas = jsonDecode(savedRutasJson);
      final savedRutasFiltradas = savedRutas.where((ruta) => !rutasAsociadas.contains(ruta['bscocNcoc'].toString())).toList();
      await prefs.setString('saved_rutas', jsonEncode(savedRutasFiltradas));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Registros de Corte', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
                        final backgroundColor = registro.observacion != null
                          ? Colors.orange
                          : Colors.green;
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
                              backgroundColor: backgroundColor,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                if (registro.valorMedidor != null) Text(
                                  '💧 Valor Medidor: ${registro.valorMedidor}',
                                  style: TextStyle(
                                    color: Colors.lightGreen,
                                    fontSize: 12,
                                  ),
                                ),
                                if (registro.observacion != null) Text(
                                  '📝 Observación: ${registro.observacion}',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                if (registro.fotoBase64 != null) ...[
                                  Text(
                                    '📷 Foto:',
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 255, 255, 255),
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.memory(
                                      base64Decode(registro.fotoBase64!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
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
                      if (registros.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No hay registros para exportar.')),
                        );
                        return;
                      }
                  
                      final rutasService = RutasService();
                      await rutasService.exportarCortesAlServidor(registros);
                      await _eliminarRutasAsociadas();

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('registros_corte');
                  
                      setState(() {
                        registros.clear(); 
                      });
                  
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Registros exportados correctamente.')),
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
