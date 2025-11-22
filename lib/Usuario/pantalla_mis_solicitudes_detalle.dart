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

    // ✅ CORREGIDO: Usar solo esAprovada para determinar el estado
    final esAprovada = data["esAprovada"];
    final respuesta = data["respuesta"] ?? "";

    // Determinar estado basado en esAprovada
    String estadoTexto;
    Color estadoColor;

    if (esAprovada == true) {
      estadoTexto = "Aprobada ✓";
      estadoColor = Colors.green[600]!;
    } else if (esAprovada == false) {
      estadoTexto = "Rechazada";
      estadoColor = Colors.red[600]!;
    } else {
      estadoTexto = "En revisión";
      estadoColor = const Color(0xFFFFC107);
    }

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

            // Badge de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                estadoTexto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ✅ NUEVO: Mostrar respuesta del admin si existe
            if (respuesta.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: esAprovada == true ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: esAprovada == true
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      esAprovada == true ? Icons.check_circle : Icons.info,
                      color: esAprovada == true
                          ? Colors.green[700]
                          : Colors.red[700],
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            esAprovada == true
                                ? "Respuesta del administrador"
                                : "Motivo del rechazo",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: esAprovada == true
                                  ? Colors.green[900]
                                  : Colors.red[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            respuesta,
                            style: TextStyle(
                              fontSize: 14,
                              color: esAprovada == true
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

            Center(
              child: Text(
                esAprovada == true
                    ? "¡Tu receta ha sido aprobada y publicada! 🎉"
                    : esAprovada == false
                    ? "Puedes crear una nueva solicitud con las correcciones sugeridas."
                    : "Esta es una versión preliminar, si es aprobada el diseño final puede variar.",
                style: TextStyle(
                  fontSize: 13,
                  color: esAprovada == null ? Colors.grey : Colors.black54,
                  fontWeight: esAprovada != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
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
