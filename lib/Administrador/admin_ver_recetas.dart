// lib/Administrador/admin_ver_recetas.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminVerRecetas extends StatefulWidget {
  final List<QueryDocumentSnapshot>? recetasFiltradas;
  final String? buscarTitulo;

  const AdminVerRecetas({super.key, this.recetasFiltradas, this.buscarTitulo});

  @override
  State<AdminVerRecetas> createState() => _AdminVerRecetasState();
}

class _AdminVerRecetasState extends State<AdminVerRecetas> {
  final CollectionReference recetasRef = FirebaseFirestore.instance.collection(
    'Recetas',
  );

  // Controllers para edición (reutilizables)
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _imagenUrlController = TextEditingController();
  final TextEditingController _ingredienteController = TextEditingController();
  final TextEditingController _pasoController = TextEditingController();

  // Para búsqueda dentro de esta pantalla
  final TextEditingController _searchController = TextEditingController();

  List<String> _ingredientes = [];
  List<String> _pasos = [];

  @override
  void initState() {
    super.initState();
    if (widget.buscarTitulo != null && widget.buscarTitulo!.isNotEmpty) {
      _searchController.text = widget.buscarTitulo!;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _imagenUrlController.dispose();
    _ingredienteController.dispose();
    _pasoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Recetas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Barra de búsqueda FIJA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Buscar por título...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Lista / grid de recetas - EXPANDIDO para tomar todo el espacio restante
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: widget.recetasFiltradas != null
                  ? _buildGrid(widget.recetasFiltradas!)
                  : StreamBuilder<QuerySnapshot>(
                      stream: recetasRef
                          .where('esAprovada', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No hay recetas disponibles',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        final all = snapshot.data!.docs;

                        // Aplicar filtro local por título
                        final filtro = _searchController.text
                            .trim()
                            .toLowerCase();
                        final filtradas = filtro.isEmpty
                            ? all
                            : all.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final titulo = (data['titulo'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return titulo.contains(filtro);
                              }).toList();

                        return _buildGrid(filtradas);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye el grid con diseño parecido a PantallaInicio
  Widget _buildGrid(List<QueryDocumentSnapshot> recetas) {
    return GridView.builder(
      // QUITAR TODO EL PADDING que pueda causar overflow
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: recetas.length,
      itemBuilder: (context, index) {
        final receta = recetas[index];
        final data = receta.data() as Map<String, dynamic>;
        final imagenUrl =
            data['imagenUrl'] as String? ??
            'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=500';
        final titulo = data['titulo'] ?? 'Sin título';
        final categoria = data['categoria'] ?? 'Sin categoría';
        final descripcion = data['descripcion'] ?? '';

        return GestureDetector(
          onTap: () => _navegarADetallesReceta(
            receta: receta,
            titulo: titulo,
            descripcion: descripcion,
            imagenUrl: imagenUrl,
            categoria: categoria,
            creadoPor: data['creadoPor'] ?? 'Desconocido',
            fecha: data['fechaCreacion'] != null
                ? (data['fechaCreacion'] as Timestamp).toDate()
                : null,
            ingredientes: List<String>.from(data['ingredientes'] ?? []),
            pasos: List<String>.from(data['pasos'] ?? []),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    imagenUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        categoria,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Edit button
                          GestureDetector(
                            onTap: () {
                              _navegarAEditarReceta(receta);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          GestureDetector(
                            onTap: () {
                              _confirmarEliminar(receta.id, titulo);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
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

  // -----------------------------------------------------
  // Navegar a pantalla de detalles en lugar de diálogo
  // -----------------------------------------------------
  void _navegarADetallesReceta({
    required QueryDocumentSnapshot receta,
    required String titulo,
    required String descripcion,
    required String imagenUrl,
    required String categoria,
    required String creadoPor,
    required List<String> ingredientes,
    required List<String> pasos,
    DateTime? fecha,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DetallesRecetaScreen(
          titulo: titulo,
          descripcion: descripcion,
          imagenUrl: imagenUrl,
          categoria: categoria,
          creadoPor: creadoPor,
          fecha: fecha,
          ingredientes: ingredientes,
          pasos: pasos,
          receta: receta,
          onEdit: () {
            Navigator.pop(context);
            _navegarAEditarReceta(receta);
          },
          onDelete: () {
            Navigator.pop(context);
            _confirmarEliminar(receta.id, titulo);
          },
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // Navegar a pantalla de edición en lugar de diálogo
  // -----------------------------------------------------
  void _navegarAEditarReceta(QueryDocumentSnapshot recetaDoc) async {
    final recetaData = recetaDoc.data() as Map<String, dynamic>;

    // Rellenar controladores con datos actuales
    _tituloController.text = recetaData['titulo'] ?? '';
    _descripcionController.text = recetaData['descripcion'] ?? '';
    _categoriaController.text = recetaData['categoria'] ?? '';
    _imagenUrlController.text = recetaData['imagenUrl'] ?? '';
    _ingredientes = List<String>.from(recetaData['ingredientes'] ?? []);
    _pasos = List<String>.from(recetaData['pasos'] ?? []);

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EditarRecetaScreen(
          tituloController: _tituloController,
          descripcionController: _descripcionController,
          categoriaController: _categoriaController,
          imagenUrlController: _imagenUrlController,
          ingredienteController: _ingredienteController,
          pasoController: _pasoController,
          ingredientes: _ingredientes,
          pasos: _pasos,
          recetaId: recetaDoc.id,
          recetasRef: recetasRef,
        ),
      ),
    );

    if (resultado == true) {
      setState(() {}); // Refrescar la lista
    }
  }

  // -----------------------------------------------------
  // Confirmación eliminar (este sí puede ser diálogo simple)
  // -----------------------------------------------------
  void _confirmarEliminar(String recetaId, String titulo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de eliminar "$titulo"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _eliminarReceta(recetaId, titulo);
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

  // -----------------------------------------------------
  // Eliminar receta en Firestore
  // -----------------------------------------------------
  Future<void> _eliminarReceta(String recetaId, String titulo) async {
    try {
      await recetasRef.doc(recetaId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receta "$titulo" eliminada'),
          backgroundColor: Colors.green.shade400,
        ),
      );
      setState(() {}); // Refrescar la lista
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  // Valida formulario
  bool _validarFormulario() {
    if (_tituloController.text.trim().isEmpty) {
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

  // Limpia controladores
  void _limpiarFormulario() {
    _tituloController.clear();
    _descripcionController.clear();
    _categoriaController.clear();
    _imagenUrlController.clear();
    _ingredienteController.clear();
    _pasoController.clear();
    _ingredientes = [];
    _pasos = [];
  }
}

// -----------------------------------------------------
// PANTALLA SEPARADA PARA DETALLES DE RECETA
// -----------------------------------------------------
class _DetallesRecetaScreen extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String imagenUrl;
  final String categoria;
  final String creadoPor;
  final DateTime? fecha;
  final List<String> ingredientes;
  final List<String> pasos;
  final QueryDocumentSnapshot receta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetallesRecetaScreen({
    required this.titulo,
    required this.descripcion,
    required this.imagenUrl,
    required this.categoria,
    required this.creadoPor,
    required this.fecha,
    required this.ingredientes,
    required this.pasos,
    required this.receta,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            if (imagenUrl.isNotEmpty)
              Image.network(
                imagenUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey,
                  child: const Icon(Icons.image, size: 50, color: Colors.white),
                ),
              ),

            // Información básica
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip('Categoría: $categoria', Icons.category),
                      _buildInfoChip('Creado por: $creadoPor', Icons.person),
                      if (fecha != null)
                        _buildInfoChip(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha!)}', // AÑADÍ ! para convertir DateTime? a DateTime
                          Icons.calendar_today,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Ingredientes
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingredientes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ingredientes.map((ingrediente) {
                      return Chip(
                        backgroundColor: Colors.orange.shade100,
                        label: Text(ingrediente),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Pasos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pasos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...pasos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final paso = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade500,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              paso,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      backgroundColor: Colors.grey[100],
    );
  }
}

// -----------------------------------------------------
// PANTALLA SEPARADA PARA EDITAR RECETA
// -----------------------------------------------------
class _EditarRecetaScreen extends StatefulWidget {
  final TextEditingController tituloController;
  final TextEditingController descripcionController;
  final TextEditingController categoriaController;
  final TextEditingController imagenUrlController;
  final TextEditingController ingredienteController;
  final TextEditingController pasoController;
  final List<String> ingredientes;
  final List<String> pasos;
  final String recetaId;
  final CollectionReference recetasRef;

  const _EditarRecetaScreen({
    required this.tituloController,
    required this.descripcionController,
    required this.categoriaController,
    required this.imagenUrlController,
    required this.ingredienteController,
    required this.pasoController,
    required this.ingredientes,
    required this.pasos,
    required this.recetaId,
    required this.recetasRef,
  });

  @override
  State<_EditarRecetaScreen> createState() => __EditarRecetaScreenState();
}

class __EditarRecetaScreenState extends State<_EditarRecetaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Receta'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _guardarCambios),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            TextField(
              controller: widget.tituloController,
              decoration: InputDecoration(
                labelText: 'Título',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Descripción
            TextField(
              controller: widget.descripcionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Categoría
            TextField(
              controller: widget.categoriaController,
              decoration: InputDecoration(
                labelText: 'Categoría',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Imagen URL
            TextField(
              controller: widget.imagenUrlController,
              decoration: InputDecoration(
                labelText: 'URL de la imagen',
                hintText: 'https://...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Vista previa
            if (widget.imagenUrlController.text.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.imagenUrlController.text,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            if (widget.imagenUrlController.text.isNotEmpty)
              const SizedBox(height: 12),

            // Ingredientes
            const Text(
              'Ingredientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.ingredienteController,
                    decoration: InputDecoration(
                      hintText: 'Agregar ingrediente',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _addIngrediente,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips ingredientes
            if (widget.ingredientes.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.ingredientes.map((ing) {
                  return Chip(
                    backgroundColor: Colors.orange.shade200,
                    label: Text(ing),
                    onDeleted: () =>
                        setState(() => widget.ingredientes.remove(ing)),
                  );
                }).toList(),
              ),
            if (widget.ingredientes.isNotEmpty) const SizedBox(height: 16),

            // Pasos
            const Text(
              'Pasos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.pasoController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Agregar paso',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addPaso,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista de pasos
            if (widget.pasos.isNotEmpty)
              Column(
                children: widget.pasos.asMap().entries.map((entry) {
                  final i = entry.key;
                  final paso = entry.value;
                  return ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(paso),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => widget.pasos.removeAt(i)),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addIngrediente() {
    if (widget.ingredienteController.text.trim().isEmpty) return;
    setState(() {
      widget.ingredientes.add(widget.ingredienteController.text.trim());
      widget.ingredienteController.clear();
    });
  }

  void _addPaso() {
    if (widget.pasoController.text.trim().isEmpty) return;
    setState(() {
      widget.pasos.add(widget.pasoController.text.trim());
      widget.pasoController.clear();
    });
  }

  bool _validarFormulario() {
    if (widget.tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El título es requerido')));
      return false;
    }
    if (widget.ingredientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ingrediente')),
      );
      return false;
    }
    if (widget.pasos.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agrega al menos un paso')));
      return false;
    }
    return true;
  }

  Future<void> _guardarCambios() async {
    if (!_validarFormulario()) return;

    try {
      await widget.recetasRef.doc(widget.recetaId).update({
        'titulo': widget.tituloController.text.trim(),
        'descripcion': widget.descripcionController.text.trim(),
        'categoria': widget.categoriaController.text.trim(),
        'imagenUrl': widget.imagenUrlController.text.trim(),
        'ingredientes': widget.ingredientes,
        'pasos': widget.pasos,
        'fechaActualizacion': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true); // Retornar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receta actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
