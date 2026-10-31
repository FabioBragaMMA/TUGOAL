import 'dart:math';
import 'package:flutter/material.dart';
import '../models/jogo.dart';

class AdminMatchesScreen extends StatefulWidget {
  final List<Jogo> jogos;
  final VoidCallback onSaved;
  final Future<void> Function(Jogo jogo)? onMatchSaved;
  final Future<void> Function(int jornada)? onRoundSimulated;

  const AdminMatchesScreen({
    super.key,
    required this.jogos,
    required this.onSaved,
    this.onMatchSaved,
    this.onRoundSimulated,
  });

  @override
  State<AdminMatchesScreen> createState() => _AdminMatchesScreenState();
}

class _AdminMatchesScreenState extends State<AdminMatchesScreen> {
  int _jornadaSelecionada = 1;
  final Random _random = Random();
  bool _isSaving = false;

  int get _maxJornada {
    if (widget.jogos.isEmpty) return 1;
    return widget.jogos.map((j) => j.jornada).reduce(max);
  }

  bool _jornadasAnterioresConcluidas() {
    if (_jornadaSelecionada == 1) return true;
    return !widget.jogos.any(
      (j) => j.jornada < _jornadaSelecionada && !j.realizado,
    );
  }

  Future<void> _guardarJogo(Jogo jogo, int golosCasa, int golosFora) async {
    if (_isSaving) return;

    final oldGolosCasa = jogo.golosCasa;
    final oldGolosFora = jogo.golosFora;
    final oldRealizado = jogo.realizado;

    setState(() {
      _isSaving = true;
      jogo.golosCasa = golosCasa;
      jogo.golosFora = golosFora;
      jogo.realizado = true;
    });

    try {
      if (widget.onMatchSaved != null) {
        await widget.onMatchSaved!(jogo);
      }
      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado gravado na base de dados!')),
      );
    } catch (e) {
      setState(() {
        jogo.golosCasa = oldGolosCasa;
        jogo.golosFora = oldGolosFora;
        jogo.realizado = oldRealizado;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gravar resultado: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _simularJornadaAtual() async {
    if (!_jornadasAnterioresConcluidas() || _isSaving) return;

    final jogosDaJornada = widget.jogos
        .where((j) => j.jornada == _jornadaSelecionada && !j.realizado)
        .toList();

    if (jogosDaJornada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não existem jogos por simular nesta jornada.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.onRoundSimulated != null) {
        await widget.onRoundSimulated!(_jornadaSelecionada);
      } else {
        for (final jogo in jogosDaJornada) {
          jogo.golosCasa = _random.nextInt(5);
          jogo.golosFora = _random.nextInt(5);
          jogo.realizado = true;

          if (widget.onMatchSaved != null) {
            await widget.onMatchSaved!(jogo);
          }
        }
      }

      widget.onSaved();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jornada $_jornadaSelecionada simulada e gravada!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao simular jornada: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_jornadaSelecionada > _maxJornada) {
      _jornadaSelecionada = _maxJornada;
    }

    final jornadasDisponiveis = List<int>.generate(_maxJornada, (index) => index + 1);
    if (!jornadasDisponiveis.contains(_jornadaSelecionada)) {
      _jornadaSelecionada = jornadasDisponiveis.first;
    }

    final jogosDaJornada = widget.jogos
        .where((j) => j.jornada == _jornadaSelecionada)
        .toList();
    final bool podeEditarOuSimular = _jornadasAnterioresConcluidas();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Registar Resultados')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E8B3D), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _jornadaSelecionada,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E8B3D)),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    items: jornadasDisponiveis
                        .map(
                          (jornada) => DropdownMenuItem<int>(
                            value: jornada,
                            child: Text('JORNADA $jornada DE $_maxJornada'),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _jornadaSelecionada = value);
                          },
                  ),
                ),
              ),
            ),
          ),
          if (!podeEditarOuSimular)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Bloqueado! Deve concluir todos os jogos das jornadas anteriores antes de prosseguir.',
                      style: TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: podeEditarOuSimular && !_isSaving
                  ? _simularJornadaAtual
                  : null,
              icon: const Icon(Icons.casino, color: Colors.white),
              label: Text(
                _isSaving ? 'A gravar...' : 'Simular Jornada Automaticamente',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: podeEditarOuSimular
                    ? Colors.purple[700]
                    : Colors.grey[400],
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: jogosDaJornada.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Não existem jogos para esta jornada.\nVolta ao menu e abre novamente "Registar Jogos" para gerar o calendário com as equipas atuais.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jogosDaJornada.length,
                    itemBuilder: (context, index) {
                      final jogo = jogosDaJornada[index];
                      final homeCtrl = TextEditingController(
                        text: jogo.golosCasa?.toString() ?? '',
                      );
                      final awayCtrl = TextEditingController(
                        text: jogo.golosFora?.toString() ?? '',
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  jogo.equipaCasa.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 35,
                                      child: TextField(
                                        controller: homeCtrl,
                                        enabled: !jogo.realizado &&
                                            podeEditarOuSimular &&
                                            !_isSaving,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('-'),
                                    ),
                                    SizedBox(
                                      width: 35,
                                      child: TextField(
                                        controller: awayCtrl,
                                        enabled: !jogo.realizado &&
                                            podeEditarOuSimular &&
                                            !_isSaving,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  jogo.equipaFora.nome,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              jogo.realizado
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    )
                                  : (podeEditarOuSimular
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.save,
                                            color: Color(0xFF2E8B3D),
                                          ),
                                          onPressed: _isSaving
                                              ? null
                                              : () {
                                                  final golosCasa = int.tryParse(
                                                    homeCtrl.text.trim(),
                                                  );
                                                  final golosFora = int.tryParse(
                                                    awayCtrl.text.trim(),
                                                  );

                                                  if (golosCasa == null ||
                                                      golosFora == null) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Coloca os dois resultados em números.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  _guardarJogo(
                                                    jogo,
                                                    golosCasa,
                                                    golosFora,
                                                  );
                                                },
                                        )
                                      : Icon(
                                          Icons.lock_outline,
                                          color: Colors.grey[400],
                                          size: 20,
                                        )),
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