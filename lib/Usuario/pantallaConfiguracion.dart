import 'package:flutter/material.dart';

class Pantallaconfiguracion extends StatelessWidget {
  const Pantallaconfiguracion({super.key});

  @override
  Widget build(BuildContext context) {
    // Paleta usada en la UI
    final background = const Color(0xFF0F0F0F);
    final cardBackground = const Color(0xFF121212);
    final accent = const Color(0xFF1DB954); // verde similar al del diseño

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
        child: SingleChildScrollView(
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
                            // Aquí puedes cambiar a Image.asset(...) si tienes una imagen local
                            child: const Icon(
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
                      onPressed: () {
                        // Acción de editar perfil
                      },
                      child: Text('Editar', style: TextStyle(color: accent)),
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
                      subtitle: const Text(
                        'D Jo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        'Recetas Favoritas.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      subtitle: Text(
                        'Completar sección Info.',
                        style: TextStyle(color: accent),
                      ),
                      onTap: () {
                        // navegar a editar info
                      },
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.white70),
                      title: const Text(
                        'Correo Electrónico',
                        style: TextStyle(color: Colors.white70),
                      ),
                      subtitle: const Text(
                        '+504 9477-1360',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.link, color: Colors.white70),
                      title: const Text(
                        'Enlaces',
                        style: TextStyle(color: Colors.white70),
                      ),
                      subtitle: Text(
                        'Añadir enlaces',
                        style: TextStyle(color: accent),
                      ),
                      onTap: () {
                        // acción añadir enlaces
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Espacio final
            ],
          ),
        ),
      ),
    );
  }
}
