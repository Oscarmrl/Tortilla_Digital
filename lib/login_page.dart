import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tortilla_digital/Administrador/admin_home.dart';
import 'package:tortilla_digital/register_page.dart';
import 'package:tortilla_digital/Usuario/pantallainicio.dart';

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
    _checkAutoLogin();
    _loadSavedCredentials();
  }

  // ---------------- AUTO LOGIN ----------------
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool('is_logged_in') ?? false;

    if (!isLogged) return;

    final uid = prefs.getString('user_id');
    if (uid == null || uid.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!userDoc.exists) return;

      final rol = userDoc.data()?['rol'];
      if (rol == 'Admin') {
        Get.off(() => const AdminHomeScreen());
      } else {
        Get.off(() => PantallaInicio(userId: uid, nombreUsuario: ''));
      }
    } catch (_) {
      // si hay error no hacer nada
    }
  }

  // ---------------- GOOGLE LOGIN ----------------
  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _loading = true);
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // cancelado

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final uid = userCredential.user!.uid;
      await _saveLoginInfo(uid); // guarda sesión
      await _ensureUserDocExists(uid, userCredential.user);

      _redirectUser(uid);
    } catch (e) {
      _showMessage("Error con Google: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // helper: si quieres crear doc de usuario en Firestore si no existe (opcional)
  Future<void> _ensureUserDocExists(String uid, User? user) async {
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'nombre': user.displayName ?? '',
        'correo': user.email ?? '',
        'imagen': user.photoURL ?? '',
        'rol': 'Usuario',
        'favoritos': [],
        'historial': [],
        'fecha_creacion': FieldValue.serverTimestamp(),
      });
    }
  }

  // ---------------- REDIRECCION SEGÚN ROL ----------------
  Future<void> _redirectUser(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        _showMessage("No se encontró información del usuario");
        return;
      }

      final data = userDoc.data()!;
      final rol = data['rol'];
      final nombre = data['nombre'] ?? "Usuario";

      if (rol == "Admin") {
        Get.off(() => const AdminHomeScreen());
      } else {
        Get.off(() => PantallaInicio(userId: uid, nombreUsuario: nombre));
      }
    } catch (e) {
      _showMessage("Error al obtener usuario: $e");
    }
  }

  // ---------------- CARGAR CREDENCIALES GUARDADAS ----------------
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') ?? false) {
      _emailController.text = prefs.getString('saved_email') ?? "";
      _passwordController.text = prefs.getString('saved_password') ?? "";
      setState(() => _rememberMe = true);
    }
  }

  // ---------------- GUARDAR "RECUÉRDAME" ----------------
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

  Future<void> _saveLoginInfo(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_id', uid);
  }

  // ---------------- LOGIN CON EMAIL/PASSWORD ----------------
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Por favor, completa todos los campos");
      return;
    }

    try {
      setState(() => _loading = true);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Guardar datos según checkbox
      await _handleRememberMe(email, password);
      if (_rememberMe) {
        await _saveLoginInfo(uid);
      } else {
        // Si no quiere recordar, aseguramos limpiar is_logged_in
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('user_id');
      }

      // redirigir por rol
      _redirectUser(uid);
    } on FirebaseAuthException catch (e) {
      String msg = "Error al iniciar sesión";
      if (e.code == "user-not-found") msg = "Usuario no encontrado";
      if (e.code == "wrong-password") msg = "Contraseña incorrecta";
      if (e.code == "invalid-email") msg = "Correo inválido";
      _showMessage(msg);
    } catch (e) {
      _showMessage("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------- ALERTA ----------------
  void _showMessage(String message) {
    Get.snackbar(
      "Aviso",
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ---------------- UI: Diseño según imagen ----------------
  @override
  Widget build(BuildContext context) {
    // Paleta basada en la imagen
    const Color pageBg = Color.fromARGB(255, 255, 254, 254); // crema claro
    const Color accentPeach = Color(0xFFFFC107); // botón durazno
    const Color inputBorder = Color(0xFFDDD6C8);
    const Color smallText = Color(0xFFB58F6A);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // pequeño back arrow (como en la imagen)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Logo + texto
                Column(
                  children: [
                    // logo asset
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/tortilla.png'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tortilla Digital',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bienvenido de nuevo.',
                      style: TextStyle(color: smallText, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Card estilo minimalista con inputs y botón
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Usuario
                      _styledInput(
                        controller: _emailController,
                        hint: 'Correo',
                        icon: Icons.person_outline,
                        borderColor: inputBorder,
                      ),
                      const SizedBox(height: 12),

                      // Contraseña
                      _styledInput(
                        controller: _passwordController,
                        hint: 'Contraseña',
                        icon: Icons.lock_outline,
                        obscure: true,
                        borderColor: inputBorder,
                      ),

                      const SizedBox(height: 10),

                      // Recuerdame y olvide?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                                activeColor: accentPeach,
                              ),
                              const Text('Recuérdame'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // placeholder: podrías implementar recuperación
                              _showMessage(
                                "Funcionalidad de recuperar contraseña",
                              );
                            },
                            child: const Text(
                              'Olvidé contraseña',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Botón Login
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentPeach,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Center(
                        child: Text(
                          'O continuar con',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Botones sociales (Apple + Google) — estilo redondo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 18),

                          // Google (funcional)
                          InkWell(
                            onTap: _loginWithGoogle,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: inputBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/google_icon.png',
                                width: 20,
                                height: 20,
                                // Si no tienes el asset, puedes usar Icon(Icons.g_translate)
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.g_translate,
                                      color: Colors.red,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Registrar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(color: Colors.black87),
                          ),
                          TextButton(
                            onPressed: () => Get.to(() => const RegisterPage()),
                            child: Text(
                              'Registrarse',
                              style: TextStyle(
                                color: accentPeach,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Pie decorativo (ondas) — simple barra con color
                Container(
                  height: 60,
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: const BoxDecoration(color: Color(0x00FFFFFF)),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 24,
                      width: 160,
                      decoration: BoxDecoration(
                        color: accentPeach.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para inputs con bordes como en la imagen
  Widget _styledInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Color borderColor = Colors.grey,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.black54),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
