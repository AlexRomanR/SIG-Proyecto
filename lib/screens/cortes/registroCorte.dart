import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:sig_proyecto/screens/login/home_screen.dart';
import 'package:sig_proyecto/models/registro_corte.dart';
import 'package:shared_preferences/shared_preferences.dart';

class registroCorte extends StatefulWidget {
  final RutasSinCortar ruta;

  const registroCorte({Key? key, required this.ruta}) : super(key: key);

  @override
  _RegistroCorteScreenState createState() => _RegistroCorteScreenState();
}

class _RegistroCorteScreenState extends State<registroCorte> {
  final TextEditingController _valorMedidorController = TextEditingController();

  void _guardarRegistro() async {
    final valorMedidor = _valorMedidorController.text.isEmpty
        ? '-1' // Si el campo está vacío, asigna '-1'
        : _valorMedidorController.text;

    final nuevoRegistro = RegistroCorte(
      codigoUbicacion: widget.ruta.bscocNcoc,
      usuarioRelacionado: widget.ruta.bscocNcnt,
      codigoFijo: widget.ruta.bscntCodf,
      nombre: widget.ruta.dNomb,
      medidorSerie: widget.ruta.bsmednser,
      numeroMedidor: widget.ruta.bsmedNume,
      valorMedidor: valorMedidor,
      fechaCorte: DateTime.now(),
    );

    try {
      // Obtener instancia de SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Recuperar registros previos, si existen
      final registrosJson = prefs.getString('registros_corte') ?? '[]';
      final List<dynamic> registrosPrevios = jsonDecode(registrosJson);

      // Añadir nuevo registro a la lista
      registrosPrevios.add(nuevoRegistro.toMap());

      // Guardar la lista actualizada en memoria
      await prefs.setString('registros_corte', jsonEncode(registrosPrevios));


    // **Guardar el punto como cortado**
    List<String> puntosCortados = prefs.getStringList('puntos_cortados') ?? [];
    String codigoUbicacionStr = widget.ruta.bscocNcoc.toString();
    if (!puntosCortados.contains(codigoUbicacionStr)) {
      puntosCortados.add(codigoUbicacionStr);
      await prefs.setStringList('puntos_cortados', puntosCortados);
    }

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Registro guardado exitosamente!'),
        backgroundColor: Colors.green,
      ),
    );

      // Limpiar el controlador de texto
      setState(() {
        _valorMedidorController.clear();
      });
    } catch (e) {
      print('Error al guardar el registro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el registro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _irAlPlano() {
    // Navegar a la pantalla del plano
    Navigator.pop(context);
  }

  void _irMenuPrincipal() {
    // Navegar al menú principal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Corte',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la ruta
            Text(
              'Información de la Ruta:',
              style: TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '📍 Nombre: ${widget.ruta.dNomb}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '🔢 Código de Ubicación: ${widget.ruta.bscocNcoc}',
              style: TextStyle(color: Colors.greenAccent, fontSize: 16),
            ),
            Text(
              '🧾 Código Fijo: ${widget.ruta.bscntCodf}',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 16),
            ),
            Text(
              '📄 Medidor Serie: ${widget.ruta.bsmednser}',
              style: TextStyle(color: Colors.lightBlueAccent, fontSize: 16),
            ),
            Text(
              '🔢 Número de Medidor: ${widget.ruta.bsmedNume}',
              style: TextStyle(color: Colors.yellowAccent, fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Registrar corte
            Text(
              'Digite Lectura:',
              style: TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _valorMedidorController,
              decoration: InputDecoration(
                labelText: 'Valor del Medidor',
                labelStyle: TextStyle(color: Colors.white),
                hintText: 'Ingrese el valor del medidor',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlueAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Botón para guardar
            Center(
              child: ElevatedButton.icon(
                onPressed: _guardarRegistro,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Corte'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _irAlPlano,
                icon: const Icon(Icons.map),
                label: const Text('Ir al Plando'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Colors.blueAccent.shade700,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _irMenuPrincipal,
                icon: const Icon(Icons.backspace),
                label: const Text('Menú Principal'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Colors.redAccent.shade400,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
