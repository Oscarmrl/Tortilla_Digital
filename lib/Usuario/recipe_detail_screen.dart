import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String imagenUrl;
  final String title;
  final String category;
  final double rating;
  final String time;
  final List<String> ingredientes;
  final List<String> pasos; // ✅ Agregado a la clase
  final String idReceta;
  final String userId;

  const RecipeDetailScreen({
    super.key,
    required this.imagenUrl,
    required this.title,
    required this.category,
    required this.rating,
    required this.time,
    required this.ingredientes,
    required this.pasos, // ✅ Ahora es parte de la clase
    required this.idReceta,
    required this.userId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Agregar receta visitada al historial
    agregarRecetaAlHistorial();
  }

  /// Guarda automáticamente la receta visitada en Firestore
  Future<void> agregarRecetaAlHistorial() async {
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        print("❌ Usuario no existe.");
        return;
      }

      List historial = snapshot.data()?['historial'] ?? [];

      historial.add({'idReceta': widget.idReceta, 'fecha': Timestamp.now()});

      // Limitar historial a 10
      if (historial.length > 10) historial.removeAt(0);

      transaction.update(userRef, {'historial': historial});
    });

    print("✔ Receta añadida al historial exitosamente");
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
                          // TÍTULO + RATING
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

                          // INFO CARDS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoCard(
                                icon: Icons.access_time,
                                value: widget.time.split(' ')[0],
                                label: 'mins',
                              ),
                              _buildInfoCard(
                                icon: Icons.local_fire_department_outlined,
                                value: '103',
                                label: 'Cal',
                              ),
                              _buildInfoCard(
                                icon: Icons.layers_outlined,
                                value: 'Easy',
                                label: 'Dific',
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // INGREDIENTES
                          const Text(
                            'Ingredientes',
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

                          // DIRECCIONES / PASOS
                          const Text(
                            'Pasos',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ✅ AQUÍ USAMOS LOS PASOS DINÁMICOS
                          ...widget.pasos.asMap().entries.map((entry) {
                            int index = entry.key;
                            String paso = entry.value;
                            return _buildDirection(index + 1, paso);
                          }).toList(),

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

          // FAVORITO
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () => setState(() => isFavorite = !isFavorite),
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

  /// === Widgets auxiliares ===

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

  Widget _buildInfoCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      width: 75,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC107), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (label.isNotEmpty)
            Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
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
