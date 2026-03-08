import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/presupuesto.dart';

class PresupuestoProvider extends ChangeNotifier {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Presupuesto> _presupuestos = [];

  List<Presupuesto> get presupuestos => _presupuestos;

  // AGREGAR PRESUPUESTO
  Future<void> agregarPresupuesto(Presupuesto presupuesto) async {
    try {

      final docRef = _firestore.collection('presupuestos').doc();

      presupuesto.documentId = docRef.id;

      // calcular restante
      presupuesto.restante =
          Presupuesto.calcularRestante(presupuesto.limite, presupuesto.gastado);

      // calcular estado
      presupuesto.estado =
          Presupuesto.calcularEstado(presupuesto.fechaInicio, presupuesto.fechaFin);

      debugPrint(
        'Guardando presupuesto ID: ${presupuesto.documentId}, Titulo: ${presupuesto.titulo}',
      );

      await docRef.set({'presupuesto': presupuesto.toJson()});

      _presupuestos.add(presupuesto);

      notifyListeners();

    } catch (e) {
      debugPrint('Error al agregar presupuesto: $e');
      rethrow;
    }
  }

  // OBTENER PRESUPUESTOS DEL USUARIO
  Future<void> obtenerPresupuestosUsuario(String idUsu) async {
    try {

      final query = await _firestore
          .collection('presupuestos')
          .where('presupuesto.idUsu', isEqualTo: idUsu)
          .get();

      _presupuestos.clear();

      for (var doc in query.docs) {

        final data = doc.data()['presupuesto'];

        Presupuesto presupuesto = Presupuesto.fromJson(data);

        _presupuestos.add(presupuesto);
      }

      notifyListeners();

    } catch (e) {
      debugPrint('Error al obtener presupuestos: $e');
    }
  }

  // EDITAR PRESUPUESTO
  Future<void> editarPresupuesto(Presupuesto presupuesto) async {
    try {

      presupuesto.restante =
          Presupuesto.calcularRestante(presupuesto.limite, presupuesto.gastado);

      presupuesto.estado =
          Presupuesto.calcularEstado(presupuesto.fechaInicio, presupuesto.fechaFin);

      await _firestore
          .collection('presupuestos')
          .doc(presupuesto.documentId)
          .update({'presupuesto': presupuesto.toJson()});

      int index = _presupuestos.indexWhere(
        (p) => p.documentId == presupuesto.documentId,
      );

      if (index != -1) {
        _presupuestos[index] = presupuesto;
      }

      notifyListeners();

    } catch (e) {
      debugPrint('Error al editar presupuesto: $e');
      rethrow;
    }
  }

  // ELIMINAR PRESUPUESTO
  Future<void> eliminarPresupuesto(String documentId) async {
    try {

      await _firestore
          .collection('presupuestos')
          .doc(documentId)
          .delete();

      _presupuestos.removeWhere((p) => p.documentId == documentId);

      notifyListeners();

    } catch (e) {
      debugPrint('Error al eliminar presupuesto: $e');
      rethrow;
    }
  }

}