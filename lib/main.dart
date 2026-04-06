import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/clientes_provider.dart';
import 'providers/prestamos_provider.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/prestamos/prestamos_screen.dart';
import 'screens/prestamos/detalle_cliente_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar FFI para soporte de SQLite en Escritorio (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientesProvider()),
        ChangeNotifierProvider(create: (_) => PrestamosProvider()),
      ],
      child: MaterialApp(
        title: 'Finance App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.tealAccent,
            brightness: Brightness.dark,
            primary: const Color(0xFF00E676), // Emerald contrast
            onPrimary: Colors.black,
            surface: const Color(0xFF1E1E1E),
            surfaceContainerHighest: const Color(0xFF2C2C2C),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/home': (context) => const PrestamosScreen(),
          '/detalle': (context) => const DetalleClienteScreen(),
        },
      ),
    );
  }
}
