import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sig_proyecto/screens/cortes/cortesRutasLocalSinOrden.dart';
import 'package:sig_proyecto/screens/cortes/registroCorteLista.dart';
import 'package:sig_proyecto/screens/cortes/registroCorteLista.dart';

import 'package:sig_proyecto/screens/asistencias/asistenciasView.dart';
import 'package:sig_proyecto/screens/cortes/cortesDashBoard.dart';
import 'package:sig_proyecto/screens/cortes/cortesRutasLocal.dart';
import 'package:sig_proyecto/screens/licencias/licenciasView.dart';
import 'package:sig_proyecto/screens/login/home_screen.dart';
import 'package:sig_proyecto/screens/login/login_screen.dart';
import 'package:sig_proyecto/screens/programacion_academica/programacion_academicaView.dart';
import 'package:sig_proyecto/services/auth/auth_service.dart';
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
                    'BIENVENIDO A\nCOOSIV R.L.',
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
            // ListTile(
            //   title: Text(
            //     'Lista para cortes',
            //     style: TextStyle(color: Colors.white),
            //   ),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => ViewSavedRutasSinOrden(),
            //       ),
            //     );
            //   },
            // ),
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
