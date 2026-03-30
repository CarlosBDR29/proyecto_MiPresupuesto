import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:go_router/go_router.dart';

import '../providers/ganancia_provider.dart';
import '../providers/ingreso_provider.dart';
import '../providers/loginregistro_provider.dart';
import '../providers/categoria_provider.dart';
import '../models/ganancia.dart';
import '../models/ingreso.dart';
import '../models/categoria.dart';

class GananciaPage extends StatefulWidget {
  final String documentId;

  const GananciaPage({super.key, required this.documentId});

  @override
  State<GananciaPage> createState() => _GananciaPageState();
}

class _GananciaPageState extends State<GananciaPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<IngresoProvider>().obtenerIngresosGanancia(
        widget.documentId,
      );
    });
  }

  Future<void> mostrarFormularioIngreso(
    BuildContext context,
    String idGanancia, {
    Ingreso? ingresoExistente,
    double? ganadoAnterior,
  }) async {
    final tituloController = TextEditingController(
      text: ingresoExistente?.titulo ?? "",
    );
    final descripcionController = TextEditingController(
      text: ingresoExistente?.descripcion ?? "",
    );
    final ganadoController = TextEditingController(
      text: ingresoExistente?.ganado.toString() ?? "",
    );

    DateTime? fecha = ingresoExistente?.fecha;
    Uint8List? imageBytes = ingresoExistente?.photoBytes;

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
          title: Text(
            ingresoExistente == null ? "Nuevo Ingreso" : "Editar Ingreso",
          ),
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
                      controller: ganadoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: "Ganado"),
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
                        setState(() {}); // refrescar preview
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
                    ganadoController.text.isEmpty ||
                    fecha == null) {
                  mostrarSnackBar("Completa todos los campos");
                  return;
                }

                final loginProvider = context.read<LoginRegistroProvider>();
                final ingresoProvider = context.read<IngresoProvider>();
                final gananciaProvider = context.read<GananciaProvider>();

                final textoGanado = ganadoController.text.replaceAll(',', '.');
                final ganado = double.tryParse(textoGanado);

                if (ganado == null) {
                  mostrarSnackBar("Introduce un número válido en Ganado");
                  return;
                }

                if (ingresoExistente == null) {
                  final nuevoIngreso = Ingreso(
                    titulo: tituloController.text,
                    descripcion: descripcionController.text,
                    ganado: ganado,
                    fecha: fecha!,
                    photoBytes: imageBytes,
                    idGanancia: idGanancia,
                    idUsu: loginProvider.usuario!.documentId!,
                  );
                  await ingresoProvider.agregarIngreso(
                    nuevoIngreso,
                    gananciaProvider,
                  );
                } else {
                  ingresoExistente.titulo = tituloController.text;
                  ingresoExistente.descripcion = descripcionController.text;
                  ingresoExistente.ganado = ganado;
                  ingresoExistente.fecha = fecha!;
                  ingresoExistente.photoBytes = imageBytes;

                  await ingresoProvider.editarIngreso(
                    ingresoExistente,
                    gananciaProvider,
                    ganadoAnterior!,
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

  Future<void> editarGananciaDialog(
    BuildContext context,
    Ganancia ganancia,
  ) async {
    final tituloController = TextEditingController(text: ganancia.titulo);
    final descripcionController = TextEditingController(
      text: ganancia.descripcion,
    );
    final objetivoController = TextEditingController(
      text: ganancia.objetivo.toString(),
    );

    DateTime fechaInicio = ganancia.fechaInicio;
    DateTime fechaFin = ganancia.fechaFin;

    Categoria? categoriaSeleccionada;
    final categorias = context.read<CategoriaProvider>().categorias;

    if (ganancia.idTag != null) {
      categoriaSeleccionada = categorias.firstWhere(
        (c) => c.documentId == ganancia.idTag,
        orElse: () => categorias.first,
      );
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar ganancia"),
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
                      controller: objetivoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Objetivo"),
                    ),
                    const SizedBox(height: 15),
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
                    objetivoController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Completa todos los campos obligatorios"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validación límite
                final textoObjetivo = objetivoController.text.replaceAll(
                  ',',
                  '.',
                );
                final objetivo = double.tryParse(textoObjetivo);
                if (objetivo == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Introduce un número válido en el límite"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                ganancia.titulo = tituloController.text;
                ganancia.descripcion = descripcionController.text;
                ganancia.objetivo = objetivo;
                ganancia.fechaInicio = fechaInicio;
                ganancia.fechaFin = fechaFin;

                if (categoriaSeleccionada != null) {
                  ganancia.idTag = categoriaSeleccionada!.documentId;
                  ganancia.tag = categoriaSeleccionada!.titulo;
                } else {
                  ganancia.idTag = null;
                  ganancia.tag = null;
                }

                await context.read<GananciaProvider>().editarGanancia(ganancia);
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
    final gananciaProvider = context.watch<GananciaProvider>();
    final ingresoProvider = context.watch<IngresoProvider>();

    final Ganancia ganancia = gananciaProvider.ganancias.firstWhere(
      (g) => g.documentId == widget.documentId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(ganancia.titulo)),
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
                      ganancia.descripcion,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text("Objetivo: ${ganancia.objetivo} €"),
                    Text("Ganado: ${ganancia.ganado} €"),
                    Text(
                      "Faltante: ${(ganancia.faltante < 0 ? 0 : ganancia.faltante)} €",
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Periodo:",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${ganancia.fechaInicio.toString().split(' ')[0]} → ${ganancia.fechaFin.toString().split(' ')[0]}",
                    ),
                    const SizedBox(height: 10),
                    Text("Estado: ${ganancia.estado}"),
                    Text("Categoría: ${ganancia.tag ?? "Sin categoría"}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                editarGananciaDialog(context, ganancia);
              },
              child: const Text("Editar ganancia"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirmar eliminación"),
                    content: const Text("¿Deseas eliminar esta ganancia?"),
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
                  await gananciaProvider.eliminarGanancia(ganancia.documentId!);
                  if (context.mounted) context.go('/ganancias');
                }
              },
              child: const Text("Eliminar ganancia"),
            ),
            const Divider(height: 40),
            const Text(
              "Ingresos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...ingresoProvider.ingresos.map((ingreso) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: ingreso.photoBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            ingreso.photoBytes!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.attach_money, size: 40),
                  title: Text(
                    ingreso.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${ingreso.ganado} €"),
                      Text(ingreso.fecha.toString().split(' ')[0]),
                    ],
                  ),
                  onTap: () {
                    mostrarFormularioIngreso(
                      context,
                      ganancia.documentId!,
                      ingresoExistente: ingreso,
                      ganadoAnterior: ingreso.ganado,
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirmar eliminación"),
                          content: const Text("¿Deseas eliminar este ingreso?"),
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
                        await context.read<IngresoProvider>().eliminarIngreso(
                          ingreso,
                          context.read<GananciaProvider>(),
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
          mostrarFormularioIngreso(context, ganancia.documentId!);
        },
      ),
    );
  }
}
