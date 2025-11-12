import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminVerRecetas extends StatefulWidget {
  final List<QueryDocumentSnapshot>? recetasFiltradas;
  final String buscarTitulo;

  const AdminVerRecetas({
    super.key,
    this.recetasFiltradas,
    required this.buscarTitulo,
  });

  @override
  State<AdminVerRecetas> createState() => _AdminVerRecetasState();
}

class _AdminVerRecetasState extends State<AdminVerRecetas> {
  final CollectionReference recetasRef = FirebaseFirestore.instance.collection(
    'Recetas',
  );
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _imagenUrlController = TextEditingController();
  final TextEditingController _ingredienteController = TextEditingController();
  final TextEditingController _pasoController = TextEditingController();

  List<String> _ingredientes = [];
  List<String> _pasos = [];

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _imagenUrlController.dispose();
    _ingredienteController.dispose();
    _pasoController.dispose();
    super.dispose();
  }

  // Función para eliminar receta
  Future<void> _eliminarReceta(String recetaId, String titulo) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar la receta "$titulo"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await recetasRef.doc(recetaId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Receta "$titulo" eliminada correctamente'),
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
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Función para editar receta
  Future<void> _editarReceta(QueryDocumentSnapshot receta) async {
    final recetaData = receta.data() as Map<String, dynamic>;

    // Llenar los controladores con los datos actuales
    _tituloController.text = recetaData['titulo'] ?? '';
    _descripcionController.text = recetaData['descripcion'] ?? '';
    _categoriaController.text = recetaData['categoria'] ?? '';
    _imagenUrlController.text = recetaData['imagenUrl'] ?? '';
    _ingredientes = List<String>.from(recetaData['ingredientes'] ?? []);
    _pasos = List<String>.from(recetaData['pasos'] ?? []);

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Editar Receta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo Título
                      TextField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo Descripción
                      TextField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo Categoría
                      TextField(
                        controller: _categoriaController,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo URL de Imagen
                      TextField(
                        controller: _imagenUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL de la Imagen',
                          border: OutlineInputBorder(),
                          hintText: 'https://ejemplo.com/imagen.jpg',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Vista previa de la imagen
                      if (_imagenUrlController.text.isNotEmpty)
                        Column(
                          children: [
                            const Text(
                              'Vista previa:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _imagenUrlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Imagen no disponible',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Sección Ingredientes
                      const Text(
                        'Ingredientes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ingredienteController,
                              decoration: const InputDecoration(
                                hintText: 'Agregar ingrediente',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (_ingredienteController.text.isNotEmpty) {
                                setState(() {
                                  _ingredientes.add(
                                    _ingredienteController.text,
                                  );
                                  _ingredienteController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Lista de ingredientes
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _ingredientes.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(_ingredientes[index]),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _ingredientes.removeAt(index);
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 16),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sección Pasos
                      const Text(
                        'Pasos:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pasoController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Agregar paso',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (_pasoController.text.isNotEmpty) {
                                setState(() {
                                  _pasos.add(_pasoController.text);
                                  _pasoController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Lista de pasos
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pasos.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(_pasos[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _pasos.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _limpiarFormulario();
                              },
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_validarFormulario()) {
                                  await _guardarCambios(receta.id);
                                  Navigator.of(context).pop();
                                  _limpiarFormulario();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3C814E),
                              ),
                              child: const Text(
                                'Guardar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _validarFormulario() {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El título es requerido')));
      return false;
    }
    if (_ingredientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ingrediente')),
      );
      return false;
    }
    if (_pasos.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agrega al menos un paso')));
      return false;
    }
    return true;
  }

  Future<void> _guardarCambios(String recetaId) async {
    try {
      await recetasRef.doc(recetaId).update({
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text,
        'categoria': _categoriaController.text,
        'imagenUrl': _imagenUrlController.text,
        'ingredientes': _ingredientes,
        'pasos': _pasos,
        'fechaActualizacion': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receta actualizada correctamente'),
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

  void _limpiarFormulario() {
    _tituloController.clear();
    _descripcionController.clear();
    _categoriaController.clear();
    _imagenUrlController.clear();
    _ingredienteController.clear();
    _pasoController.clear();
    _ingredientes.clear();
    _pasos.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7DB88),
      appBar: AppBar(
        title: const Text(
          'Recetas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3C814E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.recetasFiltradas != null
            ? _listaRecetas(widget.recetasFiltradas!)
            : StreamBuilder<QuerySnapshot>(
                stream: recetasRef
                    .where('esAprovada', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay recetas disponibles',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    );
                  }
                  return _listaRecetas(snapshot.data!.docs);
                },
              ),
      ),
    );
  }

  Widget _listaRecetas(List<QueryDocumentSnapshot> recetas) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: recetas.length,
      itemBuilder: (context, index) {
        final receta = recetas[index];
        final recetaData = receta.data() as Map<String, dynamic>;
        final titulo = recetaData['titulo'] ?? 'Sin título';
        final descripcion = recetaData['descripcion'] ?? 'Sin descripción';
        final imagenUrl = recetaData['imagenUrl'] ?? '';
        final categoria = recetaData['categoria'] ?? 'Desconocida';
        final creadoPor = recetaData['creadoPor'] ?? 'Desconocido';
        final fecha = recetaData['fechaCreacion'] != null
            ? (recetaData['fechaCreacion'] as Timestamp).toDate()
            : null;
        final ingredientes = recetaData['ingredientes'] ?? [];
        final pasos = recetaData['pasos'] ?? [];

        return GestureDetector(
          onTap: () {
            _mostrarDetallesReceta(
              titulo: titulo,
              descripcion: descripcion,
              imagenUrl: imagenUrl,
              categoria: categoria,
              creadoPor: creadoPor,
              fecha: fecha,
              ingredientes: ingredientes,
              pasos: pasos,
              receta: receta,
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: imagenUrl.isNotEmpty
                        ? Image.network(
                            imagenUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey,
                                child: const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey,
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDetallesReceta({
    required String titulo,
    required String descripcion,
    required String imagenUrl,
    required String categoria,
    required String creadoPor,
    required DateTime? fecha,
    required List<dynamic> ingredientes,
    required List<dynamic> pasos,
    required QueryDocumentSnapshot receta,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imagenUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imagenUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey,
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(descripcion, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Text(
                  'Categoría: $categoria',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Creado por: $creadoPor'),
                if (fecha != null)
                  Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}'),
                const SizedBox(height: 16),
                const Text(
                  'Ingredientes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ingredientes.length,
                    itemBuilder: (context, i) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(child: Text(ingredientes[i])),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pasos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pasos.length,
                  itemBuilder: (context, j) {
                    return ListTile(
                      leading: CircleAvatar(child: Text('${j + 1}')),
                      title: Text(pasos[j]),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Botones de Editar y Eliminar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        label: const Text(
                          'Editar',
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Cerrar diálogo actual
                          _editarReceta(receta);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Cerrar diálogo actual
                          _eliminarReceta(receta.id, titulo);
                        },
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
  }
}
