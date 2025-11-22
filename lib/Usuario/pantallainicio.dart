import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tortilla_digital/Usuario/favoritos_screen.dart';
import 'package:tortilla_digital/Usuario/pantalla_configuracion.dart';
import 'package:tortilla_digital/Usuario/pantalla_mis_recetas.dart';
import 'package:tortilla_digital/Usuario/pantalla_tus_comidas.dart';
import 'package:tortilla_digital/login_page.dart';
import 'recipe_detail_screen.dart';

class PantallaInicio extends StatefulWidget {
  final String userId;

  const PantallaInicio({
    super.key,
    required this.userId,
    required nombreUsuario,
  });

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _selectedIndex = 0;

  final String _placeholderImage =
      'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=500';

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  String selectedCategory = "";
  List<String> categories = [
    'Populares',
    'Rápida',
    'Bebidas',
    'Tradicionales',
    'Postres',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("usuarios")
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final nombreUsuario = data["nombre"] ?? "Usuario";
        final imagen =
            data["imagen"] ??
            "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";

        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(imagen),
                          const SizedBox(height: 20),
                          _buildWelcomeText(nombreUsuario),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          const SizedBox(height: 24),
                          _buildCategoryIcons(),
                          const SizedBox(height: 28),
                          _buildRecipes(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomNavigationBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== SECCIONES =====

  Widget _buildHeader(String imagen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(radius: 25, backgroundImage: NetworkImage(imagen)),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(String nombreUsuario) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $nombreUsuario!',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
            children: [
              TextSpan(text: 'Del antojo a la mesa,\nsin salir de '),
              TextSpan(
                text: 'casa',
                style: TextStyle(color: Color(0xFFFFC107)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Busca cualquier receta',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          bool isSelected = selectedCategory == category;
          return GestureDetector(
            onTap: () =>
                setState(() => selectedCategory = isSelected ? "" : category),
            child: _buildCategoryIcon(
              icon: _getIconForCategory(category),
              label: category,
              isSelected: isSelected,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Populares':
        return Icons.local_fire_department;
      case 'Rápida':
        return Icons.local_pizza_outlined;
      case 'Bebidas':
        return Icons.local_cafe_outlined;
      case 'Tradicionales':
        return Icons.restaurant_outlined;
      case 'Postres':
        return Icons.icecream_outlined;
      default:
        return Icons.fastfood;
    }
  }

  Widget _buildRecipes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Recetas')
          .where('esAprovada', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildPlaceholderContent();
        }

        final allRecipes = snapshot.data!.docs;

        final filteredRecipes = allRecipes.where((recipe) {
          final data = recipe.data() as Map<String, dynamic>;
          final titulo = (data['titulo'] ?? '').toString().toLowerCase();
          final categoria = (data['categoria'] ?? '').toString();

          bool matchesSearch =
              titulo.contains(searchQuery) ||
              categoria.toLowerCase().contains(searchQuery);
          bool matchesCategory =
              selectedCategory.isEmpty || categoria == selectedCategory;

          return matchesSearch && matchesCategory;
        }).toList();

        return _buildAllRecipesSection(filteredRecipes);
      },
    );
  }

  Widget _buildAllRecipesSection(List<QueryDocumentSnapshot> recipes) {
    if (recipes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "No se encontraron recetas.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Todas las recetas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recipes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final data = recipes[index].data() as Map<String, dynamic>;
            final docId = recipes[index].id;

            return _buildPlainCard(
              documentId: docId,
              imagenUrl: data['imagenUrl'] ?? _placeholderImage,
              title: data['titulo'] ?? 'Receta',
              category: data['categoria'] ?? 'Sin categoría',
              time: data['tiempo'] ?? '30 mins',
              rating: _parseRating(data['rating']),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlainCard({
    required String documentId,
    required String imagenUrl,
    required String title,
    required String category,
    required String time,
    required double rating,
  }) {
    return GestureDetector(
      onTap: () async {
        final doc = await FirebaseFirestore.instance
            .collection('Recetas')
            .doc(documentId)
            .get();
        final data = doc.data() ?? {};

        final ingredientes = List<String>.from(data['ingredientes'] ?? []);
        final pasos = List<String>.from(data['pasos'] ?? []);

        Get.to(
          () => RecipeDetailScreen(
            imagenUrl: imagenUrl,
            title: title,
            category: category,
            rating: rating,
            time: time,
            ingredientes: ingredientes,
            idReceta: documentId,
            userId: widget.userId,
            pasos: pasos,
          ),
        );
      },
      child: _buildRecipeCard(imagenUrl, title, category, time: time),
    );
  }

  Widget _buildRecipeCard(
    String imagenUrl,
    String title,
    String category, {
    String? time,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imagenUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(category, style: TextStyle(color: Colors.grey[600])),
                if (time != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon({
    required IconData icon,
    required String label,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFC107) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey[600],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            onTap: () => setState(() => _selectedIndex = 0),
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
            icon: Icons.bookmark_outline,
            label: 'Favoritos',
            isSelected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Get.to(() => PantallaFavoritos(userId: widget.userId));
            },
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
    bool isSelected = false,
    bool isAdd = false,
    required VoidCallback onTap,
  }) {
    if (isAdd) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 24,
            ),
            if (isSelected && label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _parseRating(dynamic rating) {
    if (rating == null) return 4.8;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    return double.tryParse(rating.toString()) ?? 4.8;
  }

  Widget _buildPlaceholderContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'No hay recetas disponibles en este momento.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
