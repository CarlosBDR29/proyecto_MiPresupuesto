class Ganancia {

  // Propiedades
  String? documentId;
  String titulo;
  String descripcion;

  DateTime fechaInicio;
  DateTime fechaFin;

  double ganado;
  double objetivo;
  double faltante;

  String estado;

  String idUsu;

  String? idTag;
  String? tag;

  // Constructor
  Ganancia({
    this.documentId,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    this.ganado = 0,
    required this.objetivo,
    required this.faltante,
    required this.estado,
    required this.idUsu,
    this.idTag,
    this.tag,
  });

  // Calcular faltante
  static double calcularFaltante(double objetivo, double ganado) {
    return objetivo - ganado;
  }

  // Calcular estado según fecha
  static String calcularEstado(DateTime inicio, DateTime fin) {
    final ahora = DateTime.now();

    if (ahora.isBefore(inicio)) {
      return 'En espera';
    } else if (ahora.isAfter(fin)) {
      return 'Finalizado';
    } else {
      return 'En curso';
    }
  }

  // Convertir a Map (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'ganado': ganado,
      'objetivo': objetivo,
      'faltante': faltante,
      'estado': estado,
      'idUsu': idUsu,
      'idTag': idTag,
      'tag': tag,
    };
  }

  // Crear desde Map
  factory Ganancia.fromJson(Map<String, dynamic> json) {
    return Ganancia(
      documentId: json['documentId'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
      ganado: (json['ganado'] ?? 0).toDouble(),
      objetivo: (json['objetivo']).toDouble(),
      faltante: (json['faltante']).toDouble(),
      estado: json['estado'],
      idUsu: json['idUsu'],
      idTag: json['idTag'],
      tag: json['tag'],
    );
  }

}