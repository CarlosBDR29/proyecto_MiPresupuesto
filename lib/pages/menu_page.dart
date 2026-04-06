import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../widgets/custom_navbar.dart';
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

  bool _esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<String> _getEventosDelDia(DateTime day) {
    final presupuestos = context.read<PresupuestoProvider>().presupuestos;
    final ganancias = context.read<GananciaProvider>().ganancias;
    List<String> eventos = [];

    for (var p in presupuestos) {
      if (_esMismoDia(p.fechaFin, day))
        eventos.add("Fin presupuesto: ${p.titulo}");
    }
    for (var g in ganancias) {
      if (_esMismoDia(g.fechaFin, day))
        eventos.add("Fin ganancia: ${g.titulo}");
    }

    return eventos;
  }

  void _mostrarEventosDelDia(BuildContext context, DateTime day) {
    final presupuestosDia = context
        .read<PresupuestoProvider>()
        .presupuestos
        .where((p) => _esMismoDia(p.fechaFin, day))
        .toList();
    final gananciasDia = context
        .read<GananciaProvider>()
        .ganancias
        .where((g) => _esMismoDia(g.fechaFin, day))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                ...presupuestosDia.map(
                  (p) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                ...gananciasDia.map(
                  (g) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    double maxWidth = screenWidth > 1000
        ? 700
        : screenWidth > 600
        ? 600
        : screenWidth;

    return Scaffold(
      appBar: const CustomNavbar(),
      backgroundColor: const Color.fromARGB(255, 223, 248, 193),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Calendario de finalizaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TableCalendar(
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2100),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          _selectedDay != null &&
                          _esMismoDia(_selectedDay!, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.green.shade300,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          final presupuestos = context
                              .read<PresupuestoProvider>()
                              .presupuestos;
                          final ganancias = context
                              .read<GananciaProvider>()
                              .ganancias;

                          final cantidadPresupuestos = presupuestos
                              .where((p) => _esMismoDia(p.fechaFin, day))
                              .length;
                          final cantidadGanancias = ganancias
                              .where((g) => _esMismoDia(g.fechaFin, day))
                              .length;
                          final total =
                              cantidadPresupuestos + cantidadGanancias;
                          if (total == 0) return null;

                          Color color;
                          if (cantidadPresupuestos > 0 &&
                              cantidadGanancias > 0) {
                            color = Colors.blue;
                          } else if (cantidadGanancias > 0) {
                            color = Colors.green;
                          } else {
                            color = Colors.red;
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
                  ),
                ),
                const SizedBox(height: 25),

                if (_selectedDay != null)
                  ..._getEventosDelDia(_selectedDay!).map(
                    (evento) => Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(
                          Icons.event,
                          color: Color(0xFF2E7D32),
                        ),
                        title: Text(evento),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _menuCard(
                      context,
                      "Categorías",
                      Icons.category,
                      () => context.go(
                        '/categorias/${providerLogin.usuario!.documentId}',
                      ),
                    ),
                    _menuCard(
                      context,
                      "Presupuestos",
                      Icons.account_balance_wallet,
                      () => context.go('/presupuestos'),
                    ),
                    _menuCard(
                      context,
                      "Ganancias",
                      Icons.trending_up,
                      () => context.go('/ganancias'),
                    ),
                    _menuCard(
                      context,
                      "Estadísticas",
                      Icons.bar_chart,
                      () => context.go('/estadisticas'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context,
    String titulo,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 600 ? double.infinity : 160,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: const Color(0xFF2E7D32)),
                const SizedBox(height: 8),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
