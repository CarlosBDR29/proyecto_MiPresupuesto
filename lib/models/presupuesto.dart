class Presupuesto {

  // Propiedades
  String? documentId;
  String titulo;
  String descripcion;

  DateTime fechaInicio;
  DateTime fechaFin;

  double gastado;
  double limite;
  double restante;

  String estado;

  String idUsu;

  String? idTag;
  String? tag;

  // Constructor
  Presupuesto({
    this.documentId,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    this.gastado = 0,
    required this.limite,
    required this.restante,
    required this.estado,
    required this.idUsu,
    this.idTag,
    this.tag,
  });

  // Calcular restante
  static double calcularRestante(double limite, double gastado) {
    return limite - gastado;
  }

  // Calcular estado según la fecha
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

  // Convertir a Map (guardar en Firestore)
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'gastado': gastado,
      'limite': limite,
      'restante': restante,
      'estado': estado,
      'idUsu': idUsu,
      'idTag': idTag,
      'tag': tag,
    };
  }

  // Crear objeto desde Map (leer de Firestore)
  factory Presupuesto.fromJson(Map<String, dynamic> json) {
    return Presupuesto(
      documentId: json['documentId'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
      gastado: (json['gastado'] ?? 0).toDouble(),
      limite: (json['limite']).toDouble(),
      restante: (json['restante']).toDouble(),
      estado: json['estado'],
      idUsu: json['idUsu'],
      idTag: json['idTag'],
      tag: json['tag'],
    );
  }

}