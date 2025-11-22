import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tortilla_digital/Usuario/recipe_detail_screen.dart';

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
  const MisComidasScreen({this.userId = '', Key? key}) : super(key: key);

  @override
  _MisComidasScreenState createState() => _MisComidasScreenState();
}

class _MisComidasScreenState extends State<MisComidasScreen> {
  late String uidFinal;

  @override
  void initState() {
    super.initState();
    uidFinal = widget.userId.isNotEmpty
        ? widget.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  Future<void> limpiarHistorial() async {
    if (uidFinal.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uidFinal)
        .update({'historial': []});
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialOrdenado() async {
    if (uidFinal.isEmpty) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uidFinal)
        .get();

    if (!snapshot.exists) return [];
    List historial = snapshot.data()?['historial'] ?? [];
    historial.sort((a, b) => (b['fecha'] as Timestamp).compareTo(a['fecha']));
    return historial.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    // Caso: usuario NO autenticado
    if (uidFinal.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xffF7F7F7),
        appBar: AppBar(
          backgroundColor: const Color(0xffFFC727),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Mis Comidas',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            "Debes iniciar sesión para ver tu historial",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    // Caso: usuario autenticado → aquí va el AppBar con el ícono de limpiar historial
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xffFFC727),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mis Comidas',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Limpiar historial",
            icon: const Icon(Icons.delete_outline, color: Colors.black),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Text(
                    "¿Deseas eliminar el historial?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    "Esta acción no se puede deshacer.",
                    style: TextStyle(fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancelar"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFFC727),
                      ),
                      child: const Text(
                        "Eliminar",
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await limpiarHistorial();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Historial eliminado'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          const SizedBox(height: 10),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: obtenerHistorialOrdenado(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xffFFC727)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_food,
                          size: 70,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "No hay recetas aún",
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
                    childAspectRatio: .82,
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
                          return _emptyRecipeCard();
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

                        return _recipeCard(
                          context,
                          imagen,
                          titulo,
                          categoria,
                          rating,
                          tiempo,
                          ingredientes,
                          recetaId,
                          h['fecha'],
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

  Widget _emptyRecipeCard() {
    return Container(
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          "Receta eliminada",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget _recipeCard(
    BuildContext context,
    String img,
    String title,
    String category,
    double rating,
    String time,
    List<String> ingredientes,
    String recetaId,
    Timestamp fecha,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              imagenUrl: img,
              title: title,
              category: category,
              rating: rating,
              time: time,
              ingredientes: ingredientes,
              idReceta: recetaId,
              userId: uidFinal,
              pasos: [],
            ),
          ),
        );
      },
      child: Container(
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                img,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 8),

            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // Fecha
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _formatTimestamp(fecha),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
