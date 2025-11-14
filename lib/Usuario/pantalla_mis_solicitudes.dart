import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaMisSolicitudes extends StatelessWidget {
  const PantallaMisSolicitudes({super.key});

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    final date = (ts as Timestamp).toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Debes iniciar sesión.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis solicitudes de recetas"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("SolicitudReceta")
            .where("solicitadaPor", isEqualTo: user.uid)
            .orderBy("fechaCreacion", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Aún no has enviado recetas.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final receta = docs[index];
              final data = receta.data() as Map<String, dynamic>;

              final titulo = data["titulo"] ?? "Sin título";
              final imagen = data["imagen"] ?? "";
              final fecha = _formatTimestamp(data["fechaCreacion"]);
              final estado = data["estado"] ?? false; // true = aprobado

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: imagen.isNotEmpty
                        ? Image.network(
                            imagen,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.image, color: Colors.grey[700]),
                          ),
                  ),
                  title: Text(titulo),
                  subtitle: Text("Enviado: $fecha"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estado ? Colors.green[600] : Colors.orange[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estado ? "Aprobada" : "En revisión",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  onTap: () {
                    // Aquí puedes abrir una pantalla con más detalles si quieres
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
