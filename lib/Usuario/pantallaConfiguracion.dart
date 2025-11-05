import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PantallaConfiguracion extends StatefulWidget {
  final String userId;
  const PantallaConfiguracion({super.key, this.userId = 'usuario11'});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  late final DocumentReference _docRef;

  @override
  void initState() {
    super.initState();
    _docRef = FirebaseFirestore.instance
        .collection('Usuario')
        .doc(widget.userId);
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    DateTime dateTime;
    if (ts is Timestamp) {
      dateTime = ts.toDate();
    } else if (ts is DateTime) {
      dateTime = ts;
    } else {
      return '';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
  }

  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Ingresa $field'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _docRef.update({field: result});
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Guardado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = const Color(0xFF0F0F0F);
    final cardBackground = const Color(0xFF121212);
    final accent = const Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Perfil'),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _docRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final nombre = data['nombre']?.toString() ?? '';
            final imagen = data['imagen']?.toString() ?? '';
            final correo = data['correo']?.toString() ?? '';
            final fechaCreacion = _formatTimestamp(data['fechaCreacion']);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Avatar + Editar
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: Colors.white24,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: cardBackground,
                            child: ClipOval(
                              child: SizedBox(
                                width: 110,
                                height: 110,
                                child: imagen.isNotEmpty
                                    ? Image.network(
                                        imagen,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.person,
                                              size: 56,
                                              color: Colors.white70,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 56,
                                        color: Colors.white70,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _editField('imagen', imagen),
                          child: Text(
                            'Editar',
                            style: TextStyle(color: accent),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Card / secciones
                  Container(
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.person_outline,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Nombre',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            nombre,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () => _editField('nombre', nombre),
                        ),
                        const Divider(height: 1, color: Colors.white12),
                        ListTile(
                          leading: const Icon(
                            Icons.email_outlined,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Correo',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            correo,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const Divider(height: 1, color: Colors.white12),
                        ListTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                          ),
                          title: const Text(
                            'Fecha de creación',
                            style: TextStyle(color: Colors.white70),
                          ),
                          subtitle: Text(
                            fechaCreacion,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
