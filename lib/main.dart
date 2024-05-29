import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/components/utils/splash_screen.dart';
import 'package:gestion_asistencia_docente/screens/login/home_screen.dart';
import 'package:gestion_asistencia_docente/screens/login/login_screen.dart';
import 'package:gestion_asistencia_docente/services/auth/auth_service.dart';
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
  Widget build(BuildContext   context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ( _ ) => AuthService()),

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
      '/':  ( _ ) =>HomeScreen(),
      'login':  ( _ ) =>LoginScreen(),
      'splash':  ( _ ) =>SplashScreen()
     },
     theme: ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.orange[50],
      appBarTheme: const AppBarTheme(
        elevation: 0,
        color: Colors.red
      )
     ),
     
    );
  }


}



