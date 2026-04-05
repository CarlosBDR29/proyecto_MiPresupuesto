import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../providers/presupuesto_provider.dart';
import '../providers/ganancia_provider.dart';
import '../providers/categoria_provider.dart';

import '../models/ganancia.dart';
import '../models/presupuesto.dart';
import '../models/categoria.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  Widget _buildBarChart(
    Map<String, Map<String, double>> datosAgrupados,
    List<Categoria> categorias,
  ) {
    final categoriasMap = {for (var c in categorias) c.documentId: c.titulo};

    final listaDatos = datosAgrupados.entries.toList();

    final totalMeta = listaDatos.fold(0.0, (sum, e) => sum + e.value["meta"]!);

    final totalActual = listaDatos.fold(
      0.0,
      (sum, e) => sum + e.value["actual"]!,
    );

    final maxValor = listaDatos
        .map((e) => e.value["meta"]!)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 TOTAL ARRIBA
          Text(
            mostrarPresupuestos
                ? "Total presupuestado: ${totalMeta.toStringAsFixed(2)} €"
                : "Total objetivo: ${totalMeta.toStringAsFixed(2)} €",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            mostrarPresupuestos
                ? "Total gastado: ${totalActual.toStringAsFixed(2)} €"
                : "Total ganado: ${totalActual.toStringAsFixed(2)} €",
            style: TextStyle(
              fontSize: 16,
              color: mostrarPresupuestos ? Colors.red : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 25),

          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValor == 0 ? 10 : maxValor * 1.2,
                borderData: FlBorderData(show: false),

                /// 🔹 ARREGLA DESBORDAMIENTO LATERAL
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatoCompacto(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= listaDatos.length) {
                          return const SizedBox();
                        }

                        final key = listaDatos[index].key;
                        final nombre = categoriasMap[key] ?? "Sin categoría";

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            nombre,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                barGroups: listaDatos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final metaValor = entry.value.value["meta"]!;
                  final actualValor = entry.value.value["actual"]!;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      /// Barra meta (más clara)
                      BarChartRodData(
                        toY: metaValor,
                        width: 28,
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),

                      /// Barra actual (encima)
                      BarChartRodData(
                        toY: actualValor,
                        width: 18,
                        color: mostrarPresupuestos ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// 🔹 RESUMEN ABAJO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              mostrarPresupuestos
                  ? "Has gastado ${(totalActual / totalMeta * 100).toStringAsFixed(1)}% del total presupuestado."
                  : "Has alcanzado ${(totalActual / totalMeta * 100).toStringAsFixed(1)}% del objetivo total.",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatoCompacto(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    }
    return value.toStringAsFixed(0);
  }

  bool mostrarPresupuestos = true;

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<CategoriaProvider>().categorias;
    final presupuestos = context.watch<PresupuestoProvider>().presupuestos;
    final ganancias = context.watch<GananciaProvider>().ganancias;

    // 🔹 AGRUPACIÓN POR CATEGORÍA
    Map<String, Map<String, double>> datosAgrupados = {};

    if (mostrarPresupuestos) {
      for (var p in presupuestos) {
        final categoriaId = p.idTag ?? "sin_categoria";

        datosAgrupados.putIfAbsent(categoriaId, () => {"meta": 0, "actual": 0});

        datosAgrupados[categoriaId]!["meta"] =
            datosAgrupados[categoriaId]!["meta"]! + p.limite;

        datosAgrupados[categoriaId]!["actual"] =
            datosAgrupados[categoriaId]!["actual"]! + p.gastado;
      }
    } else {
      for (var g in ganancias) {
        final categoriaId = g.idTag ?? "sin_categoria";

        datosAgrupados.putIfAbsent(categoriaId, () => {"meta": 0, "actual": 0});

        datosAgrupados[categoriaId]!["meta"] =
            datosAgrupados[categoriaId]!["meta"]! + g.objetivo;

        datosAgrupados[categoriaId]!["actual"] =
            datosAgrupados[categoriaId]!["actual"]! + g.ganado;
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
                : _buildBarChart(datosAgrupados, categorias),
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
