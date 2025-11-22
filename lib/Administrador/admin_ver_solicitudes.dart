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
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFC107)),
              );
            }

            final solicitudes = snapshot.data!.docs;

            if (solicitudes.isEmpty) {
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

            return ListView.builder(
              itemCount: solicitudes.length,
              itemBuilder: (context, index) {
                final data = solicitudes[index].data() as Map<String, dynamic>;
                final docId = solicitudes[index].id;

                final titulo = data['titulo'] ?? 'Sin título';
                final descripcion = data['descripcion'] ?? '';
                final solicitadoPor = data['solicitadoPor'] ?? 'Desconocido';
                final estadoBool = data['estado'];
                final respuesta = data['respuesta'] ?? '';

                String estadoTexto = estadoBool == true
                    ? 'Aprobada'
                    : estadoBool == false
                    ? 'Rechazada'
                    : 'Pendiente';

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
                        color: Colors.black.withOpacity(0.05),
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
                        // Header con título y botón de eliminar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                titulo,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _mostrarDialogoEliminar(docId),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: 'Eliminar solicitud',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(
                          "Descripción: $descripcion",
                          style: _itemTextStyle(),
                        ),
                        Text(
                          "Solicitado por: $solicitadoPor",
                          style: _itemTextStyle(),
                        ),
                        Text(
                          "Estado: $estadoTexto",
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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => _actualizarSolicitud(
                                docId,
                                true,
                                '¡Solicitud aceptada!',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Aceptar'),
                            ),
                            ElevatedButton(
                              onPressed: () => _actualizarSolicitud(
                                docId,
                                false,
                                'Lo sentimos, rechazada',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Rechazar'),
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

  TextStyle _itemTextStyle({Color color = Colors.black54}) {
    return TextStyle(fontSize: 14, color: color, height: 1.3);
  }

  // ============================================================
  // 🔥 FUNCIÓN PARA ELIMINAR SOLICITUD
  // ============================================================
  void _mostrarDialogoEliminar(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Solicitud'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar esta solicitud? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarSolicitud(docId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarSolicitud(String docId) async {
    try {
      await solicitudesRef.doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _actualizarSolicitud(
    String docId,
    bool nuevoEstado,
    String nuevaRespuesta,
  ) async {
    try {
      final solicitudDoc = await solicitudesRef.doc(docId).get();
      final data = solicitudDoc.data() as Map<String, dynamic>;

      // 1. Actualizar estado en SolicitudReceta
      await solicitudesRef.doc(docId).update({
        'estado': nuevoEstado,
        'respuesta': nuevaRespuesta,
      });

      // ----------------------------------------
      // 2. Si es aprobada → copiar a Recetas
      // ----------------------------------------
      if (nuevoEstado == true) {
        await FirebaseFirestore.instance.collection('Recetas').add({
          ...data,
          'estado': true,
          'fechaAprobacion': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud actualizada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
