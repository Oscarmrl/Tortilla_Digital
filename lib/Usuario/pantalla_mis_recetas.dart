import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaMisRecetas extends StatefulWidget {
  const PantallaMisRecetas({super.key});

  @override
  State<PantallaMisRecetas> createState() => _PantallaMisRecetasState();
}

class _PantallaMisRecetasState extends State<PantallaMisRecetas> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();

  //TIEMPO
  final TextEditingController _tiempoController = TextEditingController();
  String _unidadTiempo = "Minutos";

  List<String> unidadesTiempo = ["Minutos", "Horas"];

  String _selectedCategory = '';
  File? _imageFile;

  List<String> categories = ['Rápida', 'Bebidas', 'Tradicionales', 'Postres'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = categories.first; // OPCIÓN 2 IMPLEMENTADA
  }

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

      List<String> ingredientesList = _ingredientsController.text
          .split("\n")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      List<String> pasosList = _stepsController.text
          .split("\n")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      String path =
          "solicitudes_recetas/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg";

      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(_imageFile!);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("SolicitudReceta").add({
        "categoria": _selectedCategory,
        "descripcion": _descriptionController.text.trim(),
        "esAprovada": false,
        "fechaCreacion": Timestamp.now(),
        "imagen": imageUrl,
        "ingredientes": ingredientesList,
        "pasos": pasosList,
        "respuesta": "",
        "solicitadaPor": user.uid,
        "titulo": _titleController.text.trim(),
        "tiempo":
            "${_tiempoController.text.trim()} ${_unidadTiempo.toLowerCase()}",
      });

      _titleController.clear();
      _descriptionController.clear();
      _ingredientsController.clear();
      _stepsController.clear();
      _tiempoController.clear();
      _unidadTiempo = unidadesTiempo.first;

      setState(() {
        _imageFile = null;
        _selectedCategory = categories.first; // vuelve a la primera
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Solicitud enviada"),
          backgroundColor: Colors.green[700],
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
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: true,
        title: const Text(
          'Enviar Receta',
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
                  _selectorImagen(),

                  const SizedBox(height: 15),
                  _campoTexto('Título', _titleController),

                  const SizedBox(height: 15),
                  _dropdownCategoria(),

                  const SizedBox(height: 15),
                  _campoTexto(
                    'Descripción',
                    _descriptionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _tiempoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Tiempo",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Ingresa el tiempo";
                            }
                            if (int.tryParse(value) == null) {
                              return "Solo números";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _unidadTiempo,
                          items: unidadesTiempo
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          decoration: InputDecoration(
                            labelText: "Unidad",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _unidadTiempo = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  _campoTexto(
                    'Ingredientes (uno por línea)',
                    _ingredientsController,
                    maxLines: 5,
                  ),

                  const SizedBox(height: 15),
                  _campoTexto(
                    'Pasos de preparación (uno por línea)',
                    _stepsController,
                    maxLines: 6,
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          enviarSolicitud();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Enviar solicitud',
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
            onPressed: _takePhoto,
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
                Icon(Icons.camera_alt, size: 20),
                SizedBox(width: 8),
                Text('Tomar Foto'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (_imageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _imageFile!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_back, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No hay imagen seleccionada',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _dropdownCategoria() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Categoría',
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
      items: categories.map((String value) {
        return DropdownMenuItem(value: value, child: Text(value));
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCategory = newValue!;
        });
      },
    );
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
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa $label';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
    _tiempoController.dispose();
  }
}
