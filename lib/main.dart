import 'package:flutter/material.dart';
import 'package:tortilla_digital/Usuario/pantallaConfiguracion.dart';

void main() {
  runApp(const Principal());
}

class Principal extends StatelessWidget {
  const Principal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Aplicación Principal')),
        body: Center(
          child: Builder(
            // ✅ Esto crea un nuevo contexto válido
            builder: (context) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Pantallaconfiguracion(),
                        ),
                      );
                    },
                    child: const Text('Ir a Configuración de Perfil'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
