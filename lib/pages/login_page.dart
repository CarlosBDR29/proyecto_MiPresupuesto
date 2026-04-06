import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loginregistro_provider.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
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
              maxWidth = 450; // Desktop grande
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
                        Image.asset(
                          'assets/images/LogoMyBudget.png',
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Bienvenido a MyBudget",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
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
                                    setState(() => cargando = true);
                                    String? error = await provider.loginUsuario(
                                      correoController.text.trim(),
                                      contrasenaController.text.trim(),
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
                                      context.go('/menu');
                                    }
                                  },
                                  child: const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => context.go('/registro'),
                          child: const Text(
                            '¿No tienes cuenta? Regístrate',
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
