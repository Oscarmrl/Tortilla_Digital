import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Pantallas
import 'package:tortilla_digital/login_page.dart';
import 'package:tortilla_digital/register_page.dart';
import 'package:tortilla_digital/Usuario/pantallainicio.dart';
import 'package:tortilla_digital/Administrador/admin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tortilla Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orangeAccent,
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/register', page: () => const RegisterPage()),
        GetPage(
          name: '/home',
          page: () => const PantallaInicio(nombreUsuario: '', userId: ''),
        ),
        GetPage(name: '/adminPage', page: () => AdminPage()), // ❌ No const
      ],
    );
  }
}
