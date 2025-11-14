import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tortilla_digital/recipe_detail_screen.dart';

String _formatTimestamp(dynamic ts) {
  if (ts == null) return '';
  DateTime dateTime;
  if (ts is Timestamp) {
    dateTime = ts.toDate();
  } else if (ts is DateTime) {
    dateTime = ts;
  } else {
    return ts.toString();
  }
  final two = (int n) => n.toString().padLeft(2, '0');
  return '${two(dateTime.day)}/${two(dateTime.month)}/${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

class MisComidasScreen extends StatefulWidget {
  final String userId;

  /// Opción B: Si no se envía userId, lo toma automático desde FirebaseAuth
  const MisComidasScreen({this.userId = '', Key? key}) : super(key: key);

  @override
  _MisComidasScreenState createState() => _MisComidasScreenState();
}

class _MisComidasScreenState extends State<MisComidasScreen> {
  late String uidFinal;

  @override
  void initState() {
    super.initState();

    // Si userId viene vacío → usar UID automáticamente
    uidFinal = widget.userId.isNotEmpty
        ? widget.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    if (uidFinal.isEmpty) {
      debugPrint("❌ ERROR: No hay usuario autenticado.");
    }
  }

  /// Guarda una receta y limita historial a 10
  Future<void> agregarRecetaAlHistorial(String recetaId) async {
    if (uidFinal.isEmpty) return;

    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uidFinal);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception("Usuario no encontrado en Firestore");
      }

      List historial = snapshot.data()?['historial'] ?? [];

      historial.add({'idReceta': recetaId, 'fecha': Timestamp.now()});

      // Mantener solo los últimos 10
      if (historial.length > 10) historial.removeAt(0);

      transaction.update(userRef, {'historial': historial});
    });

    setState(() {});
  }

  /// metodo limpiar historial
  Future<void> limpiarHistorial() async {
    if (uidFinal.isEmpty) return;

    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uidFinal);

    await userRef.update({'historial': []});

    setState(() {});
  }

  /// Cargar historial ordenado
  Future<List<Map<String, dynamic>>> obtenerHistorialOrdenado() async {
    if (uidFinal.isEmpty) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uidFinal)
        .get();

    if (!snapshot.exists) return [];

    List historial = snapshot.data()?['historial'] ?? [];

    historial.sort(
      (a, b) => (b['fecha'] as Timestamp).compareTo(a['fecha'] as Timestamp),
    );

    return historial.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    // Usuario no logueado
    if (uidFinal.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber,
          title: const Text("Mis Comidas"),
        ),
        body: const Center(
          child: Text(
            "Debes iniciar sesión para ver tu historial",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 233, 233),
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text(
          'Mis Comidas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Botón para probar agregando recetas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                await limpiarHistorial();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Limpiar Historial',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: obtenerHistorialOrdenado(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay historial aún',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final historial = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final h = historial[index];
                    final recetaId = h['idReceta'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Recetas')
                          .doc(recetaId)
                          .get(),
                      builder: (context, snapshotReceta) {
                        if (!snapshotReceta.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshotReceta.data!.exists) {
                          return const Card(
                            child: Center(child: Text("Receta eliminada")),
                          );
                        }

                        final data =
                            snapshotReceta.data!.data() as Map<String, dynamic>;

                        final titulo = data['titulo'] ?? 'Sin título';
                        final imagen = data['imagenUrl'] ?? '';
                        final categoria = data['categoria'] ?? '';
                        final ingredientes = List<String>.from(
                          data['ingredientes'] ?? [],
                        );
                        final rating =
                            double.tryParse(
                              data['calificacion']?.toString() ?? '4.5',
                            ) ??
                            4.5;
                        final tiempo = data['tiempo'] ?? '10 mins';

                        return Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(
                                    imagenUrl: imagen,
                                    title: titulo,
                                    category: categoria,
                                    rating: rating,
                                    time: tiempo,
                                    ingredientes: ingredientes,
                                    idReceta: recetaId,
                                    userId: uidFinal,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                // imagen de la receta
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    imagen,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // título
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // fecha vista
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    _formatTimestamp(h['fecha']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
