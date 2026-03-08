import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/categoria_provider.dart';
import '../models/categoria.dart';

class CategoriasPage extends StatefulWidget {
  final String idUsu;

  const CategoriasPage({super.key, required this.idUsu});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CategoriaProvider>()
          .obtenerCategoriasUsuario(widget.idUsu);
    });
  }

  void mostrarFormulario({Categoria? categoria}) {

    final tituloController =
        TextEditingController(text: categoria?.titulo ?? '');
    final descripcionController =
        TextEditingController(text: categoria?.descripcion ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {

                final provider = context.read<CategoriaProvider>();

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
    final categorias = provider.categorias;

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: categorias.isEmpty
          ? const Center(child: Text('No hay categorías'))
          : ListView.builder(
              itemCount: categorias.length,
              itemBuilder: (context, index) {

                final categoria = categorias[index];

                return ListTile(
                  title: Text(categoria.titulo),
                  subtitle: Text(categoria.descripcion),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          mostrarFormulario(categoria: categoria);
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          context.read<CategoriaProvider>()
                              .eliminarCategoria(categoria.documentId!);
                        },
                      ),

                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          mostrarFormulario();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}