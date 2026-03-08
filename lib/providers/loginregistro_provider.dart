import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/usuario.dart';

class LoginRegistroProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Usuario> _usuarios = [];

  List<Usuario> get usuarios => _usuarios;

  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  // CIFRAR CONTRASEÑA
  String cifrarContrasena(String contrasena) {
    final bytes = utf8.encode(contrasena);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // REGISTRAR USUARIO
  Future<String?> registrarUsuario(Usuario usuario) async {
    try {
      // comprobar si el correo ya existe
      final query = await _firestore
          .collection('usuarios')
          .where('usuario.correo', isEqualTo: usuario.correo)
          .get();

      if (query.docs.isNotEmpty) {
        return 'El correo ya está registrado';
      }

      final docRef = _firestore.collection('usuarios').doc();

      usuario.documentId = docRef.id;

      // cifrar contraseña
      usuario.contrasena = cifrarContrasena(usuario.contrasena);

      debugPrint(
        'Guardando usuario ID: ${usuario.documentId}, Correo: ${usuario.correo}',
      );

      await docRef.set({'usuario': usuario.toJson()});

      _usuarios.add(usuario);

      notifyListeners();

      return null;
    } catch (e) {
      debugPrint('Error al registrar usuario: $e');
      return 'Error al registrar usuario';
    }
  }

  // LOGIN USUARIO
  Future<String?> loginUsuario(String correo, String contrasena) async {
    try {
      final query = await _firestore
          .collection('usuarios')
          .where('usuario.correo', isEqualTo: correo)
          .get();

      if (query.docs.isEmpty) {
        return 'Usuario no encontrado';
      }

      final doc = query.docs.first;

      final data = doc.data();
      final usuarioData = data['usuario'];

      final contrasenaCifrada = cifrarContrasena(contrasena);

      if (usuarioData['contrasena'] != contrasenaCifrada) {
        return 'Contraseña incorrecta';
      }

      // crear objeto usuario
      _usuario = Usuario.fromJson(usuarioData);
      _usuario!.documentId = doc.id;

      debugPrint('Login correcto: $correo');

      notifyListeners();

      return null;
    } catch (e) {
      debugPrint('Error en login: $e');
      return 'Error al iniciar sesión';
    }
  }

  // LOGOUT
  Future<void> logoutUsuario() async {
    _usuario = null;
    _usuarios.clear();
    notifyListeners();
  }
}
