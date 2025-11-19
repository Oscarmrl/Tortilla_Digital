import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController buscarController = TextEditingController();
  final CollectionReference recetasRef = FirebaseFirestore.instance.collection(
    'Recetas',
  );

  void _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _buscarRecetas(BuildContext context) async {
    String texto = buscarController.text.trim();
    if (texto.isEmpty) return;

    QuerySnapshot snapshot = await recetasRef
        .where('esAprovada', isEqualTo: true)
        .get();
    List<QueryDocumentSnapshot> resultados = snapshot.docs.where((doc) {
      String titulo = (doc.data() as Map<String, dynamic>)['titulo'] ?? '';
      return titulo.toLowerCase().contains(texto.toLowerCase());
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminVerRecetas(recetasFiltradas: resultados, buscarTitulo: texto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7DB88),
      appBar: AppBar(
        title: const Text(
          'Panel de Administrador',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3C814E),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: buscarController,
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
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _buscarRecetas(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C814E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Buscar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            _adminCard(
              context,
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
              context,
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
              context,
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
              context,
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
        leading: Icon(
          icon,
          color: const Color.fromARGB(255, 230, 136, 4),
          size: 30,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
