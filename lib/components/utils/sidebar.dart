import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gestion_asistencia_docente/screens/login/home_screen.dart';
import 'package:gestion_asistencia_docente/screens/login/login_screen.dart';
import 'package:gestion_asistencia_docente/services/auth/auth_service.dart';
import 'package:provider/provider.dart';


class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;



    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name),
            accountEmail: Text(user.email),
            // currentAccountPicture: CircleAvatar(
            //   child: ClipOval(
            //     child: Image.network(
            //       imageUrl,
            //       width: 90,
            //       height: 90,
            //       fit: BoxFit.cover,
            //       errorBuilder: (context, error, stackTrace) {
            //         print('Error al cargar la imagen: $error');
            //         return Icon(Icons
            //             .error); // Muestra un ícono de error en caso de fallo
            //       },
            //     ),
            //   ),
            // ),
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/utils/sidebar_fondo.jpg'),
                    fit: BoxFit.cover)),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text(
              'Inicio',
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HomeScreen()));
            },
          ),

 
 


          const Divider(
            thickness: 3,
            indent: 15,
            endIndent: 15,
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.black),
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
    );
  }
}
