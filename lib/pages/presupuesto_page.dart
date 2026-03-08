import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/presupuesto_provider.dart';
import '../models/presupuesto.dart';

class PresupuestoPage extends StatelessWidget {

  final String documentId;

  const PresupuestoPage({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PresupuestoProvider>();

    final Presupuesto presupuesto =
        provider.presupuestos.firstWhere(
      (p) => p.documentId == documentId,
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

            const SizedBox(height: 30),

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