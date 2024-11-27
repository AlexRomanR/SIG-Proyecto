import 'package:flutter/material.dart';
import 'package:sig_proyecto/components/utils/splash_screen.dart';
import 'package:sig_proyecto/screens/login/home_screen.dart';
import 'package:sig_proyecto/screens/login/login_screen.dart';
import 'package:sig_proyecto/services/api/asistenciasService.dart';
import 'package:sig_proyecto/services/api/licenciasService.dart';
import 'package:sig_proyecto/services/api/programacion_academicaService.dart';
import 'package:sig_proyecto/services/api/rutasService.dart';
import 'package:sig_proyecto/services/api/rutas_sin_cortarService.dart';
import 'package:sig_proyecto/services/auth/auth_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const AppState());
}

class AppState extends StatefulWidget {
  const AppState({super.key});

  @override
  State<AppState> createState() => _AppStateState();
}

class _AppStateState extends State<AppState> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProgramacionAcademicaService()),
        ChangeNotifierProvider(create: (_) => AsistenciasService()),
        ChangeNotifierProvider(create: (_) => LicenciasService()),
        ChangeNotifierProvider(create: (_) => RutasSinCortarService()),
        ChangeNotifierProvider(create: (_) => RutasService()),

        //   ChangeNotifierProvider(create: ( _ ) => VehicleService()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Proyecto SI2',
      initialRoute: 'splash',
      routes: {
        '/': (_) => HomeScreen(),
        'login': (_) => LoginScreen(),
        'splash': (_) => SplashScreen()
      },
      theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: const Color.fromARGB(255, 14, 13, 12),
          appBarTheme: const AppBarTheme(
              elevation: 0, color: Color.fromARGB(255, 0, 0, 0))),
    );
  }
}
