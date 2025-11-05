import 'package:flutter/material.dart';
import 'package:tortilla_digital/register_page.dart';

//Login Page
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7DB88), // Fondo verde claro
      body: Center(
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD966), Color(0xFF9AC17D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),

              // Imagen superior (tortilla)
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/tortilla.png'),
              ),
              const SizedBox(height: 12),

              // Título
              const Text(
                'Bienvenidos!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Contenedor inferior verde oscuro
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF3C814E),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Campo Email
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Correo',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo Password
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Checkbox Remember me
                    Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (_) {},
                          activeColor: const Color(0xFFFFD966),
                        ),
                        const Text(
                          'Recuerdame',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Botón Log In
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F6E41),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Iniciar Sesion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Conectar con redes
                    const Text(
                      'Conestar con:',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 28,
                        ), // Instagram
                        SizedBox(width: 16),
                        Icon(Icons.facebook, color: Colors.white, size: 28),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botón Sign Up
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF89B76F),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
