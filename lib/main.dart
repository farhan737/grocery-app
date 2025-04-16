import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';
import 'models/product.dart';
import 'services/sheet_service.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite_common_ffi for desktop platforms
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for desktop platforms
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
        ChangeNotifierProvider(
          create: (context) => CartProvider(),
        ),
        Provider<Future<List<Product>>>(
          create: (context) => SheetService().fetchProducts(),
          lazy: false, // Load products immediately
        ),
      ],
      child: MaterialApp(
        title: 'Sarukulu',
        themeMode: ThemeMode.dark, // Force dark theme
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: Colors.deepPurple,
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurple,
            secondary: Colors.purpleAccent,
            tertiary: Color(0xFFB388FF), // Light violet
            surface: Color(0xFF1E1E1E), // Dark surface
            background: Color(0xFF121212), // Dark background
            error: Colors.redAccent,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.deepPurple,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF2D2D2D),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.purpleAccent,
            foregroundColor: Colors.white,
          ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.purpleAccent;
              }
              return Colors.grey;
            }),
            trackColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.purpleAccent.withOpacity(0.5);
              }
              return Colors.grey.withOpacity(0.5);
            }),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.purpleAccent;
              }
              return Colors.grey;
            }),
          ),
          radioTheme: RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.purpleAccent;
              }
              return Colors.grey;
            }),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFF3D3D3D),
            thickness: 1,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
