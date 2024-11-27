import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewSavedRutas extends StatelessWidget {
  const ViewSavedRutas({super.key});

  Future<List<RutasSinCortar>> _loadSavedRutas() async {
    final prefs = await SharedPreferences.getInstance();
    final rutasJson = prefs.getString('saved_rutas');

    if (rutasJson != null) {
      try {
        final List<dynamic> rutasList = jsonDecode(rutasJson);

        // Convertir los datos de manera segura
        final rutas = rutasList.map((ruta) {
          return RutasSinCortar(
            bscocNcoc:
                int.parse(ruta['bscocNcoc'].toString()), // Convertir a int
            bscntCodf:
                int.parse(ruta['bscntCodf'].toString()), // Convertir a int
            bscocNcnt:
                int.parse(ruta['bscocNcnt'].toString()), // Convertir a int
            dNomb: ruta['dNomb'] ?? '', // Manejar nulos
            bscocNmor:
                int.parse(ruta['bscocNmor'].toString()), // Convertir a int
            bscocImor: double.parse(
                ruta['bscocImor'].toString()), // Convertir a double
            bsmednser: ruta['bsmednser'] ?? '', // Manejar nulos
            bsmedNume: ruta['bsmedNume'] ?? '', // Manejar nulos
            bscntlati: double.parse(
                ruta['bscntlati'].toString()), // Convertir a double
            bscntlogi: double.parse(
                ruta['bscntlogi'].toString()), // Convertir a double
            dNcat: ruta['dNcat'] ?? '', // Manejar nulos
            dCobc: ruta['dCobc'] ?? '', // Manejar nulos
            dLotes: ruta['dLotes'] ?? '', // Manejar nulos
          );
        }).toList();

        print('Datos cargados correctamente: $rutas');
        return rutas;
      } catch (e) {
        print('Error al deserializar las rutas guardadas: $e');
        return [];
      }
    }

    print('No se encontraron rutas guardadas');
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rutas Guardadas'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<RutasSinCortar>>(
        future: _loadSavedRutas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator(color: Colors.lightBlueAccent));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar rutas guardadas',
                    style: TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No hay rutas guardadas',
                    style: TextStyle(color: Colors.white)));
          }

          final rutas = snapshot.data!;
          return ListView.builder(
            itemCount: rutas.length,
            itemBuilder: (context, index) {
              final ruta = rutas[index];
              return ListTile(
                title: Text(
                  ruta.dNomb.trim(),
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💵 Importe Mora: ${ruta.bscocImor}',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                    Text(
                      '📍 Latitud: ${ruta.bscntlati}, Longitud: ${ruta.bscntlogi}',
                      style: TextStyle(color: Colors.lightBlueAccent),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
