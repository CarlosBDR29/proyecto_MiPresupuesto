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

  Future<void> generarPdfGanancia(
    Ganancia ganancia,
    List<Ingreso> ingresos,
  ) async {
    final pdf = pw.Document();

    final porcentaje = ((ganancia.ganado / ganancia.objetivo) * 100).clamp(
      0,
      100,
    );

    final totalIngresos = ingresos.fold<double>(
      0,
      (sum, item) => sum + item.ganado,
    );

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
                "Informe de Ganancia",
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

          pw.Text("Título: ${ganancia.titulo}"),
          pw.Text("Descripción: ${ganancia.descripcion}"),
          pw.Text(
            "Periodo: ${ganancia.fechaInicio.toString().split(' ')[0]} - ${ganancia.fechaFin.toString().split(' ')[0]}",
          ),
          pw.Text("Estado: ${ganancia.estado}"),
          pw.Text("Categoría: ${ganancia.tag ?? "Sin categoría"}"),

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
                pw.Text("Objetivo: ${ganancia.objetivo.toStringAsFixed(2)}"),
                pw.Text("Ganado: ${ganancia.ganado.toStringAsFixed(2)}"),
                pw.Text(
                  "Faltante: ${(ganancia.faltante < 0 ? 0 : ganancia.faltante).toStringAsFixed(2)}",
                ),
                pw.Text("Gano: ${porcentaje.toStringAsFixed(1)} %"),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          /// TABLA GASTOS
          pw.Text(
            "Listado de ingresos",
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
            headers: ["Título", "Fecha", "Ganado"],
            data: ingresos
                .map(
                  (g) => [
                    g.titulo,
                    g.fecha.toString().split(' ')[0],
                    g.ganado.toStringAsFixed(2),
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
                "TOTAL INGRESOS: ${totalIngresos.toStringAsFixed(2)}",
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
      descargarPdfWeb(bytes, "ganancia_${ganancia.titulo}.pdf");
    } else {
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    }
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

    if (ganancia.idTag != null && categorias.isNotEmpty) {
      try {
        categoriaSeleccionada = categorias.firstWhere(
          (c) => c.documentId == ganancia.idTag,
        );
      } catch (_) {
        categoriaSeleccionada = null;
      }
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
      backgroundColor: const Color.fromARGB(255, 223, 248, 193),
      appBar: const CustomNavbar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final esPantallaGrande = constraints.maxWidth > 900;
          final anchoContenido = esPantallaGrande ? 900.0 : double.infinity;

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
                            ganancia.titulo,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// DESCRIPCIÓN
                          Text(
                            ganancia.descripcion,
                            style: const TextStyle(color: Colors.black54),
                          ),

                          const SizedBox(height: 20),

                          /// BARRA PROGRESO (GANADO / OBJETIVO)
                          Builder(
                            builder: (_) {
                              final porcentaje =
                                  ((ganancia.ganado / ganancia.objetivo) * 100)
                                      .clamp(0, 100)
                                      .toDouble();

                              Color colorBarra;

                              if (porcentaje < 60) {
                                colorBarra = Colors.red;
                              } else if (porcentaje < 90) {
                                colorBarra = Colors.orange;
                              } else {
                                colorBarra = Colors.green;
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: porcentaje / 100,
                                    minHeight: 12,
                                    borderRadius: BorderRadius.circular(10),
                                    color: colorBarra,
                                    backgroundColor: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${porcentaje.toStringAsFixed(1)}% alcanzado",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorBarra,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          /// DATOS ECONÓMICOS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDato(
                                "Objetivo",
                                "${ganancia.objetivo.toStringAsFixed(2)} €",
                              ),
                              _buildDato(
                                "Ganado",
                                "${ganancia.ganado.toStringAsFixed(2)} €",
                              ),
                              _buildDato(
                                "Faltante",
                                "${(ganancia.faltante < 0 ? 0 : ganancia.faltante).toStringAsFixed(2)} €",
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// PERIODO
                          Text(
                            "Periodo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            "${ganancia.fechaInicio.toString().split(' ')[0]}  →  ${ganancia.fechaFin.toString().split(' ')[0]}",
                          ),

                          const SizedBox(height: 15),

                          /// ESTADO + TAG
                          Row(
                            children: [
                              Chip(
                                label: Text(ganancia.estado),
                                backgroundColor: ganancia.estado == "Activo"
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                              ),
                              const SizedBox(width: 10),
                              Chip(
                                label: Text(ganancia.tag ?? "Sin categoría"),
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
                      /// EDITAR
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
                            editarGananciaDialog(context, ganancia);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Editar"),
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// ELIMINAR
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
                                  "¿Deseas eliminar esta ganancia?",
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
                              await context
                                  .read<GananciaProvider>()
                                  .eliminarGanancia(ganancia.documentId!);

                              if (context.mounted) {
                                context.go('/ganancias');
                              }
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
                        generarPdfGanancia(ganancia, ingresoProvider.ingresos);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Exportar a PDF"),
                    ),
                  ),

                  const Divider(height: 40),

                  const Text(
                    "Ingresos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ...ingresoProvider.ingresos.map((ingreso) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),

                        /// IMAGEN O ICONO
                        leading: ingreso.photoBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  ingreso.photoBytes!,
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
                                  Icons.attach_money,
                                  color: Colors.green,
                                  size: 30,
                                ),
                              ),

                        /// TÍTULO
                        title: Text(
                          ingreso.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        /// SUBTÍTULO
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${ingreso.ganado.toStringAsFixed(2)} €"),
                            Text(ingreso.fecha.toString().split(' ')[0]),
                          ],
                        ),

                        /// CLICK PARA EDITAR
                        onTap: () {
                          mostrarFormularioIngreso(
                            context,
                            ganancia.documentId!,
                            ingresoExistente: ingreso,
                            ganadoAnterior: ingreso.ganado,
                          );
                        },

                        /// DELETE CON CONFIRMACIÓN
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
                                    "Eliminar ingreso",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    "¿Estás seguro de que quieres eliminar este ingreso?\nEsta acción no se puede deshacer.",
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
                              await context
                                  .read<IngresoProvider>()
                                  .eliminarIngreso(
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          mostrarFormularioIngreso(context, ganancia.documentId!);
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
