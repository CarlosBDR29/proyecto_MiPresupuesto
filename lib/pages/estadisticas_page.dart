import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/presupuesto_provider.dart';
import '../providers/ganancia_provider.dart';
import '../providers/categoria_provider.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  bool mostrarPresupuestos = true;

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<CategoriaProvider>().categorias;
    final presupuestos = context.watch<PresupuestoProvider>().presupuestos;
    final ganancias = context.watch<GananciaProvider>().ganancias;

    // 🔹 AGRUPACIÓN POR CATEGORÍA
    Map<String, double> datosAgrupados = {};

    if (mostrarPresupuestos) {
      for (var p in presupuestos) {
        final categoriaId = p.idTag ?? "sin_categoria";
        datosAgrupados[categoriaId] =
            (datosAgrupados[categoriaId] ?? 0) + p.limite;
      }
    } else {
      for (var g in ganancias) {
        final categoriaId = g.idTag ?? "sin_categoria";
        datosAgrupados[categoriaId] =
            (datosAgrupados[categoriaId] ?? 0) + g.objetivo;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Estadísticas")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // 🔄 Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("Presupuestos"),
                selected: mostrarPresupuestos,
                selectedColor: Colors.red,
                onSelected: (_) {
                  setState(() => mostrarPresupuestos = true);
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text("Ganancias"),
                selected: !mostrarPresupuestos,
                selectedColor: Colors.green,
                onSelected: (_) {
                  setState(() => mostrarPresupuestos = false);
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          Expanded(
            child: datosAgrupados.isEmpty
                ? const Center(child: Text("No hay datos disponibles"))
                : PieChart(
                    PieChartData(
                      sections: datosAgrupados.entries.map((entry) {
                        final categoria = categorias.firstWhere(
                          (c) => c.documentId == entry.key,
                          orElse: () => categorias.first,
                        );

                        return PieChartSectionData(
                          value: entry.value,
                          title: categoria?.titulo ?? "Sin categoría",
                          color: _generarColor(entry.key),
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 🎨 Generador simple de colores
  Color _generarColor(String key) {
    final hash = key.hashCode;
    return Colors.primaries[hash % Colors.primaries.length];
  }
}
