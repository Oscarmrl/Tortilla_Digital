import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();
  final TextEditingController tiempoController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  final TextEditingController imagenUrlController = TextEditingController();
  final TextEditingController ingredientesController = TextEditingController();
  final TextEditingController pasosController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7DB88),
      appBar: AppBar(
        title: const Text(
          'Agregar Receta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3C814E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _campoTexto('Título', tituloController),
              const SizedBox(height: 10),
              _campoTexto('Descripción', descripcionController, maxLines: 3),
              const SizedBox(height: 10),
              _campoTexto('Categoría', categoriaController),
              const SizedBox(height: 10),
              _campoTexto('Tiempo', tiempoController),
              const SizedBox(height: 10),
              _campoTexto('Rating', ratingController),
              const SizedBox(height: 10),
              _campoTexto('URL de la imagen', imagenUrlController),
              const SizedBox(height: 10),
              _campoTexto(
                'Ingredientes (separados por coma)',
                ingredientesController,
              ),
              const SizedBox(height: 10),
              _campoTexto('Pasos (separados por coma)', pasosController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarReceta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C814E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Guardar Receta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
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
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
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
      List<String> ingredientes = ingredientesController.text
          .split(',')
          .map((e) => e.trim())
          .toList();
      List<String> pasos = pasosController.text
          .split(',')
          .map((e) => e.trim())
          .toList();

      try {
        // Verificar si ya existe una receta con el mismo título
        QuerySnapshot existing = await recetasRef
            .where('titulo', isEqualTo: tituloController.text)
            .get();

        if (existing.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ya existe una receta con este título, por favor cambie el título.',
              ),
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
          'imagenUrl': imagenUrlController.text,
          'ingredientes': ingredientes,
          'pasos': pasos,
          'esAprovada': true,
          'creadoPor': 'admin',
          'fechaCreacion': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta agregada correctamente')),
        );

        Navigator.pop(context); // Regresar a AdminVerRecetas
      } catch (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $error')));
      }
    }
  }
}
