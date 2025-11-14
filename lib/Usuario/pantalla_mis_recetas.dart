import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaMisRecetas extends StatefulWidget {
  const PantallaMisRecetas({super.key});

  @override
  State<PantallaMisRecetas> createState() => _PantallaMisRecetas();
}

class _PantallaMisRecetas extends State<PantallaMisRecetas> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  String _selectedCategory = 'Principal';
  File? _imageFile;

  List<String> categories = [
    'Principal',
    'Postre',
    'Bebida',
    'Ensalada',
    'Sopa',
    'Aperitivo',
  ];

  Future<void> enviarSolicitud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Debes iniciar sesión.")));
        return;
      }

      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Toma una foto de tu receta.")),
        );
        return;
      }

      // 1. Subir imagen a Storage
      String imagePath =
          "solicitudes_recetas/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg";

      final ref = FirebaseStorage.instance.ref().child(imagePath);
      await ref.putFile(_imageFile!);
      final imageUrl = await ref.getDownloadURL();

      // 2. Enviar documento a Firestore
      await FirebaseFirestore.instance.collection("SolicitudReceta").add({
        "categoria": [_selectedCategory],
        "descripcion": _descriptionController.text.trim(),
        "estado": false,
        "fechaCreacion": Timestamp.now(),
        "imagen": imageUrl,
        "ingredientes": _ingredientsController.text.trim(),
        "respuesta": "",
        "solicitadaPor": user.uid,
        "titulo": _titleController.text.trim(),
        "pasos": _stepsController.text.trim(),
      });

      // 🧽 3. Limpiar campos correctamente
      _titleController.clear();
      _descriptionController.clear();
      _ingredientsController.clear();
      _stepsController.clear();

      setState(() {
        _imageFile = null;
        _selectedCategory = 'Principal';
      });

      // 4. Mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Solicitud enviada"),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al enviar solicitud: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Receta'),
        backgroundColor: const Color(0xFFFFC107), // Amber color from the image
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                // Image Picker
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                Text(
                                  'Toca para tomar una foto',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título de la receta',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Ingredients Field
                TextFormField(
                  controller: _ingredientsController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Ingredientes',
                    hintText: 'Escribe cada ingrediente en una nueva línea',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa los ingredientes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Describe brevemente tu receta',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Steps Field
                TextFormField(
                  controller: _stepsController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Pasos de preparación',
                    hintText: 'Escribe cada paso en una nueva línea',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa los pasos de preparación';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      enviarSolicitud();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Enviar solicitud',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }
}
