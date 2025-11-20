import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage("Por favor, completa todos los campos");
      return;
    }
    if (password != confirmPassword) {
      _showMessage("Las contraseñas no coinciden");
      return;
    }

    try {
      setState(() => _loading = true);

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
            'nombre': name,
            'correo': email,
            'uid': userCredential.user!.uid,
            'rol': 'Cliente',
            'fecha_creacion': FieldValue.serverTimestamp(),
          });

      _showMessage("Cuenta creada exitosamente 🎉");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Error al registrar usuario");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 242, 242),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 330,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/tortilla.png'),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Tortilla Digital',
                  style: TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        hint: "Nombre completo",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _emailController,
                        hint: "Correo electrónico",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _passwordController,
                        hint: "Contraseña",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: "Confirmar contraseña",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                              : const Text(
                                  "Registrar",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "¿Ya tienes cuenta?",
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Inicia sesión",
                          style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
