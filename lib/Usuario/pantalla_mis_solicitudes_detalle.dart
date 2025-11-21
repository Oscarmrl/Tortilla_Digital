import 'package:flutter/material.dart';

class PantallaMisSolicitudesDetalle extends StatelessWidget {
  final Map<String, dynamic> data;

  const PantallaMisSolicitudesDetalle({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final titulo = data["titulo"] ?? "";
    final descripcion = data["descripcion"] ?? "";

    final ingredientesRaw = data["ingredientes"];
    late final String ingredientes = (ingredientesRaw is List)
        ? ingredientesRaw.join("\n")
        : (ingredientesRaw ?? "");

    final pasosRaw = data["pasos"];
    late final String pasos = (pasosRaw is List)
        ? pasosRaw.join("\n")
        : (pasosRaw ?? "");

    final categoriasRaw = data["categoria"];
    late final List<String> categorias = (categoriasRaw is List)
        ? categoriasRaw.cast<String>()
        : (categoriasRaw is String)
        ? [categoriasRaw]
        : [];

    final tiempoCompleto = data["tiempo"] ?? "";
    final imagen = data["imagen"] ?? "";
    final esAprovada = data["esAprovada"] ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: true,
        title: const Text(
          "Detalle de la receta",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------- IMAGEN -----------
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: imagen.isNotEmpty
                  ? Image.network(
                      imagen,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // ----------- TÍTULO Y ESTATUS -----------
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: esAprovada ? Colors.green[600] : const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                esAprovada ? "Aprobada" : "En revisión",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ----------- TARJETA DE INFORMACIÓN -----------
            _cardSeccion(title: "Categoría", content: categorias.join(", ")),

            _cardSeccion(title: "Descripción", content: descripcion),

            _cardSeccion(
              title: "Tiempo de preparación",
              content: tiempoCompleto,
            ),

            _cardSeccion(title: "Ingredientes", content: ingredientes),

            _cardSeccion(title: "Pasos de preparación", content: pasos),

            const SizedBox(height: 40),

            const Center(
              child: Text(
                "Esta es una versión preliminar, si es aprobada el diseño final puede variar.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ----------- TARJETA DE SECCIÓN UNIFORME -----------
  Widget _cardSeccion({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
