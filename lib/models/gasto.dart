import 'dart:typed_data';

class Gasto {

  String? documentId;

  String titulo;
  DateTime fecha;
  double coste;
  String descripcion;

  Uint8List? photoBytes;

  String idUsu;
  String idPresu;

  Gasto({
    this.documentId,
    required this.titulo,
    required this.fecha,
    required this.coste,
    required this.descripcion,
    this.photoBytes,
    required this.idUsu,
    required this.idPresu,
  });

  // FROM JSON
  factory Gasto.fromJson(Map<String, dynamic> json) {

    return Gasto(
      documentId: json['documentId'],
      titulo: json['titulo'],
      fecha: DateTime.parse(json['fecha']),
      coste: (json['coste'] as num).toDouble(),
      descripcion: json['descripcion'],
      photoBytes: json['photoBytes'] != null
          ? Uint8List.fromList(List<int>.from(json['photoBytes']))
          : null,
      idUsu: json['idUsu'],
      idPresu: json['idPresu'],
    );
  }

  // TO JSON
  Map<String, dynamic> toJson() {

    return {
      'documentId': documentId,
      'titulo': titulo,
      'fecha': fecha.toIso8601String(),
      'coste': coste,
      'descripcion': descripcion,
      'photoBytes': photoBytes,
      'idUsu': idUsu,
      'idPresu': idPresu,
    };
  }
}