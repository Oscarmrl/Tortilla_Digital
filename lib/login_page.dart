import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tortilla_digital/Administrador/admin_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tortilla_digital/register_page.dart';
import 'package:tortilla_digital/Usuario/pantallainicio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late FirebaseAuth _auth;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _loadSavedCredentials(); // ⬅️ Cargar usuario guardado
  }

  Future<void> _loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // Usuario canceló

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      _redirectUser(userCredential.user!.uid); // Redirige según Firestore
    } catch (e) {
      _showMessage("Error con Google: $e");
    }
  }

  Future<void> _loginWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final token = result.accessToken!;
        final credential = FacebookAuthProvider.credential(token.token);

        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );

        _redirectUser(userCredential.user!.uid); // Redirige según Firestore
      } else {
        _showMessage("Error en Facebook: ${result.message}");
      }
    } catch (e) {
      _showMessage("Error con Facebook: $e");
    }
  }

  Future<void> _redirectUser(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      _showMessage("No se encontró información del usuario");
      return;
    }

    final rol = userDoc.data()!['rol'];
    final nombre = userDoc.data()?['nombre'] ?? 'Usuario';

    if (rol == 'Admin') {
      Get.offNamed('/adminPage');
    } else {
      Get.off(() => PantallaInicio(nombreUsuario: nombre, userId: ''));
    }
  }

  // -------------------------------------------------------------
  // 🔥 Cargar correo/contraseña guardados
  // -------------------------------------------------------------
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final remember = prefs.getBool('remember_me') ?? false;

    if (remember && savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  // -------------------------------------------------------------
  // 🔥 Guardar o eliminar datos según el checkbox
  // -------------------------------------------------------------
  Future<void> _handleRememberMe(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  // -------------------------------------------------------------
  // 🔥 Tu login original (solo añadí el llamado a guardar datos)
  // -------------------------------------------------------------
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Por favor, completa todos los campos");
      return;
    }

    try {
      setState(() => _loading = true);

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔥 Guardar o borrar datos
      await _handleRememberMe(email, password);

      final uid = userCredential.user!.uid;

      final userDocRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // Backup: buscar por correo
        final query = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('correo', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          _showMessage("No se encontró información del usuario");
          return;
        }

        final data = query.docs.first.data();
        final rol = data['rol'] ?? '';

        if (rol == 'Admin') {
          Get.off(() => const AdminHomeScreen());
        } else {
          Get.off(
            () => PantallaInicio(
              userId: '',
              nombreUsuario: '', // no tenemos uid en este backup
            ),
          );
        }
        return;
      }

      // Documento principal existe
      final data = userDoc.data()!;
      final rol = data['rol'] ?? '';

      if (rol == 'Admin') {
        Get.off(() => const AdminHomeScreen());
      } else {
        // Navegación con paso de parámetro usando Get
        Get.off(() => PantallaInicio(userId: uid, nombreUsuario: ''));
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Error al iniciar sesión";
      if (e.code == 'user-not-found') {
        errorMsg = "Usuario no encontrado";
      } else if (e.code == 'wrong-password') {
        errorMsg = "Contraseña incorrecta";
      } else if (e.code == 'invalid-email') {
        errorMsg = "Correo inválido";
      }
      _showMessage(errorMsg);
    } catch (e) {
      _showMessage("Ocurrió un error: ${e.toString()}");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    Get.snackbar(
      'Aviso',
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7DB88),
      body: Center(
        child: SingleChildScrollView(
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
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/tortilla.png'),
                ),
                const SizedBox(height: 12),
                const Text(
                  '¡Bienvenidos!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
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
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Correo',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                            activeColor: const Color(0xFFFFD966),
                          ),
                          const Text(
                            'Recuérdame',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F6E41),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      const Text(
                        "O continuar con",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: _loginWithGoogle,
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.g_translate,
                                color: Colors.red,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 6),

                      OutlinedButton(
                        onPressed: () => Get.to(() => const RegisterPage()),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          backgroundColor: const Color(0xFF89B76F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                            color: Colors.white,
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
}
