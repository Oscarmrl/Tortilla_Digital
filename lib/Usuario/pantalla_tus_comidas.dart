import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Helper to format Timestamps without adding a new package
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
      appBar: AppBar(title: const Text('Mis Comidas')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              // Simula agregar una receta con ID aleatorio
              String recetaId =
                  'receta${DateTime.now().millisecondsSinceEpoch}';
              await agregarRecetaAlHistorial(recetaId);
            },
            child: const Text('Agregar receta al historial'),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: obtenerHistorialOrdenado(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay historial aún.'));
                }

                final historial = snapshot.data!;
                return ListView.builder(
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final receta = historial[index];
                    final id = receta['idReceta']?.toString() ?? '';
                    final fecha = _formatTimestamp(receta['fecha']);
                    return ListTile(
                      title: Text('Receta: $id'),
                      subtitle: Text('Vista: $fecha'),
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
