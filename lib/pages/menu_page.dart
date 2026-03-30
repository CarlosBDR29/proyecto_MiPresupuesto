import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loginregistro_provider.dart';
import 'package:go_router/go_router.dart';

import 'categorias_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final providerLogin = context.read<LoginRegistroProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Menú')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¡Has iniciado sesión correctamente!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await providerLogin.logoutUsuario();
                context.go('/login');
              },
              child: const Text('Cerrar sesión'),
            ),
            ElevatedButton(
              onPressed: () {
                context.go('/categorias/${providerLogin.usuario!.documentId}');
              },
              child: const Text("Ir a Categorías"),
            ),
            ElevatedButton(
              onPressed: () {
                context.go('/presupuestos');
              },
              child: const Text("Presupuestos"),
            ),
            ElevatedButton(
              onPressed: () {
                context.go('/ganancias');
              },
              child: const Text("Ganancias"),
            ),
          ],
        ),
      ),
    );
  }
}
