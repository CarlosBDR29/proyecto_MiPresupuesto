import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../utils/download_mobile.dart'
    if (dart.library.html) '../utils/download_web.dart';

import '../widgets/custom_navbar.dart';
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

  Future<void> generarPdfPresupuesto(
    Presupuesto presupuesto,
    List<Gasto> gastos,
  ) async {
    final pdf = pw.Document();

    final porcentaje = ((presupuesto.gastado / presupuesto.limite) * 100).clamp(
      0,
      100,
    );

    final totalGastos = gastos.fold<double>(0, (sum, item) => sum + item.coste);

    final fechaGeneracion = DateTime.now().toString().split(' ')[0];

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          /// LOGO + TITULO
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  color: PdfColors.green300,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "MB",
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                "Informe de Presupuesto",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          pw.Text(
            "Fecha de generación: $fechaGeneracion",
            style: const pw.TextStyle(fontSize: 10),
          ),

          pw.Divider(color: PdfColors.green),

          pw.SizedBox(height: 20),

          /// DATOS GENERALES
          pw.Text(
            "Información general",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Text("Título: ${presupuesto.titulo}"),
          pw.Text("Descripción: ${presupuesto.descripcion}"),
          pw.Text(
            "Periodo: ${presupuesto.fechaInicio.toString().split(' ')[0]} - ${presupuesto.fechaFin.toString().split(' ')[0]}",
          ),
          pw.Text("Estado: ${presupuesto.estado}"),
          pw.Text("Categoría: ${presupuesto.tag ?? "Sin categoría"}"),

          pw.SizedBox(height: 20),

          /// RESUMEN ECONOMICO
          pw.Text(
            "Resumen económico",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Límite: ${presupuesto.limite.toStringAsFixed(2)}"),
                pw.Text("Gastado: ${presupuesto.gastado.toStringAsFixed(2)}"),
                pw.Text(
                  "Restante: ${(presupuesto.restante < 0 ? 0 : presupuesto.restante).toStringAsFixed(2)}",
                ),
                pw.Text("Uso: ${porcentaje.toStringAsFixed(1)} %"),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          /// TABLA GASTOS
          pw.Text(
            "Listado de gastos",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green600),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ["Título", "Fecha", "Coste"],
            data: gastos
                .map(
                  (g) => [
                    g.titulo,
                    g.fecha.toString().split(' ')[0],
                    g.coste.toStringAsFixed(2),
                  ],
                )
                .toList(),
          ),

          pw.SizedBox(height: 15),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                "TOTAL GASTOS: ${totalGastos.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      descargarPdfWeb(bytes, "presupuesto_${presupuesto.titulo}.pdf");
    } else {
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    }
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

    if (presupuesto.idTag != null && categorias.isNotEmpty) {
      try {
        categoriaSeleccionada = categorias.firstWhere(
          (c) => c.documentId == presupuesto.idTag,
        );
      } catch (_) {
        categoriaSeleccionada = null;
      }
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
      backgroundColor: const Color.fromARGB(255, 223, 248, 193),
      appBar: const CustomNavbar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final esPantallaGrande = constraints.maxWidth > 900;
          final anchoContenido = esPantallaGrande ? 900.0 : double.infinity;

          final porcentaje = ((presupuesto.gastado / presupuesto.limite) * 100)
              .clamp(0, 100)
              .toDouble();

          final restanteVisible = presupuesto.restante < 0
              ? 0
              : presupuesto.restante;

          Color colorBarra;

          if (porcentaje < 60) {
            colorBarra = Colors.green;
          } else if (porcentaje < 90) {
            colorBarra = Colors.orange;
          } else {
            colorBarra = Colors.red;
          }

          return Center(
            child: Container(
              width: anchoContenido,
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TÍTULO
                          Text(
                            presupuesto.titulo,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            presupuesto.descripcion,
                            style: const TextStyle(color: Colors.black54),
                          ),

                          const SizedBox(height: 20),

                          /// BARRA PROGRESO
                          LinearProgressIndicator(
                            value: porcentaje / 100,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(10),
                            color: colorBarra,
                            backgroundColor: Colors.grey.shade300,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "${porcentaje.toStringAsFixed(1)}% utilizado",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorBarra,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// DATOS ECONÓMICOS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDato(
                                "Límite",
                                "${presupuesto.limite.toStringAsFixed(2)} €",
                              ),
                              _buildDato(
                                "Gastado",
                                "${presupuesto.gastado.toStringAsFixed(2)} €",
                              ),
                              _buildDato(
                                "Restante",
                                "${restanteVisible.toStringAsFixed(2)} €",
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// FECHAS
                          Text(
                            "Periodo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            "${presupuesto.fechaInicio.toString().split(' ')[0]}  →  ${presupuesto.fechaFin.toString().split(' ')[0]}",
                          ),

                          const SizedBox(height: 15),

                          /// ESTADO + TAG
                          Row(
                            children: [
                              Chip(
                                label: Text(presupuesto.estado),
                                backgroundColor: presupuesto.estado == "Activo"
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                              ),
                              const SizedBox(width: 10),
                              Chip(
                                label: Text(presupuesto.tag ?? "Sin categoría"),
                                backgroundColor: Colors.blue.shade100,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            editarPresupuestoDialog(context, presupuesto);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Editar"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text("Confirmar eliminación"),
                                content: const Text(
                                  "¿Deseas eliminar este presupuesto?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Eliminar"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await provider.eliminarPresupuesto(
                                presupuesto.documentId!,
                              );
                              if (context.mounted) context.go('/presupuestos');
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text("Eliminar"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        generarPdfPresupuesto(
                          presupuesto,
                          gastoProvider.gastos,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Exportar a PDF"),
                    ),
                  ),

                  const Divider(height: 40),

                  const Text(
                    "Gastos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ...gastoProvider.gastos.map((gasto) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),

                        leading: gasto.photoBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  gasto.photoBytes!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.green,
                                  size: 30,
                                ),
                              ),

                        title: Text(
                          gasto.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${gasto.coste.toStringAsFixed(2)} €"),
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

                        // ✅ SOLO ESTE trailing
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    "Eliminar gasto",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    "¿Estás seguro de que quieres eliminar este gasto?\nEsta acción no se puede deshacer.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancelar"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Eliminar"),
                                    ),
                                  ],
                                );
                              },
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          mostrarFormularioGasto(context, presupuesto.documentId);
        },
      ),
    );
  }

  Widget _buildDato(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}
