import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sig_proyecto/models/rutas_sin_cortar.dart';
import 'package:sig_proyecto/screens/login/home_screen.dart';
import 'package:sig_proyecto/models/registro_corte.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Importar image_picker

class registroCorte extends StatefulWidget {
  final RutasSinCortar ruta;

  const registroCorte({Key? key, required this.ruta}) : super(key: key);

  @override
  _RegistroCorteScreenState createState() => _RegistroCorteScreenState();
}

class _RegistroCorteScreenState extends State<registroCorte> {
  final TextEditingController _textController = TextEditingController();
  String _selectedOption = 'Ninguna'; // Default value
  String? _fotoBase64; // Variable para guardar la foto en base64
  File? _fotoFile; // Para mostrar la foto antes de guardarla

  Future<void> _tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      setState(() {
        _fotoBase64 = base64Encode(bytes);
        _fotoFile = File(foto.path);
      });
    }
  }

  void _guardarRegistro() async {
    final String? valorMedidor =
        _selectedOption == 'Ninguna' ? _textController.text : null;
    final String? observacion =
        _selectedOption == 'Observacion' ? _textController.text : null;

    final nuevoRegistro = RegistroCorte(
      codigoUbicacion: widget.ruta.bscocNcoc,
      usuarioRelacionado: widget.ruta.bscocNcnt,
      codigoFijo: widget.ruta.bscntCodf,
      nombre: widget.ruta.dNomb,
      medidorSerie: widget.ruta.bsmednser,
      numeroMedidor: widget.ruta.bsmedNume,
      valorMedidor: valorMedidor,
      observacion: observacion,
      fechaCorte: DateTime.now(),
      fotoBase64: _fotoBase64, // Guardamos la foto
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
    
      List<String> puntosCortados = prefs.getStringList('puntos_cortados') ?? [];
      // **Guardar el punto como cortado**
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
      setState(() {});
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
    // Navegar a la pantalla del plano y forzar recarga
    Navigator.pop(context, true);
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
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Colors.white), // Botón blanco
          onPressed: () {
            _irAlPlano(); // Llama a tu lógica personalizada
          },
        ),
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
        child: ListView(
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
            if (_fotoFile != null) ...[
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      '📷 Foto', // Emoji que representa una foto
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center, // Centra el texto
                    ),
                    const SizedBox(
                        height: 10), // Espaciado entre el texto y la imagen
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _fotoFile !=
                              null // Verifica nuevamente antes de usar el operador `!`
                          ? Image.file(_fotoFile!, fit: BoxFit.cover)
                          : const SizedBox
                              .shrink(), // Placeholder si no hay imagen
                    ),
                  ],
                ),
              ),
            ],
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
            DropdownButton<String>(
              value: _selectedOption,
              dropdownColor: Colors.black87,
              style: TextStyle(color: Colors.white),
              items: ['Ninguna', 'Observacion'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOption = newValue!;
                  _textController.clear();
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: _selectedOption == 'Ninguna'
                    ? 'Valor del Medidor'
                    : 'Observación',
                labelStyle: TextStyle(color: Colors.white),
                hintText: _selectedOption == 'Ninguna'
                    ? 'Ingrese el valor del medidor'
                    : 'Ingrese la observación',
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
            // Botón para tomar foto
            Center(
              child: ElevatedButton.icon(
                onPressed: _tomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tomar Foto'),
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
                onPressed: _irAlPlano,
                icon: const Icon(Icons.map),
                label: const Text('Volver al plano'),
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
