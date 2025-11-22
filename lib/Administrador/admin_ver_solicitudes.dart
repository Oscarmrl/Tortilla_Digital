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
                final estadoBool = data['esAprovada'];
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
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
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

  void _actualizarSolicitud(
    String docId,
    bool nuevoEstado,
    String nuevaRespuesta,
  ) async {
    try {
      final solicitudDoc = await solicitudesRef.doc(docId).get();
      final data = solicitudDoc.data() as Map<String, dynamic>;
      await solicitudesRef.doc(docId).update({
        'esAprovada': nuevoEstado,
        'respuesta': nuevaRespuesta,
      });
      if (nuevoEstado == true) {
        await FirebaseFirestore.instance.collection('Recetas').add({
          'categoria': data['categoria'],
          'descripcion': data['descripcion'],
          'esAprovada': true,
          'fechaCreacion': data['fechaCreacion'],
          'imagenUrl': data['imagen'],
          'ingredientes': data['ingredientes'],
          'pasos': data['pasos'],
          'titulo': data['titulo'],
          'tiempo': data['tiempo'],
          'fechaAprobacion': Timestamp.now(),
          'rating': 4.8,
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solicitud actualizada')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    }
  }
}
