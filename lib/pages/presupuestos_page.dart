import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/presupuesto_provider.dart';
import '../providers/loginregistro_provider.dart';
import '../models/presupuesto.dart';

class PresupuestosPage extends StatefulWidget {
  const PresupuestosPage({super.key});

  @override
  State<PresupuestosPage> createState() => _PresupuestosPageState();
}

class _PresupuestosPageState extends State<PresupuestosPage> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final loginProvider = context.read<LoginRegistroProvider>();
      final presupuestoProvider = context.read<PresupuestoProvider>();

      presupuestoProvider.obtenerPresupuestosUsuario(
        loginProvider.usuario!.documentId!,
      );
    });
  }

  void mostrarFormulario() {

    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final limiteController = TextEditingController();

    DateTime? inicio;
    DateTime? fin;

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("Nuevo Presupuesto"),
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
                      decoration: const InputDecoration(labelText: "Descripción"),
                    ),

                    TextField(
                      controller: limiteController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Límite"),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      child: Text(inicio == null
                          ? "Fecha inicio"
                          : inicio.toString().split(' ')[0]),
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
                      child: Text(fin == null
                          ? "Fecha fin"
                          : fin.toString().split(' ')[0]),
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

                final loginProvider =
                    context.read<LoginRegistroProvider>();

                final presupuestoProvider =
                    context.read<PresupuestoProvider>();

                Presupuesto nuevo = Presupuesto(
                  titulo: tituloController.text,
                  descripcion: descripcionController.text,
                  fechaInicio: inicio!,
                  fechaFin: fin!,
                  limite: double.parse(limiteController.text),
                  restante: 0,
                  estado: "",
                  idUsu: loginProvider.usuario!.documentId!,
                );

                await presupuestoProvider.agregarPresupuesto(nuevo);

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

    final provider = context.watch<PresupuestoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Presupuestos")),
      body: ListView.builder(
        itemCount: provider.presupuestos.length,
        itemBuilder: (context, index) {

          final presupuesto = provider.presupuestos[index];

          return ListTile(
            title: Text(presupuesto.titulo),
            subtitle: Text(
              "Restante: ${presupuesto.restante} | Estado: ${presupuesto.estado}",
            ),
            onTap: () {
              context.go('/presupuesto/${presupuesto.documentId}');
            },
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