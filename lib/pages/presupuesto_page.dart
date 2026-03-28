import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:go_router/go_router.dart';

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

    DateTime fechaInicio = presupuesto.fechaInicio;
    DateTime fechaFin = presupuesto.fechaFin;

    Categoria? categoriaSeleccionada;

    final categorias = context.read<CategoriaProvider>().categorias;

    // Si ya tiene categoría asignada
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
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
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
                      controller: limiteController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Límite"),
                    ),
                    const SizedBox(height: 15),

                    // Selección de fecha inicio
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: fechaInicio,
                        );
                        if (picked != null)
                          setState(() => fechaInicio = picked);
                      },
                      child: Text(
                        "Fecha inicio: ${fechaInicio.toString().split(' ')[0]}",
                      ),
                    ),

                    // Selección de fecha fin
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: fechaInicio,
                          lastDate: DateTime(2100),
                          initialDate: fechaFin,
                        );
                        if (picked != null) setState(() => fechaFin = picked);
                      },
                      child: Text(
                        "Fecha fin: ${fechaFin.toString().split(' ')[0]}",
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<Categoria>(
                      value: categoriaSeleccionada,
                      hint: const Text("Seleccionar categoría"),
                      items: [
                        const DropdownMenuItem<Categoria>(
                          value: null,
                          child: Text("Sin categoría"),
                        ),
                        ...categorias.map((categoria) {
                          return DropdownMenuItem(
                            value: categoria,
                            child: Text(categoria.titulo),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          categoriaSeleccionada = value;
                        });
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
              onPressed: () async {
                // Validación campos obligatorios
                if (tituloController.text.isEmpty ||
                    descripcionController.text.isEmpty ||
                    limiteController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Completa todos los campos obligatorios"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validación límite
                final textoLimite = limiteController.text.replaceAll(',', '.');
                final limite = double.tryParse(textoLimite);
                if (limite == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Introduce un número válido en el límite"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Guardar cambios
                presupuesto.titulo = tituloController.text;
                presupuesto.descripcion = descripcionController.text;
                presupuesto.limite = limite;
                presupuesto.fechaInicio = fechaInicio;
                presupuesto.fechaFin = fechaFin;

                if (categoriaSeleccionada != null) {
                  presupuesto.idTag = categoriaSeleccionada!.documentId;
                  presupuesto.tag = categoriaSeleccionada!.titulo;
                } else {
                  presupuesto.idTag = null;
                  presupuesto.tag = null;
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
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presupuesto.descripcion,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),

                    Text("Límite: ${presupuesto.limite} €"),
                    Text("Gastado: ${presupuesto.gastado} €"),
                    Text(
                      "Restante: ${(presupuesto.restante < 0 ? 0 : presupuesto.restante)} €",
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Periodo:",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${presupuesto.fechaInicio.toString().split(' ')[0]}  →  ${presupuesto.fechaFin.toString().split(' ')[0]}",
                    ),

                    const SizedBox(height: 10),

                    Text("Estado: ${presupuesto.estado}"),
                    Text("Categoría: ${presupuesto.tag ?? "Sin categoría"}"),
                  ],
                ),
              ),
            ),

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
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirmar eliminación"),
                    content: const Text("¿Deseas eliminar este presupuesto?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Eliminar"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await provider.eliminarPresupuesto(presupuesto.documentId!);
                  if (context.mounted) context.go('/presupuestos');
                }
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
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: gasto.photoBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            gasto.photoBytes!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.receipt_long, size: 40),

                  title: Text(
                    gasto.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${gasto.coste} €"),
                      Text(gasto.fecha.toString().split(' ')[0]),
                    ],
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
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirmar eliminación"),
                          content: const Text("¿Deseas eliminar este gasto?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancelar"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Eliminar"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await context.read<GastoProvider>().eliminarGasto(
                          gasto,
                          context.read<PresupuestoProvider>(),
                        );
                      }
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
