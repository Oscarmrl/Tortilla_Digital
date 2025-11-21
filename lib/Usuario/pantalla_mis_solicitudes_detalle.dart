import 'package:flutter/material.dart';

class PantallaMisSolicitudesDetalle extends StatelessWidget {
  final Map<String, dynamic> data;

  const PantallaMisSolicitudesDetalle({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final titulo = data["titulo"] ?? "";
    final descripcion = data["descripcion"] ?? "";

    // ---------- INGREDIENTES ----------
    final ingredientesRaw = data["ingredientes"];
    late final String ingredientes;

    if (ingredientesRaw is List) {
      ingredientes = ingredientesRaw.join("\n");
    } else if (ingredientesRaw is String) {
      ingredientes = ingredientesRaw;
    } else {
      ingredientes = "";
    }

    // ---------- PASOS ----------
    final pasosRaw = data["pasos"];
    late final String pasos;

    if (pasosRaw is List) {
      pasos = pasosRaw.join("\n");
    } else if (pasosRaw is String) {
      pasos = pasosRaw;
    } else {
      pasos = "";
    }

    // ---------- CATEGORIA ----------
    final categoriasRaw = data["categoria"];
    late final List<String> categorias;

    if (categoriasRaw is List) {
      categorias = categoriasRaw.cast<String>();
    } else if (categoriasRaw is String) {
      categorias = [categoriasRaw];
    } else {
      categorias = [];
    }

    final imagen = data["imagen"] ?? "";
    final estado = data["estado"] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de la receta"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagen.isNotEmpty
                  ? Image.network(
                      imagen,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey[700],
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // TITULO
            Text(
              titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ESTADO
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estado ? Colors.green[600] : Colors.orange[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estado ? "Aprobada" : "En revisión",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // CATEGORIA
            const Text(
              "Categoría:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(categorias.join(", "), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // DESCRIPCION
            const Text(
              "Descripción:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(descripcion, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // INGREDIENTES
            const Text(
              "Ingredientes:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(ingredientes, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // PASOS
            const Text(
              "Pasos de preparación:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(pasos, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 50),

            const Text(
              "Esta es una versión preliminar, si es aprobada el diseño final puede variar.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
