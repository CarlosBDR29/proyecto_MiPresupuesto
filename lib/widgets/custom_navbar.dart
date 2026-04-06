import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/loginregistro_provider.dart';

class CustomNavbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final providerLogin = context.read<LoginRegistroProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    // Determinar si estamos en móvil/tablet
    final bool isMobile = screenWidth < 700;

    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      elevation: 4,
      title: Row(
        children: [
          Image.asset('assets/images/LogoMyBudget.png', height: 40),
          const SizedBox(width: 12),
          const Text(
            'MyBudget',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      actions: [
        if (!isMobile) ...[
          TextButton(
            onPressed: () => context.go('/menu'),
            child: const Text('Menú', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => context.go('/presupuestos'),
            child: const Text(
              'Presupuesto',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/ganancias'),
            child: const Text(
              'Ganancias',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.go('/categorias/${providerLogin.usuario!.documentId}'),
            child: const Text(
              'Categorías',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/estadisticas'),
            child: const Text(
              'Estadísticas',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ] else ...[
          // Menú desplegable para móvil/tablet
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'menu':
                  context.go('/menu');
                  break;
                case 'presupuestos':
                  context.go('/presupuestos');
                  break;
                case 'ganancias':
                  context.go('/ganancias');
                  break;
                case 'categorias':
                  context.go(
                    '/categorias/${providerLogin.usuario!.documentId}',
                  );
                  break;
                case 'estadisticas':
                  context.go('/estadisticas');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'menu', child: Text('Menú')),
              const PopupMenuItem(
                value: 'presupuestos',
                child: Text('Presupuesto'),
              ),
              const PopupMenuItem(value: 'ganancias', child: Text('Ganancias')),
              const PopupMenuItem(
                value: 'categorias',
                child: Text('Categorías'),
              ),
              const PopupMenuItem(
                value: 'estadisticas',
                child: Text('Estadísticas'),
              ),
            ],
          ),
        ],

        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            await providerLogin.logoutUsuario();
            context.go('/login');
          },
        ),
      ],
    );
  }
}
