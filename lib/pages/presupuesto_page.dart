import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

//import 'package:file_picker/file_picker.dart';

import '../providers/presupuesto_provider.dart';
import '../providers/categoria_provider.dart';
import '../providers/loginregistro_provider.dart';

import '../models/presupuesto.dart';
import '../models/categoria.dart';

import '../providers/gasto_provider.dart';
import '../models/gasto.dart';

class PresupuestoPage extends StatefulWidget {
  final String documentId;

  const PresupuestoPage({super.key, required this.documentId});

  @override
  State<PresupuestoPage> createState() => _PresupuestoPageState();
}

class _PresupuestoPageState extends State<PresupuestoPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<GastoProvider>().obtenerGastosPresupuesto(widget.documentId);
    });
  }

  Future<void> mostrarFormularioGasto(
    BuildContext context,
    String? idPresupuesto, {
    Gasto? gastoExistente,
    double? costeAnterior,
  }) async {
    final tituloController = TextEditingController(
      text: gastoExistente?.titulo ?? "",
    );

    final descripcionController = TextEditingController(
      text: gastoExistente?.descripcion ?? "",
    );

    final costeController = TextEditingController(
      text: gastoExistente?.coste.toString() ?? "",
    );

    DateTime? fecha = gastoExistente?.fecha;
    Uint8List? imageBytes = gastoExistente?.photoBytes;

    File? selectedFile;

    void mostrarSnackBar(String mensaje) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red[400]),
      );
    }

    Future<void> pickImage() async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();

          setState(() {
            imageBytes = bytes;
          });
        }
      } catch (e) {
        mostrarSnackBar("Error al seleccionar imagen: $e");
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(gastoExistente == null ? "Nuevo Gasto" : "Editar Gasto"),
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
                      controller: costeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: "Coste"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => fecha = picked);
                      },
                      child: Text(
                        fecha == null
                            ? "Seleccionar fecha"
                            : fecha.toString().split(' ')[0],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await pickImage();
                        setState(() {}); // Actualizar preview
                      },
                      child: Text(
                        imageBytes == null
                            ? "Seleccionar imagen"
                            : "Cambiar imagen",
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (imageBytes != null)
                      Image.memory(imageBytes!, height: 120, fit: BoxFit.cover),
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
              onPressed: () async {
                if (tituloController.text.isEmpty ||
                    descripcionController.text.isEmpty ||
                    costeController.text.isEmpty ||
                    fecha == null) {
                  mostrarSnackBar("Completa todos los campos");
                  return;
                }

                final loginProvider = context.read<LoginRegistroProvider>();
                final gastoProvider = context.read<GastoProvider>();
                final presupuestoProvider = context.read<PresupuestoProvider>();

                final textoCoste = costeController.text.replaceAll(',', '.');
                final coste = double.tryParse(textoCoste);

                if (coste == null) {
                  mostrarSnackBar("Introduce un número válido en el coste");
                  return;
                }

                if (gastoExistente == null) {
                  // CREAR
                  final nuevoGasto = Gasto(
                    titulo: tituloController.text,
                    descripcion: descripcionController.text,
                    coste: coste,
                    fecha: fecha!,
                    photoBytes: imageBytes,
                    idPresu: idPresupuesto!,
                    idUsu: loginProvider.usuario!.documentId!,
                  );

                  await gastoProvider.agregarGasto(
                    nuevoGasto,
                    presupuestoProvider,
                  );
                } else {
                  // EDITAR
                  gastoExistente.titulo = tituloController.text;
                  gastoExistente.descripcion = descripcionController.text;
                  gastoExistente.coste = coste;
                  gastoExistente.fecha = fecha!;
                  gastoExistente.photoBytes = imageBytes;

                  await gastoProvider.editarGasto(
                    gastoExistente,
                    presupuestoProvider,
                    costeAnterior!,
                  );
                }

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> editarPresupuestoDialog(
    BuildContext context,
    Presupuesto presupuesto,
  ) async {
    final tituloController = TextEditingController(text: presupuesto.titulo);
    final descripcionController = TextEditingController(
      text: presupuesto.descripcion,
    );
    final limiteController = TextEditingController(
      text: presupuesto.limite.toString(),
    );

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

                await context.read<PresupuestoProvider>().editarPresupuesto(
                  presupuesto,
                );

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
    final gastoProvider = context.watch<GastoProvider>();

    final Presupuesto presupuesto = provider.presupuestos.firstWhere(
      (p) => p.documentId == widget.documentId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(presupuesto.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Descripción: ${presupuesto.descripcion}"),
            Text("Límite: ${presupuesto.limite}"),
            Text("Gastado: ${presupuesto.gastado}"),
            Text("Restante: ${presupuesto.restante}"),
            Text("Estado: ${presupuesto.estado}"),
            Text("Categoría: ${presupuesto.tag ?? "Sin categoría"}"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                editarPresupuestoDialog(context, presupuesto);
              },
              child: const Text("Editar presupuesto"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                await provider.eliminarPresupuesto(presupuesto.documentId!);

                Navigator.pop(context);
              },
              child: const Text("Eliminar presupuesto"),
            ),

            const Divider(height: 40),

            const Text(
              "Gastos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...gastoProvider.gastos.map((gasto) {
              return Card(
                child: ListTile(
                  title: Text(gasto.titulo),
                  subtitle: Text(
                    "${gasto.coste}€  |  ${gasto.fecha.toString().split(' ')[0]}",
                  ),

                  onTap: () {
                    mostrarFormularioGasto(
                      context,
                      presupuesto.documentId!,
                      gastoExistente: gasto,
                      costeAnterior: gasto.coste,
                    );
                  },

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await context.read<GastoProvider>().eliminarGasto(
                        gasto,
                        context.read<PresupuestoProvider>(),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          mostrarFormularioGasto(context, presupuesto.documentId);
        },
      ),
    );
  }
}
