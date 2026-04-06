import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ganancia.dart';

class GananciaProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Ganancia> _ganancias = [];

  List<Ganancia> get ganancias => _ganancias;

  // AGREGAR GANANCIA
  Future<void> agregarGanancia(Ganancia ganancia) async {
    try {
      final docRef = _firestore.collection('ganancias').doc();

      ganancia.documentId = docRef.id;

      // calcular faltante
      ganancia.faltante = Ganancia.calcularFaltante(
        ganancia.objetivo,
        ganancia.ganado,
      );

      // calcular estado
      ganancia.estado = Ganancia.calcularEstado(
        ganancia.fechaInicio,
        ganancia.fechaFin,
      );

      debugPrint(
        'Guardando ganancia ID: ${ganancia.documentId}, Titulo: ${ganancia.titulo}',
      );

      await docRef.set({'ganancia': ganancia.toJson()});

      _ganancias.add(ganancia);

      notifyListeners();
    } catch (e) {
      debugPrint('Error al agregar ganancia: $e');
      rethrow;
    }
  }

  // OBTENER GANANCIAS DEL USUARIO
  Future<void> obtenerGananciasUsuario(String idUsu) async {
    try {
      final query = await _firestore
          .collection('ganancias')
          .where('ganancia.idUsu', isEqualTo: idUsu)
          .get();

      _ganancias.clear();

      for (var doc in query.docs) {
        final data = doc.data()['ganancia'];

        Ganancia ganancia = Ganancia.fromJson(data);

        _ganancias.add(ganancia);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al obtener ganancias: $e');
    }
  }

  // EDITAR GANANCIA
  Future<void> editarGanancia(Ganancia ganancia) async {
    try {
      ganancia.faltante = Ganancia.calcularFaltante(
        ganancia.objetivo,
        ganancia.ganado,
      );

      ganancia.estado = Ganancia.calcularEstado(
        ganancia.fechaInicio,
        ganancia.fechaFin,
      );

      await _firestore.collection('ganancias').doc(ganancia.documentId).update({
        'ganancia': ganancia.toJson(),
      });

      int index = _ganancias.indexWhere(
        (g) => g.documentId == ganancia.documentId,
      );

      if (index != -1) {
        _ganancias[index] = ganancia;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al editar ganancia: $e');
      rethrow;
    }
  }

  // ELIMINAR GANANCIA
  Future<void> eliminarGanancia(String documentId) async {
    try {
      final batch = _firestore.batch();

      // 🔹 Buscar ingresos asociados (campo anidado)
      final ingresosSnapshot = await _firestore
          .collection('ingresos')
          .where('ingreso.idGanancia', isEqualTo: documentId)
          .get();

      for (var doc in ingresosSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 🔹 Borrar ganancia
      final gananciaRef = _firestore.collection('ganancias').doc(documentId);

      batch.delete(gananciaRef);

      await batch.commit();

      _ganancias.removeWhere((g) => g.documentId == documentId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar ganancia: $e');
      rethrow;
    }
  }
}
