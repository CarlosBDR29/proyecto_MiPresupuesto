import 'dart:typed_data';

class Ingreso {

  String? documentId;

  String titulo;
  DateTime fecha;
  double ganado;
  String descripcion;

  Uint8List? photoBytes;

  String idUsu;
  String idGanancia;

  Ingreso({
    this.documentId,
    required this.titulo,
    required this.fecha,
    required this.ganado,
    required this.descripcion,
    this.photoBytes,
    required this.idUsu,
    required this.idGanancia,
  });

  // FROM JSON
  factory Ingreso.fromJson(Map<String, dynamic> json) {
    return Ingreso(
      documentId: json['documentId'],
      titulo: json['titulo'],
      fecha: DateTime.parse(json['fecha']),
      ganado: (json['ganado'] as num).toDouble(),
      descripcion: json['descripcion'],
      photoBytes: json['photoBytes'] != null
          ? Uint8List.fromList(List<int>.from(json['photoBytes']))
          : null,
      idUsu: json['idUsu'],
      idGanancia: json['idGanancia'],
    );
  }

  // TO JSON
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'titulo': titulo,
      'fecha': fecha.toIso8601String(),
      'ganado': ganado,
      'descripcion': descripcion,
      'photoBytes': photoBytes,
      'idUsu': idUsu,
      'idGanancia': idGanancia,
    };
  }
}