import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'favoritos_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String imagenUrl;
  final String title;
  final String category;
  final double rating;
  final String time;
  final List<String> ingredientes;
  final String idReceta;
  final String userId;
  final List<String> pasos;

  const RecipeDetailScreen({
    super.key,
    required this.imagenUrl,
    required this.title,
    required this.category,
    required this.rating,
    required this.time,
    required this.ingredientes,
    required this.idReceta,
    required this.userId,
    required this.pasos,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    agregarRecetaAlHistorial();
    cargarFavorito();
  }

  /// Verifica si la receta ya está en favoritos
  Future<void> cargarFavorito() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .get();

    List favs = userDoc.data()?['favoritos'] ?? [];

    setState(() {
      isFavorite = favs.contains(widget.idReceta);
    });
  }

  /// Quitar de favoritos
  Future<void> quitarDeFavoritos() async {
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      List favoritos = snapshot.data()?['favoritos'] ?? [];

      favoritos.remove(widget.idReceta);

      transaction.update(userRef, {'favoritos': favoritos});
    });

    print("❌ Receta eliminada de favoritos");
  }

  /// Guarda receta en historial
  Future<void> agregarRecetaAlHistorial() async {
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) return;

      List historial = snapshot.data()?['historial'] ?? [];

      historial.add({'idReceta': widget.idReceta, 'fecha': Timestamp.now()});

      if (historial.length > 10) historial.removeAt(0);

      transaction.update(userRef, {'historial': historial});
    });
  }

  /// Agregar a favoritos
  Future<void> agregarAFavoritos() async {
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      List favoritos = snapshot.data()?['favoritos'] ?? [];

      if (!favoritos.contains(widget.idReceta)) {
        favoritos.add(widget.idReceta);
      }

      transaction.update(userRef, {'favoritos': favoritos});
    });

    print("✔ Receta agregada a favoritos");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGEN PRINCIPAL
                Stack(
                  children: [
                    Image.network(
                      widget.imagenUrl,
                      height: 400,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // CONTENIDO
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TÍTULO + RATING
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.category,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC107),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.rating.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          /// INGREDIENTES
                          const Text(
                            'Ingredients',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Column(
                            children: widget.ingredientes
                                .map((e) => _buildIngredient(e))
                                .toList(),
                          ),

                          const SizedBox(height: 32),

                          const Text(
                            'Directions',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Column(
                            children: List.generate(
                              widget.pasos.length,
                              (i) => _buildDirection(i + 1, widget.pasos[i]),
                            ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BOTÓN VOLVER
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: _circleButton(Icons.arrow_back_ios_new),
            ),
          ),

          // BOTÓN FAVORITO
          // BOTÓN FAVORITO
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () async {
                setState(() => isFavorite = !isFavorite);

                if (isFavorite) {
                  await agregarAFavoritos();
                } else {
                  await quitarDeFavoritos();
                }
              },
              child: _circleButton(
                isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                color: isFavorite ? const Color(0xFFFFC107) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Widgets auxiliares ----

  Widget _circleButton(IconData icon, {Color color = Colors.black}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }

  Widget _buildIngredient(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDirection(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
