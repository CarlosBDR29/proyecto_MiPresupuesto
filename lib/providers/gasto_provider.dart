import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gasto.dart';
import '../models/presupuesto.dart';
import 'presupuesto_provider.dart';

class GastoProvider extends ChangeNotifier {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  List<Gasto> _gastos = [];

  List<Gasto> get gastos => _gastos;

  // AGREGAR GASTO
  Future<void> agregarGasto(
    Gasto gasto,
    PresupuestoProvider presupuestoProvider,
  ) async {

    try {

      final docRef = _firestore.collection('gastos').doc();

      gasto.documentId = docRef.id;

      await docRef.set({
        'gasto': gasto.toJson(),
      });

      _gastos.add(gasto);

      // ACTUALIZAR PRESUPUESTO
      final presupuesto = presupuestoProvider.presupuestos.firstWhere(
        (p) => p.documentId == gasto.idPresu,
      );

      presupuesto.gastado += gasto.coste;

      await presupuestoProvider.editarPresupuesto(presupuesto);

      notifyListeners();

    } catch (e) {
      debugPrint("Error al agregar gasto: $e");
      rethrow;
    }
  }

  // OBTENER GASTOS DE UN PRESUPUESTO
  Future<void> obtenerGastosPresupuesto(String idPresu) async {

    try {

      final query = await _firestore
          .collection('gastos')
          .where('gasto.idPresu', isEqualTo: idPresu)
          .get();

      _gastos.clear();

      for (var doc in query.docs) {

        final data = doc.data()['gasto'];

        Gasto gasto = Gasto.fromJson(data);

        _gastos.add(gasto);
      }

      notifyListeners();

    } catch (e) {
      debugPrint("Error al obtener gastos: $e");
    }
  }

  // EDITAR GASTO
  Future<void> editarGasto(
    Gasto gasto,
    PresupuestoProvider presupuestoProvider,
    double costeAnterior,
  ) async {

    try {

      await _firestore
          .collection('gastos')
          .doc(gasto.documentId)
          .update({
        'gasto': gasto.toJson(),
      });

      int index = _gastos.indexWhere(
        (g) => g.documentId == gasto.documentId,
      );

      if (index != -1) {
        _gastos[index] = gasto;
      }

      // ACTUALIZAR PRESUPUESTO
      final presupuesto = presupuestoProvider.presupuestos.firstWhere(
        (p) => p.documentId == gasto.idPresu,
      );

      presupuesto.gastado =
          presupuesto.gastado - costeAnterior + gasto.coste;

      await presupuestoProvider.editarPresupuesto(presupuesto);

      notifyListeners();

    } catch (e) {
      debugPrint("Error al editar gasto: $e");
      rethrow;
    }
  }

  // ELIMINAR GASTO
  Future<void> eliminarGasto(
    Gasto gasto,
    PresupuestoProvider presupuestoProvider,
  ) async {

    try {

      await _firestore
          .collection('gastos')
          .doc(gasto.documentId)
          .delete();

      _gastos.removeWhere(
        (g) => g.documentId == gasto.documentId,
      );

      // ACTUALIZAR PRESUPUESTO
      final presupuesto = presupuestoProvider.presupuestos.firstWhere(
        (p) => p.documentId == gasto.idPresu,
      );

      presupuesto.gastado -= gasto.coste;

      await presupuestoProvider.editarPresupuesto(presupuesto);

      notifyListeners();

    } catch (e) {
      debugPrint("Error al eliminar gasto: $e");
      rethrow;
    }
  }

}