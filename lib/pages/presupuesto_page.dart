import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/presupuesto_provider.dart';
import '../providers/categoria_provider.dart';

import '../models/presupuesto.dart';
import '../models/categoria.dart';

class PresupuestoPage extends StatefulWidget {
  final String documentId;

  const PresupuestoPage({super.key, required this.documentId});

  @override
  State<PresupuestoPage> createState() => _PresupuestoPageState();
}

class _PresupuestoPageState extends State<PresupuestoPage> {

  Future<void> editarPresupuestoDialog(
      BuildContext context,
      Presupuesto presupuesto,
      ) async {

    final tituloController = TextEditingController(text: presupuesto.titulo);
    final descripcionController = TextEditingController(text: presupuesto.descripcion);
    final limiteController = TextEditingController(text: presupuesto.limite.toString());

    Categoria? categoriaSeleccionada;

    final categorias = context.read<CategoriaProvider>().categorias;

    if (presupuesto.idTag != null) {
      categoriaSeleccionada = categorias.firstWhere(
            (c) => c.documentId == presupuesto.idTag,
        orElse: () => categorias.first,
      );
    }

    await showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("Editar presupuesto"),
          content: SingleChildScrollView(
            child: Column(
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

                const SizedBox(height: 15),

                DropdownButtonFormField<Categoria>(
                  value: categoriaSeleccionada,
                  hint: const Text("Seleccionar categoría"),
                  items: categorias.map((categoria) {

                    return DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.titulo),
                    );

                  }).toList(),
                  onChanged: (value) {
                    categoriaSeleccionada = value;
                  },
                ),

              ],
            ),
          ),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),

            ElevatedButton(
              onPressed: () async {

                presupuesto.titulo = tituloController.text;
                presupuesto.descripcion = descripcionController.text;
                presupuesto.limite = double.parse(limiteController.text);

                if (categoriaSeleccionada != null) {
                  presupuesto.idTag = categoriaSeleccionada!.documentId;
                  presupuesto.tag = categoriaSeleccionada!.titulo;
                }

                await context
                    .read<PresupuestoProvider>()
                    .editarPresupuesto(presupuesto);

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),

          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PresupuestoProvider>();

    final Presupuesto presupuesto = provider.presupuestos.firstWhere(
          (p) => p.documentId == widget.documentId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(presupuesto.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Descripción: ${presupuesto.descripcion}"),
            Text("Límite: ${presupuesto.limite}"),
            Text("Gastado: ${presupuesto.gastado}"),
            Text("Restante: ${presupuesto.restante}"),
            Text("Estado: ${presupuesto.estado}"),
            Text("Categoría: ${presupuesto.tag ?? "Sin categoría"}"),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                editarPresupuestoDialog(context, presupuesto);
              },
              child: const Text("Editar presupuesto"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {

                await provider.eliminarPresupuesto(
                  presupuesto.documentId!,
                );

                Navigator.pop(context);
              },
              child: const Text("Eliminar presupuesto"),
            ),

          ],
        ),
      ),
    );
  }
}