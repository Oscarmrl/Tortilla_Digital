import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminAgregarRecetaScreen extends StatefulWidget {
  const AdminAgregarRecetaScreen({super.key});

  @override
  State<AdminAgregarRecetaScreen> createState() =>
      _AdminAgregarRecetaScreenState();
}

class _AdminAgregarRecetaScreenState extends State<AdminAgregarRecetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final CollectionReference recetasRef = FirebaseFirestore.instance.collection(
    'Recetas',
  );
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();
  final TextEditingController tiempoController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  final TextEditingController ingredientesController = TextEditingController();
  final TextEditingController pasosController = TextEditingController();

  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();
  bool _subiendoImagen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: true,
        title: const Text(
          'Agregar Receta',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _campoTexto('Título', tituloController),
                  const SizedBox(height: 15),
                  _campoTexto(
                    'Descripción',
                    descripcionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  _campoTexto('Categoría', categoriaController),
                  const SizedBox(height: 15),

                  _campoTiempoLibre(),
                  const SizedBox(height: 15),

                  _campoTexto('Rating', ratingController),
                  const SizedBox(height: 15),

                  _selectorImagen(),
                  const SizedBox(height: 15),

                  _campoTexto(
                    'Ingredientes (separados por coma)',
                    ingredientesController,
                  ),
                  const SizedBox(height: 15),
                  _campoTexto('Pasos (separados por coma)', pasosController),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _subiendoImagen ? null : _guardarReceta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _subiendoImagen
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Subiendo imagen...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Guardar Receta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoTiempoLibre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiempo de preparación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: tiempoController,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Ejemplo: 30 min, 1 hora, 1h 30min, 45 minutos...',
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el tiempo de preparación';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _selectorImagen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen de la receta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _subiendoImagen ? null : _seleccionarImagen,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 20),
                SizedBox(width: 8),
                Text(
                  'Seleccionar imagen de la galería',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (_imagenSeleccionada != null)
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _subiendoImagen
                      ? null
                      : () {
                          setState(() {
                            _imagenSeleccionada = null;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Quitar imagen',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          )
        else if (!_subiendoImagen)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_camera_back,
                  size: 50,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No hay imagen seleccionada',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = File(imagen.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<String?> _subirImagenAFirebase() async {
    if (_imagenSeleccionada == null) return null;

    try {
      setState(() {
        _subiendoImagen = true;
      });
      String nombreArchivo =
          'receta_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference referencia = _storage.ref().child(nombreArchivo);

      UploadTask uploadTask = referencia.putFile(_imagenSeleccionada!);
      TaskSnapshot snapshot = await uploadTask;

      String downloadURL = await snapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      return null;
    } finally {
      setState(() {
        _subiendoImagen = false;
      });
    }
  }

  Widget _campoTexto(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese $label';
        }
        return null;
      },
    );
  }

  void _guardarReceta() async {
    if (_formKey.currentState!.validate()) {
      if (_imagenSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona una imagen para la receta'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      List<String> ingredientes = ingredientesController.text
          .split(',')
          .map((e) => e.trim())
          .toList();

      List<String> pasos = pasosController.text
          .split(',')
          .map((e) => e.trim())
          .toList();

      try {
        QuerySnapshot existing = await recetasRef
            .where('titulo', isEqualTo: tituloController.text)
            .get();

        if (existing.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ya existe una receta con este título. Cambia el título por favor.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        String? imagenUrl = await _subirImagenAFirebase();

        if (imagenUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir la imagen. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await recetasRef.add({
          'titulo': tituloController.text,
          'descripcion': descripcionController.text,
          'categoria': categoriaController.text,
          'tiempo': tiempoController.text,
          'rating': ratingController.text,
          'imagenUrl': imagenUrl,
          'ingredientes': ingredientes,
          'pasos': pasos,
          'esAprovada': true,
          'creadoPor': 'admin',
          'fechaCreacion': DateTime.now(),
          'fechaActualizacion': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receta agregada correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
