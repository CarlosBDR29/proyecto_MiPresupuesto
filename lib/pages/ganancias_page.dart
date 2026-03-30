import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/ganancia_provider.dart';
import '../providers/loginregistro_provider.dart';
import '../models/ganancia.dart';

class GananciasPage extends StatefulWidget {
  const GananciasPage({super.key});

  @override
  State<GananciasPage> createState() => _GananciasPageState();
}

class _GananciasPageState extends State<GananciasPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final loginProvider = context.read<LoginRegistroProvider>();
      final gananciaProvider = context.read<GananciaProvider>();

      final idUsu = loginProvider.usuario!.documentId!;

      gananciaProvider.obtenerGananciasUsuario(idUsu);
    });
  }

  void mostrarFormulario() {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final objetivoController = TextEditingController();

    DateTime? inicio;
    DateTime? fin;

    void mostrarError(String mensaje) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nueva Ganancia"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(labelText: "Título"),
                    ),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: "Descripción",
                      ),
                    ),
                    TextField(
                      controller: objetivoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Objetivo"),
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton(
                      child: Text(
                        inicio == null
                            ? "Fecha inicio"
                            : inicio.toString().split(' ')[0],
                      ),
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );

                        if (fecha != null) {
                          setState(() => inicio = fecha);
                        }
                      },
                    ),

                    ElevatedButton(
                      child: Text(
                        fin == null
                            ? "Fecha fin"
                            : fin.toString().split(' ')[0],
                      ),
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );

                        if (fecha != null) {
                          setState(() => fin = fecha);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () async {
                if (tituloController.text.isEmpty ||
                    descripcionController.text.isEmpty ||
                    objetivoController.text.isEmpty ||
                    inicio == null ||
                    fin == null) {
                  mostrarError("Completa todos los campos");
                  return;
                }

                final textoObjetivo =
                    objetivoController.text.replaceAll(',', '.');

                final objetivo = double.tryParse(textoObjetivo);

                if (objetivo == null) {
                  mostrarError("Introduce un número válido en el objetivo");
                  return;
                }

                final loginProvider =
                    context.read<LoginRegistroProvider>();
                final gananciaProvider =
                    context.read<GananciaProvider>();

                Ganancia nueva = Ganancia(
                  titulo: tituloController.text,
                  descripcion: descripcionController.text,
                  fechaInicio: inicio!,
                  fechaFin: fin!,
                  objetivo: objetivo,
                  faltante: 0,
                  estado: "",
                  idUsu: loginProvider.usuario!.documentId!,
                );

                await gananciaProvider.agregarGanancia(nueva);

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GananciaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Ganancias")),
      body: ListView.builder(
        itemCount: provider.ganancias.length,
        itemBuilder: (context, index) {
          final ganancia = provider.ganancias[index];

          final faltante =
              ganancia.faltante < 0 ? 0 : ganancia.faltante;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(
                ganancia.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Faltante: $faltante € | Estado: ${ganancia.estado}",
              ),
              onTap: () {
                context.go('/ganancia/${ganancia.documentId}');
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: mostrarFormulario,
        child: const Icon(Icons.add),
      ),
    );
  }
}