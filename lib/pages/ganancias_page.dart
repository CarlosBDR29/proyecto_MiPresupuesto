import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../widgets/custom_navbar.dart';
import '../providers/ganancia_provider.dart';
import '../providers/loginregistro_provider.dart';
import '../providers/categoria_provider.dart';
import '../models/ganancia.dart';
import '../models/categoria.dart';

class GananciasPage extends StatefulWidget {
  const GananciasPage({super.key});

  @override
  State<GananciasPage> createState() => _GananciasPageState();
}

class _GananciasPageState extends State<GananciasPage> {
  String textoBusqueda = "";
  String filtroEstado = "Todos";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final loginProvider = context.read<LoginRegistroProvider>();
      final gananciaProvider = context.read<GananciaProvider>();
      final categoriaProvider = context.read<CategoriaProvider>();

      final idUsu = loginProvider.usuario!.documentId!;
      gananciaProvider.obtenerGananciasUsuario(idUsu);
      categoriaProvider.obtenerCategoriasUsuario(idUsu);
    });
  }

  void mostrarFormulario() {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final objetivoController = TextEditingController();

    DateTime? inicio;
    DateTime? fin;
    Categoria? categoriaSeleccionada;
    final categorias = context.read<CategoriaProvider>().categorias;

    void mostrarError(String mensaje) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Ganancia"),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
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
                  controller: objetivoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: "Objetivo (€)"),
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
                    if (fecha != null) setState(() => inicio = fecha);
                  },
                ),
                ElevatedButton(
                  child: Text(
                    fin == null ? "Fecha fin" : fin.toString().split(' ')[0],
                  ),
                  onPressed: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      firstDate: inicio ?? DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: inicio ?? DateTime.now(),
                    );
                    if (fecha != null) setState(() => fin = fecha);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Categoria?>(
                  value: categoriaSeleccionada,
                  hint: const Text("Seleccionar categoría"),
                  items: [
                    const DropdownMenuItem<Categoria?>(
                      value: null,
                      child: Text("Sin categoría"),
                    ),
                    ...categorias.map(
                      (categoria) => DropdownMenuItem(
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
            onPressed: () async {
              if (tituloController.text.isEmpty ||
                  descripcionController.text.isEmpty ||
                  objetivoController.text.isEmpty ||
                  inicio == null ||
                  fin == null) {
                mostrarError("Completa todos los campos");
                return;
              }

              final objetivo = double.tryParse(
                objetivoController.text.replaceAll(',', '.'),
              );
              if (objetivo == null) {
                mostrarError("Introduce un número válido en el objetivo");
                return;
              }

              final loginProvider = context.read<LoginRegistroProvider>();
              final gananciaProvider = context.read<GananciaProvider>();

              Ganancia nueva = Ganancia(
                titulo: tituloController.text,
                descripcion: descripcionController.text,
                fechaInicio: inicio!,
                fechaFin: fin!,
                objetivo: objetivo,
                ganado: 0,
                faltante: objetivo,
                estado: "Activo",
                idTag: categoriaSeleccionada?.documentId,
                tag: categoriaSeleccionada?.titulo,
                idUsu: loginProvider.usuario!.documentId!,
              );

              await gananciaProvider.agregarGanancia(nueva);
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GananciaProvider>();
    final size = MediaQuery.of(context).size;
    final isLarge = size.width > 800;

    final gananciasFiltradas = provider.ganancias.where((g) {
      final coincideBusqueda = g.titulo.toLowerCase().contains(
        textoBusqueda.toLowerCase(),
      );
      final coincideEstado = filtroEstado == "Todos"
          ? true
          : g.estado == filtroEstado;
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
            Center(
              child: Column(
                children: [
                  const Text(
                    "Ganancias",
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

            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLarge ? 500 : double.infinity,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Buscar ganancia...",
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

            ...gananciasFiltradas.map((g) => _buildGananciaCard(g)).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: mostrarFormulario,
        backgroundColor: Colors.green,
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

  Widget _buildGananciaCard(Ganancia g) {
    final faltanteVisible = g.faltante < 0 ? 0 : g.faltante;
    final porcentaje = g.objetivo > 0
        ? ((g.ganado / g.objetivo) * 100).clamp(0, 100)
        : 0;

    Color colorBarra;
    if (porcentaje < 60)
      colorBarra = Colors.red;
    else if (porcentaje < 90)
      colorBarra = Colors.orange;
    else
      colorBarra = Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/ganancia/${g.documentId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                g.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                g.descripcion,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Inicio: ${g.fechaInicio.toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "Fin: ${g.fechaFin.toString().split(' ')[0]}",
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
                "${porcentaje.toStringAsFixed(1)}% alcanzado",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorBarra,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ganado: ${g.ganado.toStringAsFixed(2)}€"),
                  Text("Objetivo: ${g.objetivo.toStringAsFixed(2)}€"),
                  Text("Faltante: ${faltanteVisible.toStringAsFixed(2)}€"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(g.estado),
                    backgroundColor: g.estado == "Activo"
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                  if (g.tag != null)
                    Chip(
                      label: Text(g.tag!),
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
