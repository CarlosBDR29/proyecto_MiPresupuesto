import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_navbar.dart';
import '../providers/presupuesto_provider.dart';
import '../providers/ganancia_provider.dart';
import '../providers/categoria_provider.dart';
import '../models/categoria.dart';

class CategoriasPage extends StatefulWidget {
  final String idUsu;

  const CategoriasPage({super.key, required this.idUsu});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  String textoBusqueda = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CategoriaProvider>().obtenerCategoriasUsuario(widget.idUsu);
    });
  }

  void mostrarFormulario({Categoria? categoria}) {
    final tituloController = TextEditingController(
      text: categoria?.titulo ?? '',
    );
    final descripcionController = TextEditingController(
      text: categoria?.descripcion ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            categoria == null ? 'Nueva Categoría' : 'Editar Categoría',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Guardar'),
              onPressed: () async {
                final provider = context.read<CategoriaProvider>();

                if (tituloController.text.isEmpty) return;

                if (categoria == null) {
                  Categoria nueva = Categoria(
                    titulo: tituloController.text,
                    descripcion: descripcionController.text,
                    idUsu: widget.idUsu,
                  );

                  await provider.agregarCategoria(nueva);
                } else {
                  categoria.titulo = tituloController.text;
                  categoria.descripcion = descripcionController.text;

                  await provider.editarCategoria(categoria);
                }

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
    final provider = context.watch<CategoriaProvider>();
    final size = MediaQuery.of(context).size;
    final isLarge = size.width > 800;

    final categoriasFiltradas = provider.categorias.where((c) {
      return c.titulo.toLowerCase().contains(textoBusqueda.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: const CustomNavbar(),
      backgroundColor: const Color.fromARGB(255, 223, 248, 193),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 80 : 16,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 🔹 TÍTULO GRANDE
            Center(
              child: Column(
                children: [
                  const Text(
                    "Categorías",
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

            const SizedBox(height: 25),

            /// 🔍 BUSCADOR ESTILIZADO
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLarge ? 500 : double.infinity,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Buscar categoría...",
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

            const SizedBox(height: 25),

            /// 📦 LISTA DE CATEGORÍAS
            if (categoriasFiltradas.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    "No hay categorías",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              ...categoriasFiltradas
                  .map((categoria) => _buildCategoriaCard(categoria))
                  .toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          mostrarFormulario();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoriaCard(Categoria categoria) {
    final presupuestos = context.watch<PresupuestoProvider>().presupuestos;
    final ganancias = context.watch<GananciaProvider>().ganancias;

    final totalPresupuestos = presupuestos
        .where((p) => p.idTag == categoria.documentId)
        .length;

    final totalGanancias = ganancias
        .where((g) => g.idTag == categoria.documentId)
        .length;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Título
            Text(
              categoria.titulo,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            /// 🔹 Descripción
            Text(
              categoria.descripcion,
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 15),

            /// 📊 Estadísticas
            Row(
              children: [
                _buildStatBox(
                  icon: Icons.account_balance_wallet,
                  label: "Presupuestos",
                  value: totalPresupuestos.toString(),
                ),

                const SizedBox(width: 15),

                _buildStatBox(
                  icon: Icons.trending_up,
                  label: "Ganancias",
                  value: totalGanancias.toString(),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    mostrarFormulario(categoria: categoria);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    context.read<CategoriaProvider>().eliminarCategoria(
                      categoria.documentId!,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
