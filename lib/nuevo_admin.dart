import 'package:flutter/material.dart';

class NuevoAdminScreen extends StatefulWidget {
  const NuevoAdminScreen({super.key}); //Pantalla de nuevo administrador

  @override
  State<NuevoAdminScreen> createState() => _NuevoAdminScreenState();
}

class _NuevoAdminScreenState extends State<NuevoAdminScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // Lista simulada de administradores registrados (no guardamos la contraseña en la vista)
  List<Map<String, dynamic>> administradores = [
    {'nombre': 'Nabil Reyes', 'correo': 'nabil@correo.com', 'activo': true},
    {'nombre': 'Emma Torres', 'correo': 'emma@correo.com', 'activo': false},
  ];

  void registrarAdministrador() {
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text;

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

    setState(() {
      administradores.add({'nombre': nombre, 'correo': correo, 'activo': true});
      _nombreController.clear();
      _correoController.clear();
      _passwordController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Administrador registrado con éxito')),
    );
  }

  void cambiarEstado(int index) {
    setState(() {
      administradores[index]['activo'] = !administradores[index]['activo'];
    });

    final estado = administradores[index]['activo']
        ? 'activado'
        : 'desactivado';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Administrador ${administradores[index]['nombre']} $estado',
        ),
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
        backgroundColor: const Color.fromARGB(255, 74, 41, 0),
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
                backgroundColor: const Color.fromARGB(255, 82, 43, 1),
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
              'Administradores registrados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: administradores.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay administradores registrados aún.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: administradores.length,
                      itemBuilder: (context, index) {
                        final admin = administradores[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                              admin['nombre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(admin['correo']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  admin['activo'] ? 'Activo' : 'Inactivo',
                                  style: TextStyle(
                                    color: admin['activo']
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: admin['activo'],
                                  activeColor: const Color.fromARGB(
                                    255,
                                    83,
                                    51,
                                    2,
                                  ),
                                  onChanged: (value) => cambiarEstado(index),
                                ),
                              ],
                            ),
                          ),
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
