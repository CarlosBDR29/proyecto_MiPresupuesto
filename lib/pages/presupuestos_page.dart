import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../widgets/custom_navbar.dart';
import '../providers/presupuesto_provider.dart';
import '../providers/loginregistro_provider.dart';
import '../providers/categoria_provider.dart';
import '../models/presupuesto.dart';
import '../models/categoria.dart';

class PresupuestosPage extends StatefulWidget {
  const PresupuestosPage({super.key});

  @override
  State<PresupuestosPage> createState() => _PresupuestosPageState();
}

class _PresupuestosPageState extends State<PresupuestosPage> {
  String textoBusqueda = "";
  String filtroEstado = "Todos";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final loginProvider = context.read<LoginRegistroProvider>();
      final presupuestoProvider = context.read<PresupuestoProvider>();
      final categoriaProvider = context.read<CategoriaProvider>();

      final idUsu = loginProvider.usuario!.documentId!;
      presupuestoProvider.obtenerPresupuestosUsuario(idUsu);
      categoriaProvider.obtenerCategoriasUsuario(idUsu);
    });
  }

  void mostrarFormulario() {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final limiteController = TextEditingController();

    DateTime? fechaInicio;
    DateTime? fechaFin;
    Categoria? categoriaSeleccionada;

    final categorias = context.read<CategoriaProvider>().categorias;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Nuevo Presupuesto",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: tituloController,
                    decoration: const InputDecoration(
                      labelText: "Título",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: "Descripción",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: limiteController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Límite (€)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => fechaInicio = picked);
                    },
                    child: Text(
                      fechaInicio == null
                          ? "Seleccionar fecha inicio"
                          : "Inicio: ${fechaInicio.toString().split(' ')[0]}",
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (fechaInicio == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Selecciona primero la fecha de inicio",
                            ),
                          ),
                        );
                        return;
                      }
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: fechaInicio!,
                        lastDate: DateTime(2100),
                        initialDate: fechaInicio!,
                      );
                      if (picked != null) setState(() => fechaFin = picked);
                    },
                    child: Text(
                      fechaFin == null
                          ? "Seleccionar fecha fin"
                          : "Fin: ${fechaFin.toString().split(' ')[0]}",
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<Categoria?>(
                    value: categoriaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: "Categoría",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<Categoria?>(
                        value: null,
                        child: Text("Sin categoría"),
                      ),
                      ...categorias.map(
                        (categoria) => DropdownMenuItem<Categoria?>(
                          value: categoria,
                          child: Text(categoria.titulo),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => categoriaSeleccionada = value),
                  ),
                ],
              ),
            ),
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
                    limiteController.text.isEmpty ||
                    fechaInicio == null ||
                    fechaFin == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Completa todos los campos obligatorios"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final limite = double.tryParse(
                  limiteController.text.replaceAll(',', '.'),
                );
                if (limite == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Introduce un número válido en el límite"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final loginProvider = context.read<LoginRegistroProvider>();
                final presupuestoProvider = context.read<PresupuestoProvider>();

                Presupuesto nuevo = Presupuesto(
                  titulo: tituloController.text,
                  descripcion: descripcionController.text,
                  fechaInicio: fechaInicio!,
                  fechaFin: fechaFin!,
                  limite: limite,
                  restante: limite,
                  gastado: 0,
                  estado: "Activo",
                  idTag: categoriaSeleccionada?.documentId,
                  tag: categoriaSeleccionada?.titulo,
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
    final size = MediaQuery.of(context).size;
    final isLarge = size.width > 800;

    final presupuestosFiltrados = provider.presupuestos.where((p) {
      final coincideBusqueda = p.titulo.toLowerCase().contains(
        textoBusqueda.toLowerCase(),
      );
      final coincideEstado = filtroEstado == "Todos"
          ? true
          : p.estado == filtroEstado;
      return coincideBusqueda && coincideEstado;
    }).toList();

    return Scaffold(
      appBar: const CustomNavbar(),
      backgroundColor: const Color.fromARGB(255, 223, 248, 193),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 80 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TÍTULO
            Center(
              child: Column(
                children: [
                  const Text(
                    "Presupuestos",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BUSCADOR
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLarge ? 500 : double.infinity,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Buscar presupuesto...",
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => textoBusqueda = value),
              ),
            ),
            const SizedBox(height: 15),

            // FILTRO ESTADO
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFiltroChip("Todos"),
                _buildFiltroChip("En curso"),
                _buildFiltroChip("Finalizado"),
              ],
            ),
            const SizedBox(height: 20),

            // LISTA DE PRESUPUESTOS
            ...presupuestosFiltrados
                .map((p) => _buildPresupuestoCard(p))
                .toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: mostrarFormulario,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltroChip(String estado) {
    final seleccionado = filtroEstado == estado;
    return ChoiceChip(
      label: Text(estado),
      selected: seleccionado,
      selectedColor: Colors.green,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => filtroEstado = estado),
    );
  }

  Widget _buildPresupuestoCard(Presupuesto presupuesto) {
    final porcentaje = presupuesto.limite > 0
        ? ((presupuesto.gastado / presupuesto.limite) * 100).clamp(0, 100)
        : 0;
    final restanteVisible = presupuesto.restante < 0 ? 0 : presupuesto.restante;

    Color colorBarra;
    if (porcentaje < 60)
      colorBarra = Colors.green;
    else if (porcentaje < 90)
      colorBarra = Colors.orange;
    else
      colorBarra = Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/presupuesto/${presupuesto.documentId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                presupuesto.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                presupuesto.descripcion,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Inicio: ${presupuesto.fechaInicio.toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "Fin: ${presupuesto.fechaFin.toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: porcentaje / 100,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
                color: colorBarra,
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 6),
              Text(
                "${porcentaje.toStringAsFixed(1)}% utilizado",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorBarra,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Gastado: ${presupuesto.gastado.toStringAsFixed(2)}€"),
                  Text("Límite: ${presupuesto.limite.toStringAsFixed(2)}€"),
                  Text("Restante: ${restanteVisible.toStringAsFixed(2)}€"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(presupuesto.estado),
                    backgroundColor: presupuesto.estado == "Activo"
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                  if (presupuesto.tag != null)
                    Chip(
                      label: Text(presupuesto.tag!),
                      backgroundColor: Colors.blue.shade100,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
