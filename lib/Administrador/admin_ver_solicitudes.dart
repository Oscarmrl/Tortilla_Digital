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
      backgroundColor: const Color(0xFFB7DB88),
      appBar: AppBar(
        title: const Text(
          'Solicitudes de Recetas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3C814E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: solicitudesRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No hay solicitudes',
                  style: TextStyle(fontSize: 18, color: Colors.white),
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

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Descripción: $descripcion'),
                              Text('Solicitado por: $solicitadoPor'),
                              Text('Estado: $estado'),
                              if (respuesta.isNotEmpty)
                                Text('Respuesta: $respuesta'),
                              if (fecha != null)
                                Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy – HH:mm').format(fecha)}',
                                ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _actualizarSolicitud(
                                docId,
                                'aceptada',
                                '¡Solicitud aceptada!',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Aceptar'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _actualizarSolicitud(
                                docId,
                                'rechazada',
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
