import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

import 'services/keyword_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-load and compile keywords on startup for seamless hyperlinking
  await KeywordService().initialize();
  
  runApp(const DnDWikiApp());
}

class DnDWikiApp extends StatelessWidget {
  const DnDWikiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D&D 5.5e Wiki',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF818CF8),
        scaffoldBackgroundColor: const Color(0xFF020617), // Deep slate 950
        cardColor: const Color(0xFF1E293B), // Slate 800
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.blueGrey.shade200,
          displayColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF818CF8), // Indigo 400
          secondary: Color(0xFFC084FC), // Purple 400
          surface: Color(0xFF0F172A), // Slate 900
          background: Color(0xFF020617), // Slate 950
          error: Colors.redAccent,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
