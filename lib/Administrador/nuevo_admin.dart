import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NuevoAdminScreen extends StatefulWidget {
  const NuevoAdminScreen({super.key});

  @override
  State<NuevoAdminScreen> createState() => _NuevoAdminScreenState();
}

class _NuevoAdminScreenState extends State<NuevoAdminScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final CollectionReference usuariosRef = FirebaseFirestore.instance.collection(
    'usuarios',
  );

  // Registrar usuario
  Future<void> registrarAdministrador() async {
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty || correo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
        ),
      );
      return;
    }

    try {
      await usuariosRef.add({
        'nombre': nombre,
        'correo': correo,
        'rol': 'Admin',
        'fecha_creacion': DateTime.now(),
      });

      _nombreController.clear();
      _correoController.clear();
      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador registrado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Editar usuario
  void _editarUsuario(DocumentSnapshot u) {
    final data = u.data() as Map<String, dynamic>;
    _nombreController.text = data['nombre'] ?? '';
    _correoController.text = data['correo'] ?? '';
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await u.reference.update({
                'nombre': _nombreController.text.trim(),
                'correo': _correoController.text.trim(),
              });
              _nombreController.clear();
              _correoController.clear();
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Eliminar usuario
  void _eliminarUsuario(DocumentSnapshot u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Deseas eliminar este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await u.reference.delete();
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Administrador'),
        backgroundColor: const Color.fromARGB(255, 1, 77, 10),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registrar nuevo administrador',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: registrarAdministrador,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 56, 7),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Registrar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Usuarios registrados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: usuariosRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data!.docs;
                  if (users.isEmpty) {
                    return const Center(
                      child: Text('No hay usuarios registrados aún.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      final data = u.data() as Map<String, dynamic>;
                      final rol = data['rol'] as String? ?? 'Cliente';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            data['nombre'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(data['correo'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: (rol == 'Admin' || rol == 'Cliente')
                                    ? rol
                                    : 'Cliente',
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Admin',
                                    child: Text('Admin'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Cliente',
                                    child: Text('Cliente'),
                                  ),
                                ],
                                onChanged: (nuevoRol) {
                                  if (nuevoRol != null) {
                                    u.reference.update({'rol': nuevoRol});
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editarUsuario(u),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _eliminarUsuario(u),
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
          ],
        ),
      ),
    );
  }
}
