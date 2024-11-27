import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gestion_asistencia_docente/screens/cortes/prueba.dart';
import 'package:gestion_asistencia_docente/screens/cortes/registroCorteLista.dart';

import 'package:gestion_asistencia_docente/screens/asistencias/asistenciasView.dart';
import 'package:gestion_asistencia_docente/screens/cortes/cortesDashBoard.dart';
import 'package:gestion_asistencia_docente/screens/cortes/cortesRutasLocal.dart';
import 'package:gestion_asistencia_docente/screens/licencias/licenciasView.dart';
import 'package:gestion_asistencia_docente/screens/login/home_screen.dart';
import 'package:gestion_asistencia_docente/screens/login/login_screen.dart';
import 'package:gestion_asistencia_docente/screens/programacion_academica/programacion_academicaView.dart';
import 'package:gestion_asistencia_docente/services/auth/auth_service.dart';
import 'package:provider/provider.dart';

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {

    return Drawer(
      child: Container(
        color: Colors.black, // Fondo negro para el drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: Center(
                  child: Text(
                    'BIENVENIDO A\nOOSIV R.L.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, // Texto blanco
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text(
                'SISTEMAS',
                style: TextStyle(
                  color: const Color.fromARGB(255, 184, 184, 184),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Lectura',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => const ProgramacionAcademicaView()));
              },
            ),
            ListTile(
              title: Text(
                'Cortes',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CortesDashboardView(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(
                'Cortes',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Prueba(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(
                'Rutas guardadas localmente (eliminar luego)',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewSavedRutas(),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(
                'Reconexión',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const LicenciasView(),
                //   ),
                // );
              },
            ),
            ListTile(
              title: Text(
                'Lista Registros',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListaRegistrosScreen(),
                  ),
                );
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
              title: Text(
                'LOGOUT',
                style: TextStyle(
                 color: const Color.fromARGB(255, 184, 184, 184),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Provider.of<AuthService>(context, listen: false).logut();
                print('Presionado cerrar sesión');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
