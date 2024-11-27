import 'package:flutter/material.dart';
import 'package:sig_proyecto/screens/login/home_screen.dart';
import 'package:sig_proyecto/screens/login/login_screen.dart';
import 'package:sig_proyecto/services/auth/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthService authService = AuthService(); // Instancia de AuthService

  @override
  void initState() {
    super.initState();
    navigateToNextScreen();
  }

  void navigateToNextScreen() async {
    var duration = const Duration(seconds: 2);
    await Future.delayed(duration);

    // Verificar si el usuario ya ha iniciado sesión
    if (authService.authentificate) {
      // Si el usuario ya ha iniciado sesión, navegar a la pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // Si el usuario no ha iniciado sesión, navegar a la pantalla de inicio de sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image(
          image: AssetImage('assets/utils/splash.png'),
          fit: BoxFit.cover,
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
