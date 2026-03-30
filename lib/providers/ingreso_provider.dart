import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ingreso.dart';
import '../models/ganancia.dart';
import 'ganancia_provider.dart';

class IngresoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Ingreso> _ingresos = [];

  List<Ingreso> get ingresos => _ingresos;

  // AGREGAR INGRESO
  Future<void> agregarIngreso(
    Ingreso ingreso,
    GananciaProvider gananciaProvider,
  ) async {
    try {
      final docRef = _firestore.collection('ingresos').doc();
      ingreso.documentId = docRef.id;

      await docRef.set({'ingreso': ingreso.toJson()});
      _ingresos.add(ingreso);

      // ACTUALIZAR GANANCIA
      final ganancia = gananciaProvider.ganancias.firstWhere(
        (p) => p.documentId == ingreso.idGanancia,
      );

      ganancia.ganado += ingreso.ganado;

      await gananciaProvider.editarGanancia(ganancia);

      notifyListeners();
    } catch (e) {
      debugPrint("Error al agregar ingreso: $e");
      rethrow;
    }
  }

  // OBTENER INGRESOS DE UNA GANANCIA
  Future<void> obtenerIngresosGanancia(String idGanancia) async {
    try {
      final query = await _firestore
          .collection('ingresos')
          .where('ingreso.idGanancia', isEqualTo: idGanancia)
          .get();

      _ingresos.clear();

      for (var doc in query.docs) {
        final data = doc.data()['ingreso'];
        Ingreso ingreso = Ingreso.fromJson(data);
        _ingresos.add(ingreso);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error al obtener ingresos: $e");
    }
  }

  // EDITAR INGRESO
  Future<void> editarIngreso(
    Ingreso ingreso,
    GananciaProvider gananciaProvider,
    double ganadoAnterior,
  ) async {
    try {
      await _firestore.collection('ingresos').doc(ingreso.documentId).update({
        'ingreso': ingreso.toJson(),
      });

      int index = _ingresos.indexWhere(
        (i) => i.documentId == ingreso.documentId,
      );
      if (index != -1) _ingresos[index] = ingreso;

      // ACTUALIZAR GANANCIA
      final ganancia = gananciaProvider.ganancias.firstWhere(
        (p) => p.documentId == ingreso.idGanancia,
      );

      await _firestore.collection('ganancias').doc(ganancia.documentId).update({
        'ganancia': ganancia.toJson(),
      });

            ganancia.ganado =
          ganancia.ganado - ganadoAnterior + ingreso.ganado;

      await gananciaProvider.editarGanancia(ganancia);


      notifyListeners();
    } catch (e) {
      debugPrint("Error al editar ingreso: $e");
      rethrow;
    }
  }

  // ELIMINAR INGRESO
  Future<void> eliminarIngreso(Ingreso ingreso, GananciaProvider gananciaProvider) async {
    try {
      await _firestore.collection('ingresos').doc(ingreso.documentId).delete();
      _ingresos.removeWhere((i) => i.documentId == ingreso.documentId);

      // ACTUALIZAR GANANCIA
      final ganancia = gananciaProvider.ganancias.firstWhere(
        (p) => p.documentId == ingreso.idGanancia,
      );

      ganancia.ganado -= ingreso.ganado;

      await gananciaProvider.editarGanancia(ganancia);

      notifyListeners();
    } catch (e) {
      debugPrint("Error al eliminar ingreso: $e");
      rethrow;
    }
  }
}
