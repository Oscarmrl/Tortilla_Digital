import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class PantallaConfiguracion extends StatefulWidget {
  final String userId;
  const PantallaConfiguracion({super.key, this.userId = ''});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  late final DocumentReference _docRef;

  @override
  void initState() {
    super.initState();
    _docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId);
  }

  /// ✅ Convierte Timestamp a texto legible
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

  /// ✅ Editar un campo de texto (nombre, etc.)
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

    if (result != null && result.isNotEmpty) {
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

  /// ✅ Mostrar opciones de cámara o galería
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.grey[700]),
                title: const Text(
                  'Tomar foto',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.grey[700]),
                title: const Text(
                  'Elegir desde galería',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Tomar/Seleccionar imagen y subir a Firebase Storage
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    try {
      final file = File(pickedFile.path);
      final fileName = path.basename(pickedFile.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child('usuarios')
          .child('${widget.userId}/$fileName');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await _docRef.update({'imagen': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = Colors.white;
    final cardBackground = Colors.white;
    final accent = const Color(0xFFFFC107); // amber
    final surface = const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
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
            final fechaCreacion = _formatTimestamp(data['fecha_creacion']);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: surface,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            child: ClipOval(
                              child: SizedBox(
                                width: 110,
                                height: 110,
                                child: imagen.isNotEmpty
                                    ? Image.network(
                                        imagen,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.person,
                                          size: 56,
                                          color: Colors.grey[600],
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 56,
                                        color: Colors.grey[600],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showImagePickerOptions,
                          child: Text(
                            'Cambiar foto',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.person_outline,
                            color: Colors.grey[700],
                          ),
                          title: const Text(
                            'Nombre',
                            style: TextStyle(color: Colors.grey),
                          ),
                          subtitle: Text(
                            nombre,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          onTap: () => _editField('nombre', nombre),
                        ),
                        const Divider(height: 1, color: Color(0xFFECECEC)),
                        ListTile(
                          leading: Icon(
                            Icons.email_outlined,
                            color: Colors.grey[700],
                          ),
                          title: const Text(
                            'Correo',
                            style: TextStyle(color: Colors.grey),
                          ),
                          subtitle: Text(
                            correo,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFECECEC)),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: Colors.grey[700],
                          ),
                          title: const Text(
                            'Fecha de creación',
                            style: TextStyle(color: Colors.grey),
                          ),
                          subtitle: Text(
                            fechaCreacion,
                            style: const TextStyle(color: Colors.black87),
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
