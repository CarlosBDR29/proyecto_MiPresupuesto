class Categoria {

  // Propiedades
  String? documentId; // ID del documento en Firestore
  String titulo; // Título de la categoría
  String descripcion; // Descripción de la categoría
  String idUsu; // documentId del usuario

  // Constructor
  Categoria({
    this.documentId,
    required this.titulo,
    required this.descripcion,
    required this.idUsu,
  });

  // Convertir a Map (guardar en Firestore)
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'titulo': titulo,
      'descripcion': descripcion,
      'idUsu': idUsu,
    };
  }

  // Crear objeto desde Map (leer de Firestore)
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      documentId: json['documentId'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      idUsu: json['idUsu'],
    );
  }
}