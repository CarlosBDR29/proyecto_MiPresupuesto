import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loginregistro_provider.dart';
import '../models/usuario.dart';
import 'package:go_router/go_router.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final TextEditingController repetirContrasenaController =
      TextEditingController();

  bool cargando = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LoginRegistroProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: contrasenaController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            TextField(
              controller: repetirContrasenaController,
              decoration: const InputDecoration(labelText: 'Repetir contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            cargando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      final correo = correoController.text.trim();
                      final contrasena = contrasenaController.text.trim();
                      final repetir = repetirContrasenaController.text.trim();

                      if (contrasena != repetir) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Las contraseñas no coinciden')),
                        );
                        return;
                      }

                      setState(() => cargando = true);
                      String? error = await provider.registrarUsuario(
                        Usuario(correo: correo, contrasena: contrasena),
                      );
                      setState(() => cargando = false);

                      if (error != null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(error)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuario registrado')),
                        );
                        context.go('/login');
                      }
                    },
                    child: const Text('Registrar'),
                  ),
          ],
        ),
      ),
    );
  }
}