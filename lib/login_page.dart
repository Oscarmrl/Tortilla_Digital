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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _loadSavedCredentials();
  }

  // -------------------------------------------------------------
  // 🔥 LOGIN CON GOOGLE
  // -------------------------------------------------------------
  Future<void> _loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final uid = userCredential.user!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'nombre': userCredential.user!.displayName ?? 'Usuario',
          'correo': userCredential.user!.email,
          'rol': 'Cliente',
          'fechaRegistro': FieldValue.serverTimestamp(),
          'metodRegistro': 'Google',
        });
      }

      _redirectUser(uid);
    } catch (e) {
      _showMessage("Error con Google: $e");
    }
  }

  // -------------------------------------------------------------
  // 🔥 LOGIN CON FACEBOOK
  // -------------------------------------------------------------
  Future<void> _loginWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final token = result.accessToken!;
        final credential = FacebookAuthProvider.credential(token.token);

        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );

        final uid = userCredential.user!.uid;

        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
            'nombre': userCredential.user!.displayName ?? 'Usuario',
            'correo': userCredential.user!.email,
            'rol': 'Usuario',
            'fechaRegistro': FieldValue.serverTimestamp(),
            'metodRegistro': 'Facebook',
          });
        }

        _redirectUser(uid);
      } else {
        _showMessage("Error en Facebook: ${result.message}");
      }
    } catch (e) {
      _showMessage("Error con Facebook: $e");
    }
  }

  // -------------------------------------------------------------
  // 🔥 REDIRIGIR SEGÚN ROL - CAMBIADO A Get.offAll()
  // -------------------------------------------------------------
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
      Get.offAll(() => const AdminHomeScreen());
    } else {
      Get.offAll(() => PantallaInicio(nombreUsuario: nombre, userId: uid));
    }
  }

  // -------------------------------------------------------------
  // 🔥 CARGAR CREDENCIALES GUARDADAS
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
  // 🔥 GUARDAR O ELIMINAR DATOS SEGÚN CHECKBOX
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
  // 🔥 LOGIN CON EMAIL Y CONTRASEÑA
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

      await _handleRememberMe(email, password);

      final uid = userCredential.user!.uid;

      final userDocRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
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
          Get.offAll(() => const AdminHomeScreen());
        } else {
          Get.offAll(
            () => PantallaInicio(
              userId: uid,
              nombreUsuario: data['nombre'] ?? 'Usuario',
            ),
          );
        }
        return;
      }

      final data = userDoc.data()!;
      final rol = data['rol'] ?? '';

      if (rol == 'Admin') {
        Get.offAll(() => const AdminHomeScreen());
      } else {
        Get.offAll(
          () => PantallaInicio(
            userId: uid,
            nombreUsuario: data['nombre'] ?? 'Usuario',
          ),
        );
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo y título
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFC107).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/tortilla.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '¡Bienvenido de vuelta!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Campo de correo
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFC107),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Campo de contraseña
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFC107),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                            activeColor: const Color(0xFFFFC107),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recuérdame',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Color(0xFFFFC107),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: const Color(0xFFFFC107).withOpacity(0.3),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'O continuar con',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        label: 'Google',
                        onTap: _loginWithGoogle,
                        color: Colors.red,
                        image: Image.asset(
                          'assets/google.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                        label: 'Facebook',
                        onTap: _loginWithFacebook,
                        color: Colors.blue[800]!,
                        icon: Icons.facebook,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Get.to(() => const RegisterPage()),
                        child: const Text(
                          'Regístrate',
                          style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 🔥 BOTÓN SOCIAL COMPATIBLE CON IMAGEN PNG
  // -------------------------------------------------------------
  Widget _buildSocialButton({
    IconData? icon,
    Image? image,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null) image,
            if (icon != null) Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
