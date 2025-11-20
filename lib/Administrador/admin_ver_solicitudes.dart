// lib/Administrador/admin_ver_solicitudes.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminVerSolicitudesScreen extends StatefulWidget {
  const AdminVerSolicitudesScreen({super.key});

  @override
  State<AdminVerSolicitudesScreen> createState() =>
      _AdminVerSolicitudesScreenState();
}

class _AdminVerSolicitudesScreenState extends State<AdminVerSolicitudesScreen> {
  final CollectionReference solicitudesRef = FirebaseFirestore.instance
      .collection('SolicitudReceta');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Solicitudes de Recetas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: solicitudesRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFC107)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No hay solicitudes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            final solicitudes = snapshot.data!.docs;

            return ListView.builder(
              itemCount: solicitudes.length,
              itemBuilder: (context, index) {
                final data = solicitudes[index].data() as Map<String, dynamic>;
                final docId = solicitudes[index].id;

                final titulo = data['titulo'] ?? 'Sin título';
                final descripcion = data['descripcion'] ?? '';
                final solicitadoPor = data['solicitadoPor'] ?? 'Desconocido';
                final estado = data['estado'] ?? 'Pendiente';
                final respuesta = data['respuesta'] ?? '';

                final fecha = data['fechaCreacion'] != null
                    ? (data['fechaCreacion'] as Timestamp).toDate()
                    : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Información
                        Text(
                          "Descripción: $descripcion",
                          style: _itemTextStyle(),
                        ),
                        Text(
                          "Solicitado por: $solicitadoPor",
                          style: _itemTextStyle(),
                        ),
                        Text(
                          "Estado: $estado",
                          style: _itemTextStyle(color: Colors.orange),
                        ),
                        if (respuesta.isNotEmpty)
                          Text(
                            "Respuesta: $respuesta",
                            style: _itemTextStyle(color: Colors.green),
                          ),
                        if (fecha != null)
                          Text(
                            "Fecha: ${DateFormat('dd/MM/yyyy – HH:mm').format(fecha)}",
                            style: _itemTextStyle(),
                          ),

                        const SizedBox(height: 16),

                        // Botones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _styledButton(
                              text: "Aceptar",
                              color: const Color(0xFFFFC107),
                              textColor: Colors.black,
                              onPressed: () => _actualizarSolicitud(
                                docId,
                                'aceptada',
                                '¡Solicitud aceptada!',
                              ),
                            ),
                            _styledButton(
                              text: "Rechazar",
                              color: Colors.red.shade300,
                              textColor: Colors.white,
                              onPressed: () => _actualizarSolicitud(
                                docId,
                                'rechazada',
                                'Lo sentimos, rechazada',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ==============================
  // 🔹 Helpers visuales
  // ==============================
  TextStyle _itemTextStyle({Color color = Colors.black54}) {
    return TextStyle(fontSize: 14, color: color, height: 1.3);
  }

  Widget _styledButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 1.5,
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  // ==============================
  // 🔹 Función ya existente (sin cambios)
  // ==============================
  void _actualizarSolicitud(
    String docId,
    String nuevoEstado,
    String nuevaRespuesta,
  ) {
    solicitudesRef
        .doc(docId)
        .update({'estado': nuevoEstado, 'respuesta': nuevaRespuesta})
        .then((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Solicitud $nuevoEstado')));
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar: $error')),
          );
        });
  }
}
