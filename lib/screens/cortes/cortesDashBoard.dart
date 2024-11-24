import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/screens/cortes/ImportCortesFromServer.dart';

class CortesDashboardView extends StatelessWidget {
  const CortesDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard de Cortes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Posiciona los elementos desde la parte superior
          crossAxisAlignment: CrossAxisAlignment.center, // Centra los botones horizontalmente
          children: [
            SizedBox(height: 30), // Espaciado inicial desde la parte superior
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
            SizedBox(height: 16),
            _buildButton(
              context: context,
              text: "Registrar cortes",
              icon: Icons.edit_note,
              color: Colors.greenAccent,
              onPressed: () {
                print("Registrar cortes");
              },
            ),
            SizedBox(height: 16),
            _buildButton(
              context: context,
              text: "Exportar cortes al servidor",
              icon: Icons.cloud_upload,
              color: Colors.orangeAccent,
              onPressed: () {
                print("Exportar cortes al servidor");
              },
            ),
            SizedBox(height: 16),
            _buildButton(
              context: context,
              text: "Lista de cortes realizados",
              icon: Icons.list_alt,
              color: Colors.redAccent,
              onPressed: () {
                print("Lista de cortes realizados");
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
