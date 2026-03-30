import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../pages/registro_page.dart';
import '../pages/menu_page.dart';
import '../pages/categorias_page.dart';
import '../pages/presupuestos_page.dart';
import '../pages/presupuesto_page.dart';
import '../pages/ganancias_page.dart';
import '../pages/ganancia_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegistroPage(),
      ),
      GoRoute(path: '/menu', builder: (context, state) => const MenuPage()),
      GoRoute(
        path: '/categorias/:idUsu',
        builder: (context, state) {
          final idUsu = state.pathParameters['idUsu']!;

          return CategoriasPage(idUsu: idUsu);
        },
      ),
      GoRoute(
        path: '/presupuestos',
        builder: (context, state) => const PresupuestosPage(),
      ),
      GoRoute(
        path: '/presupuesto/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return PresupuestoPage(documentId: id);
        },
      ),
      GoRoute(
        path: '/ganancias',
        builder: (context, state) => const GananciasPage(),
      ),
      GoRoute(
        path: '/ganancia/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GananciaPage(documentId: id);
        },
      ),
    ],
  );
}
