import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaInicio extends StatefulWidget {
  final String nombreUsuario;
  const PantallaInicio({super.key, required this.nombreUsuario});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _selectedIndex = 0;

  final String _placeholderImage =
      'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=500';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // Welcome Text
                      _buildWelcomeText(),
                      const SizedBox(height: 24),

                      // Search Bar
                      _buildSearchBar(),
                      const SizedBox(height: 24),

                      // Category Icons
                      _buildCategoryIcons(),
                      const SizedBox(height: 28),

                      // ✅ UN SOLO STREAMBUILDER PARA
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Recetas')
                            .where('esAprovada', isEqualTo: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            // Sin datos: muestra placeholders
                            return _buildPlaceholderContent();
                          }

                          // ✅ DATOS COMPARTIDOS
                          final allRecipes = snapshot.data!.docs;
                          final popularRecipes = allRecipes.take(2).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Popular Recipes (primeras 2)
                              _buildPopularSection(popularRecipes),
                              const SizedBox(height: 20),

                              // All Recipes (todas en grid)
                              _buildAllRecipesSection(allRecipes),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  // ==================== SECCIONES ====================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
        ),
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

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, ${widget.nombreUsuario}!',
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
              TextSpan(text: 'Make your own food,\nstay at '),
              TextSpan(
                text: 'home',
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
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search any recipe',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryIcon(
            icon: Icons.local_fire_department,
            label: 'Popular',
            isSelected: true,
          ),
          _buildCategoryIcon(
            icon: Icons.local_pizza_outlined,
            label: 'Western',
          ),
          _buildCategoryIcon(icon: Icons.local_cafe_outlined, label: 'Drinks'),
          _buildCategoryIcon(icon: Icons.restaurant_outlined, label: 'Local'),
          _buildCategoryIcon(icon: Icons.icecream_outlined, label: 'Dessert'),
        ],
      ),
    );
  }

  // ✅ SECCIÓN POPULAR (recibe datos compartidos)
  Widget _buildPopularSection(List<QueryDocumentSnapshot> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Recipes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final data = recipes[index].data() as Map<String, dynamic>;
              final docId = recipes[index].id;

              return _buildPopularCard(
                documentId: docId,
                imageUrl: data['imageUrl'] ?? _placeholderImage,
                title: data['titulo'] ?? 'Receta',
                category: data['categoria'] ?? 'Sin categoría',
                time: data['tiempo'] ?? '30 mins',
                rating: _parseRating(data['rating']),
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ SECCIÓN ALL RECIPES (recibe datos compartidos)
  Widget _buildAllRecipesSection(List<QueryDocumentSnapshot> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Recipes',
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
              imageUrl: data['imageUrl'] ?? _placeholderImage,
              title: data['titulo'] ?? 'Receta',
              category: data['categoria'] ?? 'Sin categoría',
              time: data['tiempo'] ?? '30 mins',
            );
          },
        ),
      ],
    );
  }

  // Placeholder cuando no hay datos
  Widget _buildPlaceholderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Recipes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(2, (i) {
              return _buildPopularCard(
                documentId: 'placeholder_$i',
                imageUrl: _placeholderImage,
                title: i == 0 ? 'Chicken Curry' : 'Crepes with Orange',
                category: i == 0 ? 'Asian' : 'Western',
                time: i == 0 ? '15 mins' : '35 mins',
                rating: i == 0 ? 4.8 : 4.5,
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'All Recipes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
          children: List.generate(4, (i) {
            return _buildPlainCard(
              documentId: 'placeholder_$i',
              imageUrl: _placeholderImage,
              title: 'Ejemplo ${i + 1}',
              category: 'Categoria',
              time: '30 mins',
            );
          }),
        ),
      ],
    );
  }

  // ==================== TARJETAS ====================

  Widget _buildPopularCard({
    required String documentId,
    required String imageUrl,
    required String title,
    required String category,
    required String time,
    required double rating,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          // Navegar a detalle (pasando solo el ID)
          Get.snackbar(
            'Navegando',
            'ID: $documentId',
            snackPosition: SnackPosition.BOTTOM,
          );
          // Get.to(() => RecipeDetailScreen(recipeId: documentId));
        },
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: 260,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlainCard({
    required String documentId,
    required String imageUrl,
    required String title,
    required String category,
    required String time,
  }) {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          'Navegando',
          'ID: $documentId',
          snackPosition: SnackPosition.BOTTOM,
        );
        // Get.to(() => RecipeDetailScreen(recipeId: documentId));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 14),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
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
              ),
            ),
          ],
        ),
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
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          _buildBottomNavItem(
            icon: Icons.add_circle_outline,
            label: '',
            isAdd: true,
            onTap: () {
              Get.snackbar(
                'Función',
                'Aquí podrás subir una receta (próximamente)',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange.shade100,
              );
            },
          ),
          _buildBottomNavItem(
            icon: Icons.bookmark_outline,
            label: 'Favoritos',
            isSelected: _selectedIndex == 1,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildBottomNavItem(
            icon: Icons.restaurant_menu,
            label: 'Mis comidas',
            isSelected: _selectedIndex == 2,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          _buildBottomNavItem(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            isSelected: _selectedIndex == 3,
            onTap: () => setState(() => _selectedIndex = 3),
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

  // ==================== HELPERS ====================

  double _parseRating(dynamic rating) {
    if (rating == null) return 4.8;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    return double.tryParse(rating.toString()) ?? 4.8;
  }
}
