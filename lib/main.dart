import 'package:flutter/material.dart';
import 'package:moments_remembered/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MomentsRememberedApp());
}

class MomentsRememberedApp extends StatelessWidget {
  const MomentsRememberedApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF815A46);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moments Remembered',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFFFFBF7),
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      ),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark), useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
