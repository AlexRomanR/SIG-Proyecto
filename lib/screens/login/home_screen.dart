import 'package:flutter/material.dart';
import 'package:sig_proyecto/components/utils/sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideBar(),
      appBar: AppBar(
        title: const Text('Inicio'),
        foregroundColor:
            Color.fromARGB(255, 255, 255, 255), // Color del texto en blanco
      ),
      body: Stack(
        children: [
          // Imagen de fondo
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/utils/grijo.jpg'), // Asegúrate de que la imagen esté en la carpeta assets
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Contenido
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sistema para el corte planificado de servicios públicos\nOOSIV R.L.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        Color.fromARGB(255, 255, 255, 255), // Color del texto
                  ),
                ),
                const SizedBox(height: 500),
                Text(
                  'A través de un sistema electronico fácilitamos el corte y registro de servicios publicos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        // Esto añade un sombreado para el efecto de contorno
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(10, 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
