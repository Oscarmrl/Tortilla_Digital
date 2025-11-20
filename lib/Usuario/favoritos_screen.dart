import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tortilla_digital/Usuario/pantalla_configuracion.dart';
import 'package:tortilla_digital/Usuario/pantalla_tus_comidas.dart';
import 'package:tortilla_digital/Usuario/pantalla_mis_recetas.dart';
import 'recipe_detail_screen.dart';

class PantallaFavoritos extends StatefulWidget {
  final String userId;

  const PantallaFavoritos({super.key, required this.userId});

  @override
  State<PantallaFavoritos> createState() => _PantallaFavoritosState();
}

class _PantallaFavoritosState extends State<PantallaFavoritos> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  int _selectedIndex = 1; // ⭐ FAVORITOS ES LA PESTAÑA ACTIVA

  final String _placeholderImage =
      "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=500";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: _buildBottomNavigationBar(),

      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, snapshotUser) {
            if (!snapshotUser.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshotUser.data!.data() as Map<String, dynamic>?;

            if (userData == null ||
                userData['favoritos'] == null ||
                userData['favoritos'].isEmpty) {
              return _buildEmptyStateWithHeader();
            }

            List favoritos = List<String>.from(userData['favoritos']);

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection("Recetas")
                  .where(FieldPath.documentId, whereIn: favoritos)
                  .get(),
              builder: (context, recipeSnapshot) {
                if (!recipeSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final recetas = recipeSnapshot.data!.docs;

                /// FILTRAR BUSQUEDA
                final filtered = recetas.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['titulo'] ?? '').toLowerCase();
                  return title.contains(searchQuery.toLowerCase());
                }).toList();

                return _buildContent(filtered);
              },
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // --------------------- INTERFAZ COMPLETA ------------------
  // =========================================================

  Widget _buildContent(List<QueryDocumentSnapshot> favorites) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderTop(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildFavoriteGrid(favorites),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ---------------- CABECERA SUPERIOR ----------------
  Widget _buildHeaderTop() {
    return Column(
      children: [
        Stack(
          children: [
            Image.network(
              "https://images.unsplash.com/photo-1490645935967-10de6ba17061",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        const Text(
          "Del antojo a la mesa sin salir de casa",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ---------------- Buscador ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Buscar en favoritos...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- GRID ----------------
  Widget _buildFavoriteGrid(List<QueryDocumentSnapshot> recetas) {
    if (recetas.isEmpty) {
      return _buildEmptyStateWithHeader();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recetas.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final data = recetas[index].data() as Map<String, dynamic>;
          final id = recetas[index].id;

          return GestureDetector(
            onTap: () async {
              final doc = await FirebaseFirestore.instance
                  .collection('Recetas')
                  .doc(id)
                  .get();

              final receta = doc.data() ?? {};
              final ingredientes = List<String>.from(
                receta['ingredientes'] ?? [],
              );
              final pasos = List<String>.from(receta['pasos'] ?? []);

              Get.to(
                () => RecipeDetailScreen(
                  imagenUrl: receta['imagenUrl'] ?? _placeholderImage,
                  title: receta['titulo'] ?? "Sin título",
                  category: receta['categoria'] ?? "",
                  rating: _parseRating(receta['rating']),
                  time: receta['tiempo'] ?? "",
                  ingredientes: ingredientes,
                  pasos: pasos,
                  idReceta: id,
                  userId: widget.userId,
                ),
              );
            },
            child: _buildRecipeCard(
              data['imagenUrl'] ?? _placeholderImage,
              data['titulo'] ?? "Receta",
              data['categoria'] ?? "",
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(String img, String title, String category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              img,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(category, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------ BOTTOM NAVIGATION ------------------------------
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBottomNavItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Get.back(); // vuelve a la pantalla anterior (Home)
            },
          ),

          _buildBottomNavItem(
            icon: Icons.add_circle_outline,
            label: 'Mi receta',
            isSelected: _selectedIndex == 4,
            onTap: () {
              setState(() => _selectedIndex = 4);
              Get.to(() => const PantallaMisRecetas());
            },
          ),

          _buildBottomNavItem(
            icon: Icons.bookmark,
            label: 'Favoritos',
            isSelected: _selectedIndex == 1,
            onTap: () {},
          ),

          _buildBottomNavItem(
            icon: Icons.restaurant_menu,
            label: 'Mis comidas',
            isSelected: _selectedIndex == 2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              Get.to(() => MisComidasScreen(userId: widget.userId));
            },
          ),

          _buildBottomNavItem(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            isSelected: _selectedIndex == 3,
            onTap: () {
              setState(() => _selectedIndex = 3);
              Get.to(() => PantallaConfiguracion(userId: widget.userId));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.orange : Colors.black,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithHeader() {
    return Column(
      children: [
        _buildHeaderTop(),
        const SizedBox(height: 40),
        const Text(
          "No tienes recetas favoritas aún",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  double _parseRating(dynamic rating) {
    if (rating == null) return 4.8;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    return double.tryParse(rating.toString()) ?? 4.8;
  }
}
