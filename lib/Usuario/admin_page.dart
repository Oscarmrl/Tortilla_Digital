import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _auth = FirebaseAuth.instance;

  // 🔹 Cierra sesión
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7DB88),
      appBar: AppBar(
        title: const Text(
          'Panel de Administración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3C814E),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard(
              icon: Icons.person,
              title: 'Usuarios',
              color: Colors.green.shade700,
              onTap: () {
                // 👉 Aquí abrirás la lista de usuarios
              },
            ),
            _buildAdminCard(
              icon: Icons.shopping_bag,
              title: 'Productos',
              color: Colors.orange.shade700,
              onTap: () {
                // 👉 Aquí abrirás el panel de productos
              },
            ),
            _buildAdminCard(
              icon: Icons.analytics,
              title: 'Reportes',
              color: Colors.blue.shade700,
              onTap: () {
                // 👉 Aquí abrirás las estadísticas o reportes
              },
            ),
            _buildAdminCard(
              icon: Icons.settings,
              title: 'Configuración',
              color: Colors.grey.shade700,
              onTap: () {
                // 👉 Aquí abrirás las configuraciones del sistema
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔸 Widget reutilizable para las tarjetas del panel
  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
