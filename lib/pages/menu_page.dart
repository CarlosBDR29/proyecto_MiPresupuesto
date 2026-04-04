import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/loginregistro_provider.dart';
import '../providers/presupuesto_provider.dart';
import '../providers/ganancia_provider.dart';
import '../models/presupuesto.dart';
import '../models/ganancia.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final login = context.read<LoginRegistroProvider>();
      final idUsu = login.usuario!.documentId!;

      context.read<PresupuestoProvider>().obtenerPresupuestosUsuario(idUsu);
      context.read<GananciaProvider>().obtenerGananciasUsuario(idUsu);
    });
  }

  List<String> _getEventosDelDia(DateTime day) {
    final presupuestos = context.read<PresupuestoProvider>().presupuestos;
    final ganancias = context.read<GananciaProvider>().ganancias;

    List<String> eventos = [];

    for (Presupuesto p in presupuestos) {
      if (_esMismoDia(p.fechaFin, day)) {
        eventos.add("Fin presupuesto: ${p.titulo}");
      }
    }

    for (Ganancia g in ganancias) {
      if (_esMismoDia(g.fechaFin, day)) {
        eventos.add("Fin ganancia: ${g.titulo}");
      }
    }

    return eventos;
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _mostrarEventosDelDia(BuildContext context, DateTime day) {
    final presupuestos = context.read<PresupuestoProvider>().presupuestos;
    final ganancias = context.read<GananciaProvider>().ganancias;

    final presupuestosDia = presupuestos
        .where((p) => _esMismoDia(p.fechaFin, day))
        .toList();

    final gananciasDia = ganancias
        .where((g) => _esMismoDia(g.fechaFin, day))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Eventos del día (${presupuestosDia.length + gananciasDia.length})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // 🔴 Presupuestos
                ...presupuestosDia.map(
                  (p) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.red,
                      ),
                      title: Text(p.titulo),
                      subtitle: const Text("Fin de Presupuesto"),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/presupuesto/${p.documentId}');
                        },
                      ),
                    ),
                  ),
                ),

                // 🟢 Ganancias
                ...gananciasDia.map(
                  (g) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(
                        Icons.trending_up,
                        color: Colors.green,
                      ),
                      title: Text(g.titulo),
                      subtitle: const Text("Fin de Ganancia"),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/ganancia/${g.documentId}');
                        },
                      ),
                    ),
                  ),
                ),

                if (presupuestosDia.isEmpty && gananciasDia.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No hay eventos este día.",
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerLogin = context.read<LoginRegistroProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Menú')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Calendario de finalizaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null && _esMismoDia(_selectedDay!, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final presupuestos = context
                      .read<PresupuestoProvider>()
                      .presupuestos;

                  final ganancias = context.read<GananciaProvider>().ganancias;

                  final cantidadPresupuestos = presupuestos
                      .where((p) => _esMismoDia(p.fechaFin, day))
                      .length;

                  final cantidadGanancias = ganancias
                      .where((g) => _esMismoDia(g.fechaFin, day))
                      .length;

                  final total = cantidadPresupuestos + cantidadGanancias;

                  if (total == 0) return null;

                  Color color;

                  if (cantidadPresupuestos > 0 && cantidadGanancias > 0) {
                    color = Colors.blue; // 🔵 ambos
                  } else if (cantidadGanancias > 0) {
                    color = Colors.green; // 🟢 solo ganancia
                  } else {
                    color = Colors.red; // 🔴 solo presupuesto
                  }

                  return Positioned(
                    bottom: 1,
                    child: GestureDetector(
                      onTap: () {
                        _mostrarEventosDelDia(context, day);
                      },
                      child: Container(
                        width: total > 1 ? 18 : 8,
                        height: total > 1 ? 18 : 8,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: total > 1
                            ? Text(
                                total.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            if (_selectedDay != null)
              ..._getEventosDelDia(_selectedDay!).map(
                (evento) => ListTile(
                  leading: const Icon(Icons.event, color: Colors.red),
                  title: Text(evento),
                ),
              ),

            const Divider(height: 40),

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
            ElevatedButton(
              onPressed: () {
                context.go('/estadisticas');
              },
              child: const Text("Estadísticas"),
            ),
          ],
        ),
      ),
    );
  }
}
