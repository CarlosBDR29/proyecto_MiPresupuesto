import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
//import 'package:file_picker/file_picker.dart';

import 'routes/rutas.dart';
// import 'providers/auth_provider.dart';  // Lo crearemos después
import 'providers/loginregistro_provider.dart';
import 'providers/categoria_provider.dart';
import 'providers/presupuesto_provider.dart';
import 'providers/gasto_provider.dart';
import 'providers/ganancia_provider.dart';
import 'providers/ingreso_provider.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // 2️⃣ Inicializar Firebase (Web compatible)
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Aquí agregaremos nuestros providers
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LoginRegistroProvider()),
        ChangeNotifierProvider(create: (_) => CategoriaProvider()),
        ChangeNotifierProvider(create: (_) => PresupuestoProvider()),
        ChangeNotifierProvider(create: (_) => GastoProvider()),
        ChangeNotifierProvider(create: (_) => GananciaProvider()),
        ChangeNotifierProvider(create: (_) => IngresoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Proyecto Final',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
