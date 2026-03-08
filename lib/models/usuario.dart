class Usuario {

  // Propiedades
  String? documentId; // ID del documento en Firestore
  String correo;
  String contrasena;

  // Constructor
  Usuario({
    this.documentId,
    required this.correo,
    required this.contrasena,
  });

  // Convertir el objeto a Map (para guardar en Firestore)
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'correo': correo,
      'contrasena': contrasena,
    };
  }

  // Crear objeto desde Map (cuando leemos de Firestore)
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      documentId: json['documentId'],
      correo: json['correo'],
      contrasena: json['contrasena'],
    );
  }
}