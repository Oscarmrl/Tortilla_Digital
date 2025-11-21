import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Pantallas
import 'package:tortilla_digital/login_page.dart';
import 'package:tortilla_digital/register_page.dart';
import 'package:tortilla_digital/Usuario/pantallainicio.dart';
import 'package:tortilla_digital/Administrador/admin_page.dart';
import 'package:tortilla_digital/Administrador/admin_home.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC107),
          brightness: Brightness.light,
        ),
        primaryColor: const Color(0xFFFFC107),
      ),
      // 🔥 CAMBIADO: Ahora inicia con AuthWrapper en lugar de login
      home: const AuthWrapper(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/register', page: () => const RegisterPage()),
        GetPage(
          name: '/home',
          page: () => const PantallaInicio(userId: '', nombreUsuario: ''),
        ),
        GetPage(name: '/adminPage', page: () => AdminPage()),
      ],
    );
  }
}

// ============================================================
// 🔥 AUTH WRAPPER - Verifica si hay sesión activa
// ============================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras carga, muestra splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Si hay un usuario autenticado
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final rol = userData['rol'] ?? '';
                final nombre = userData['nombre'] ?? 'Usuario';

                // Redirigir según el rol
                if (rol == 'Admin') {
                  return const AdminHomeScreen();
                } else {
                  return PantallaInicio(
                    userId: snapshot.data!.uid,
                    nombreUsuario: nombre,
                  );
                }
              }

              // Si no hay datos del usuario en Firestore, ir al login
              return const LoginPage();
            },
          );
        }

        // Si no hay usuario autenticado, mostrar login
        return const LoginPage();
      },
    );
  }
}

// ============================================================
// 🔥 SPLASH SCREEN - Pantalla de carga elegante
// ============================================================
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/tortilla.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.restaurant,
                      size: 60,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tortilla Digital',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Del antojo a la mesa',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFFFFC107),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
