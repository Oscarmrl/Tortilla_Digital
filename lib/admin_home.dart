import 'package:flutter/material.dart';
import 'nuevo_admin.dart'; // Pantalla de inicio administardor

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: Colors.brown,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar recetas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            _adminCard(
              context,
              icon: Icons.restaurant_menu,
              title: 'Ver Recetas',
              subtitle: 'Lista completa de recetas publicadas',
              onTap: () {},
            ),
            _adminCard(
              context,
              icon: Icons.pending_actions,
              title: 'Ver Solicitudes',
              subtitle: 'Recetas enviadas por los usuarios',
              onTap: () {},
            ),
            _adminCard(
              context,
              icon: Icons.add_box,
              title: 'Agregar Receta',
              subtitle: 'Agregar receta manualmente',
              onTap: () {},
            ),
            _adminCard(
              context,
              icon: Icons.person_add,
              title: 'Nuevo Administrador',
              subtitle: 'Registrar un nuevo administrador',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NuevoAdminScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.brown, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
