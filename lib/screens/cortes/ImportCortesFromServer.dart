import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/services/api/rutasService.dart';

import 'package:gestion_asistencia_docente/services/api/rutas_sin_cortarService.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImportCortesFromServerView extends StatefulWidget {
  const ImportCortesFromServerView({super.key});

  @override
  State<ImportCortesFromServerView> createState() => _ImportCortesFromServerViewState();
}

class _ImportCortesFromServerViewState extends State<ImportCortesFromServerView> {
  int? selectedRutaId; // ID de la ruta seleccionada (null para "Todas las rutas")

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final rutasService = Provider.of<RutasService>(context, listen: false);
    final rutasSinCortarService = Provider.of<RutasSinCortarService>(context, listen: false);

    try {
      // Cargar todas las rutas para el selector
      await rutasService.loadRutas();
      // Cargar inicialmente todas las rutas sin cortar
      await rutasSinCortarService.loadRutasSinCortar();
    } catch (e) {
      print('Error al cargar los datos iniciales: $e');
    }
  }

  Future<void> _filterRutasSinCortar(int? rutaId) async {
    final rutasSinCortarService = Provider.of<RutasSinCortarService>(context, listen: false);
    await rutasSinCortarService.loadRutasSinCortar(rutaId: rutaId);
  }

  Future<void> _saveRutasToLocal() async {
    final rutasSinCortarService = Provider.of<RutasSinCortarService>(context, listen: false);

    try {
      final prefs = await SharedPreferences.getInstance();
      // Convertir rutas a JSON y guardar
      final rutasJson = jsonEncode(rutasSinCortarService.rutas.map((ruta) => ruta.toJson()).toList());
      await prefs.setString('saved_rutas', rutasJson);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rutas guardadas localmente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al guardar las rutas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar las rutas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final rutasService = Provider.of<RutasService>(context);
    final rutasSinCortarService = Provider.of<RutasSinCortarService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.route, color: Colors.lightBlueAccent),
            SizedBox(width: 8),
            Text('Rutas Sin Cortar', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _saveRutasToLocal, // Guardar rutas localmente
            tooltip: "Grabar rutas",
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: rutasService.isLoading || rutasSinCortarService.isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent),
            )
          : Column(
              children: [
                // Dropdown para seleccionar rutas
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<int?>(
                    dropdownColor: Colors.grey[900],
                    value: selectedRutaId,
                    hint: Text(
                      "Seleccione una ruta",
                      style: TextStyle(color: Colors.white),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Todas las rutas", style: TextStyle(color: Colors.white)),
                      ),
                      ...rutasService.rutas.map((ruta) {
                        return DropdownMenuItem<int?>(
                          value: ruta.bsrutnrut, // ID de la ruta
                          child: Text(
                            ruta.bsrutdesc.trim(),
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRutaId = value; // Actualizar la selección
                      });
                      print(value);
                      _filterRutasSinCortar(value); // Filtrar las rutas sin cortar según la selección
                    },
                  ),
                ),
                // Lista de rutas sin cortar
                Expanded(
                  child: ListView.builder(
                    itemCount: rutasSinCortarService.rutas.length,
                    itemBuilder: (context, index) {
                      final ruta = rutasSinCortarService.rutas[index];

                      return Card(
                        elevation: 4,
                        color: Color.fromARGB(255, 29, 29, 29),
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.lightBlue,
                            child: Icon(Icons.location_on, color: Colors.white),
                          ),
                          title: Text(
                            ruta.dNomb.trim(),
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
                                '📍 Lat: ${ruta.bscntlati}, Lon: ${ruta.bscntlogi}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '💵 Importe Mora: ${ruta.bscocImor}',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '🏠 Dirección: ${ruta.dLotes.trim()}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
