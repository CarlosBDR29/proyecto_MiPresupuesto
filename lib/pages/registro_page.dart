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
      backgroundColor: const Color.fromARGB(255, 223, 248, 193),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth;

            if (constraints.maxWidth > 1000) {
              maxWidth = 450; // Desktop
            } else if (constraints.maxWidth > 600) {
              maxWidth = 400; // Tablet
            } else {
              maxWidth = constraints.maxWidth; // Móvil
            }

            return SingleChildScrollView(
              child: Container(
                width: maxWidth,
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🟢 LOGO
                        Image.asset(
                          'assets/images/LogoMyBudget.png',
                          height: 90,
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "Crear cuenta en MyBudget",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),

                        // 📧 Correo
                        TextField(
                          controller: correoController,
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E7D32),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🔒 Contraseña
                        TextField(
                          controller: contrasenaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E7D32),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🔒 Repetir contraseña
                        TextField(
                          controller: repetirContrasenaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Repetir contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E7D32),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        cargando
                            ? const CircularProgressIndicator(
                                color: Color(0xFF2E7D32),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 3,
                                  ),
                                  onPressed: () async {
                                    final correo = correoController.text.trim();
                                    final contrasena = contrasenaController.text
                                        .trim();
                                    final repetir = repetirContrasenaController
                                        .text
                                        .trim();

                                    if (contrasena != repetir) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Las contraseñas no coinciden',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => cargando = true);
                                    String? error = await provider
                                        .registrarUsuario(
                                          Usuario(
                                            correo: correo,
                                            contrasena: contrasena,
                                          ),
                                        );
                                    setState(() => cargando = false);

                                    if (error != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.red.shade400,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Usuario registrado'),
                                        ),
                                      );
                                      context.go('/login');
                                    }
                                  },
                                  child: const Text(
                                    'Registrar',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            '¿Ya tienes cuenta? Inicia sesión',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
