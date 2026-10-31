import 'package:flutter/material.dart';
import '../models/equipa.dart';
import '../models/jogo.dart';
import 'aba_inicio.dart';
import 'aba_jogos.dart';
import 'aba_classificacao.dart';
import 'aba_equipas.dart';

class TuGoalFanAreaApp extends StatefulWidget {
  final List<Equipa> equipas;
  final List<Jogo> jogos;
  final String? equipaFavoritaInicial;
  final ValueChanged<String?> onEquipaAlterada;
  final VoidCallback? onLogout;

  const TuGoalFanAreaApp({
    super.key,
    required this.equipas,
    required this.jogos,
    this.equipaFavoritaInicial,
    required this.onEquipaAlterada,
    this.onLogout,
  });

  @override
  State<TuGoalFanAreaApp> createState() => _TuGoalFanAreaAppState();
}

class _TuGoalFanAreaAppState extends State<TuGoalFanAreaApp> {
  int _indiceAtual = 0;
  late String? _equipaFavorita;

  @override
  void initState() {
    super.initState();
    _equipaFavorita = widget.equipaFavoritaInicial;
  }

  void _mudarSeparador(int indice) {
    setState(() {
      _indiceAtual = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> ecras = [
      HomeTabScreen(
        equipas: widget.equipas,
        jogos: widget.jogos,
        equipaFavorita: _equipaFavorita,
      ),
      MatchesTabScreen(
        jogos: widget.jogos,
        equipaFavorita: _equipaFavorita,
      ),
      TableTabScreen(
        equipas: widget.equipas,
        equipaFavorita: _equipaFavorita,
      ),
      TeamsTabScreen(
        equipas: widget.equipas,
        equipaFavoritaAtual: _equipaFavorita,
        onFavoritoAlterado: (novaEquipa) {
          setState(() {
            _equipaFavorita = novaEquipa;
          });
          widget.onEquipaAlterada(novaEquipa);
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8B3D),
        foregroundColor: Colors.white,
        title: const Text('TuGoal - Área do Adepto', style: TextStyle(fontSize: 18)),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Voltar ao login',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: ecras[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: _mudarSeparador,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E8B3D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Notícias'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Jogos'),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_numbered), label: 'Tabela'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Clubes'),
        ],
      ),
    );
  }
}