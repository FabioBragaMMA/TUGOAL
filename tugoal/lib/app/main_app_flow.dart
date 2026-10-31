import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../screens/ecra_painel_admin.dart';
import '../screens/ecra_login.dart';

class MainAppFlow extends StatefulWidget {
  const MainAppFlow({super.key});

  @override
  State<MainAppFlow> createState() => _MainAppFlowState();
}

class _MainAppFlowState extends State<MainAppFlow> {
  bool _isLoggedIn = false;

  void _entrarNaApp() {
    if (!mounted) return;
    setState(() => _isLoggedIn = true);
  }

  void _voltarAoLogin() {
    ApiService().logout();

    if (!mounted) return;
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return EmbeddedLoginScreen(
        onLoginSuccess: _entrarNaApp,
      );
    }

    return TuGoalDashboardScreen(
      onLogout: _voltarAoLogin,
    );
  }
}
