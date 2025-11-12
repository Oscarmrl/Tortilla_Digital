import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  return '${two(dateTime.day)}/${two(dateTime.month)}/${dateTime.year} ${two(dateTime.hour)}:${two(dateTime.minute)}';
}

class MisComidasScreen extends StatefulWidget {
  final String userId;

  // Allow a default userId so screen works when route doesn't supply one.
  const MisComidasScreen({this.userId = '', Key? key}) : super(key: key);

  @override
  _MisComidasScreenState createState() => _MisComidasScreenState();
}

class _MisComidasScreenState extends State<MisComidasScreen> {
  /// Agrega una receta al historial y limita a 10 elementos
  Future<void> agregarRecetaAlHistorial(String recetaId) async {
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      // Si el documento no existe, evita error
      if (!snapshot.exists) {
        throw Exception("Usuario no encontrado");
      }

      // Obtener historial actual o lista vacía
      List historial = snapshot.data()?['historial'] ?? [];

      // Agregar nueva receta
      historial.add({'idReceta': recetaId, 'fecha': Timestamp.now()});

      // Limitar a 10 elementos
      if (historial.length > 10) {
        historial.removeAt(0);
      }

      // Actualizar en Firestore
      transaction.update(userRef, {'historial': historial});
    });

    setState(() {}); // Actualiza la UI
  }

  /// Obtiene el historial ordenado por fecha (más reciente primero)
  Future<List<Map<String, dynamic>>> obtenerHistorialOrdenado() async {
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId);
    final snapshot = await userRef.get();

    if (!snapshot.exists) return [];

    List historial = snapshot.data()?['historial'] ?? [];

    historial.sort(
      (a, b) => (b['fecha'] as Timestamp).compareTo(a['fecha'] as Timestamp),
    );

    return historial.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 233, 233),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC107),
        title: const Text(
          'Mis Comidas',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                String recetaId =
                    'receta${DateTime.now().millisecondsSinceEpoch}';
                await agregarRecetaAlHistorial(recetaId);
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
                'Agregar receta al historial',
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
                    final receta = historial[index];
                    final id = receta['idReceta']?.toString() ?? '';
                    final fecha = _formatTimestamp(receta['fecha']);
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: const Color.fromARGB(255, 73, 77, 22),
                      child: InkWell(
                        onTap: () {
                          // Aquí puedes agregar la navegación a los detalles de la receta
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 40,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Receta: ${id.substring(6)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fecha,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
