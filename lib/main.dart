import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'utils/currency_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CurrencyHelper.initialize();
  runApp(const MonsterMeterApp());
}

/// Main application widget
class MonsterMeterApp extends StatelessWidget {
  const MonsterMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monster Meter',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FF00),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
        cardTheme: CardThemeData(
          color: const Color(0xFF2a2a2a),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

