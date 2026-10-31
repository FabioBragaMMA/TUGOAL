import 'package:flutter/material.dart';
import 'dart:math';
import '../models/jogo.dart';

class MatchesTabScreen extends StatefulWidget {
  final List<Jogo> jogos;
  final String? equipaFavorita;

  const MatchesTabScreen({
    super.key,
    required this.jogos,
    this.equipaFavorita,
  });

  @override
  State<MatchesTabScreen> createState() => _MatchesTabScreenState();
}

class _MatchesTabScreenState extends State<MatchesTabScreen> {
  int _jornadaAtual = 1;

  int get _maxJornada {
    if (widget.jogos.isEmpty) return 1;
    return widget.jogos.map((j) => j.jornada).reduce(max);
  }

  @override
  void initState() {
    super.initState();
    _jornadaAtual = _descobrirJornadaAtual();
  }

  int _descobrirJornadaAtual() {
    if (widget.jogos.isEmpty) return 1;
    int ultimaJornadaComJogos = 1;
    for (var jogo in widget.jogos) {
      if (jogo.realizado && jogo.jornada > ultimaJornadaComJogos) {
        ultimaJornadaComJogos = jogo.jornada;
      }
    }
    final temJogosPorRealizarNaUltima = widget.jogos.any((j) => j.jornada == ultimaJornadaComJogos && !j.realizado);
    if (!temJogosPorRealizarNaUltima && ultimaJornadaComJogos < _maxJornada) {
      return ultimaJornadaComJogos + 1;
    }
    return ultimaJornadaComJogos;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jogos.isEmpty) {
      return const Center(child: Text('O calendário ainda não foi gerado.'));
    }

    final jornadasDisponiveis = List<int>.generate(_maxJornada, (index) => index + 1);
    if (!jornadasDisponiveis.contains(_jornadaAtual)) {
      _jornadaAtual = jornadasDisponiveis.first;
    }

    final jogosDaJornada = widget.jogos.where((j) => j.jornada == _jornadaAtual).toList();

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E8B3D), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _jornadaAtual,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E8B3D)),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    items: jornadasDisponiveis
                        .map(
                          (jornada) => DropdownMenuItem<int>(
                            value: jornada,
                            child: Text('JORNADA $jornada'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _jornadaAtual = value);
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: jogosDaJornada.length,
              itemBuilder: (context, index) {
                final jogo = jogosDaJornada[index];
                final isFavorito = jogo.equipaCasa.nome == widget.equipaFavorita ||
                    jogo.equipaFora.nome == widget.equipaFavorita;

                return Card(
                  elevation: isFavorito ? 4 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  shape: isFavorito
                      ? RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF2E8B3D), width: 2), borderRadius: BorderRadius.circular(12))
                      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            jogo.equipaCasa.nome,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: jogo.equipaCasa.nome == widget.equipaFavorita ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: jogo.realizado ? const Color(0xFF2E8B3D) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              jogo.realizado ? '${jogo.golosCasa} - ${jogo.golosFora}' : 'vs',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: jogo.realizado ? Colors.white : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            jogo.equipaFora.nome,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: jogo.equipaFora.nome == widget.equipaFavorita ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}