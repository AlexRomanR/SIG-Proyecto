import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/components/utils/sidebar.dart';


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
      ),
      body: Center(
        child: Column(
   
          crossAxisAlignment: CrossAxisAlignment.center, // Centrar el contenido horizontalmente
          children: [
            Text(
              'Bienvenido a la agenda electrónica del colegio 15 de mayo',
              textAlign: TextAlign.center, // Centrar el texto
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24), // Espacio entre los textos
            Text(
              'Funcionalidades:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildFeatureItem(
              title: 'Revisar información del perfil',
              icon: Icons.person,
            ),
            _buildFeatureItem(
              title: 'Ver las actividades del calendario',
              icon: Icons.calendar_today,
            ),
            _buildFeatureItem(
              title: 'Actividades del curso al que perteneces',
              icon: Icons.school,
            ),
            _buildFeatureItem(
              title: 'Los comunicados del colegio',
              icon: Icons.message,
            ),
            _buildFeatureItem(
              title: 'Las materias que hay',
              icon: Icons.book,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required String title, required IconData icon}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // Aquí puedes agregar la navegación a las respectivas pantallas o funcionalidades
      },
    );
  }
}
