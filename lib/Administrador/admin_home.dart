import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_ver_recetas.dart';
import 'nuevo_admin.dart';
import 'admin_ver_solicitudes.dart';
import 'admin_agregar_receta.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  void _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Panel de Administrador",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            _adminCard(
              icon: Icons.restaurant_menu,
              title: 'Ver Recetas',
              subtitle: 'Lista completa de recetas publicadas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminVerRecetas(
                      recetasFiltradas: null,
                      buscarTitulo: '',
                    ),
                  ),
                );
              },
            ),
            _adminCard(
              icon: Icons.pending_actions,
              title: 'Ver Solicitudes',
              subtitle: 'Recetas enviadas por los usuarios',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminVerSolicitudesScreen(),
                  ),
                );
              },
            ),
            _adminCard(
              icon: Icons.add_box,
              title: 'Agregar Receta',
              subtitle: 'Agregar receta manualmente',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAgregarRecetaScreen(),
                  ),
                );
              },
            ),
            _adminCard(
              icon: Icons.person_add,
              title: 'Nuevo Administrador',
              subtitle: 'Registrar un nuevo administrador',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NuevoAdminScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 30, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}
