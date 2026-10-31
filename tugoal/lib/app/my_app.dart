import 'package:flutter/material.dart';

import 'main_app_flow.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Simulação TuGoal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E8B3D),
        scaffoldBackgroundColor: const Color(0xFF2E8B3D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E8B3D),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainAppFlow(),
    );
  }
}
