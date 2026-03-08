import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria.dart';

class CategoriaProvider extends ChangeNotifier {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Categoria> _categorias = [];

  List<Categoria> get categorias => _categorias;

  // AGREGAR CATEGORIA
  Future<void> agregarCategoria(Categoria categoria) async {
    try {
      final docRef = _firestore.collection('categorias').doc();

      categoria.documentId = docRef.id;

      debugPrint(
        'Guardando categoria ID: ${categoria.documentId}, Titulo: ${categoria.titulo}',
      );

      await docRef.set({'categoria': categoria.toJson()});

      _categorias.add(categoria);

      notifyListeners();

    } catch (e) {
      debugPrint('Error al agregar categoria: $e');
      rethrow;
    }
  }

  // OBTENER CATEGORIAS DE UN USUARIO
  Future<void> obtenerCategoriasUsuario(String idUsu) async {
    try {

      final query = await _firestore
          .collection('categorias')
          .where('categoria.idUsu', isEqualTo: idUsu)
          .get();

      _categorias.clear();

      for (var doc in query.docs) {
        final data = doc.data()['categoria'];
        Categoria categoria = Categoria.fromJson(data);
        _categorias.add(categoria);
      }

      notifyListeners();

    } catch (e) {
      debugPrint('Error al obtener categorias: $e');
    }
  }

  // EDITAR CATEGORIA
  Future<void> editarCategoria(Categoria categoria) async {
    try {

      await _firestore
          .collection('categorias')
          .doc(categoria.documentId)
          .update({'categoria': categoria.toJson()});

      int index =
          _categorias.indexWhere((c) => c.documentId == categoria.documentId);

      if (index != -1) {
        _categorias[index] = categoria;
      }

      notifyListeners();

    } catch (e) {
      debugPrint('Error al editar categoria: $e');
      rethrow;
    }
  }

  // ELIMINAR CATEGORIA
  Future<void> eliminarCategoria(String documentId) async {
    try {

      await _firestore
          .collection('categorias')
          .doc(documentId)
          .delete();

      _categorias.removeWhere((c) => c.documentId == documentId);

      notifyListeners();

    } catch (e) {
      debugPrint('Error al eliminar categoria: $e');
      rethrow;
    }
  }

}