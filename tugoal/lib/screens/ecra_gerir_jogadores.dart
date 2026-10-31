import 'package:flutter/material.dart';
import '../models/jogador.dart';
import '../models/equipa.dart';
import '../services/api_service.dart';

class AdminPlayersScreen extends StatefulWidget {
  final List<Equipa> equipas;
  final bool epocaIniciada;

  const AdminPlayersScreen({
    super.key,
    required this.equipas,
    required this.epocaIniciada,
  });

  @override
  State<AdminPlayersScreen> createState() => _AdminPlayersScreenState();
}

class _AdminPlayersScreenState extends State<AdminPlayersScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();

  String? _equipaSelecionadaId;
  String _posicaoSelecionada = 'Avançado';
  List<Jogador> _jogadores = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _erro;

  final List<String> _posicoes = const [
    'Guarda-redes',
    'Defesa',
    'Médio',
    'Avançado',
  ];

  bool get _edicaoBloqueada => widget.epocaIniciada;

  void _mostrarAvisoEpocaIniciada() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A época já começou. Não é possível adicionar ou remover jogadores.',
        ),
      ),
    );
  }

  List<Equipa> get _equipasComId =>
      widget.equipas.where((e) => e.id.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    if (_equipasComId.isNotEmpty) {
      _equipaSelecionadaId = _equipasComId.first.id;
      _carregarJogadores();
    }
  }

  @override
  void didUpdateWidget(covariant AdminPlayersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = _equipasComId.map((e) => e.id).toSet();
    if (_equipaSelecionadaId == null || !ids.contains(_equipaSelecionadaId)) {
      _equipaSelecionadaId = _equipasComId.isEmpty ? null : _equipasComId.first.id;
      _carregarJogadores();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _carregarJogadores() async {
    final equipaId = _equipaSelecionadaId;
    if (equipaId == null) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final jogadores = await _apiService.loadPlayersByTeam(equipaId);
      if (!mounted) return;
      setState(() {
        _jogadores = jogadores;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _adicionarJogador() async {
    if (_edicaoBloqueada) {
      _mostrarAvisoEpocaIniciada();
      return;
    }

    final equipaId = _equipaSelecionadaId;
    final nome = _nomeController.text.trim();
    final numero = int.tryParse(_numeroController.text.trim());

    if (equipaId == null || nome.isEmpty || numero == null || _isSaving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preenche o nome, número e escolhe uma equipa.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _apiService.addPlayer(
        teamId: equipaId,
        name: nome,
        number: numero,
        position: _posicaoSelecionada,
      );
      _nomeController.clear();
      _numeroController.clear();
      await _carregarJogadores();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jogador adicionado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar jogador: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removerJogador(Jogador jogador) async {
    if (_edicaoBloqueada) {
      _mostrarAvisoEpocaIniciada();
      return;
    }

    if (_isSaving) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover jogador'),
        content: Text('Queres remover ${jogador.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isSaving = true);

    try {
      await _apiService.removePlayer(jogador.id);
      await _carregarJogadores();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jogador removido com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover jogador: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int _ordemPosicao(String posicao) {
    final p = posicao.toLowerCase().trim();
    if (p.contains('guarda')) return 0;
    if (p.contains('defesa')) return 1;
    if (p.contains('médio') || p.contains('medio')) return 2;
    if (p.contains('avançado') || p.contains('avancado')) return 3;
    return 4;
  }

  IconData _iconePosicao(String posicao) {
    final p = posicao.toLowerCase().trim();
    if (p.contains('guarda')) return Icons.sports_handball;
    if (p.contains('defesa')) return Icons.shield_outlined;
    if (p.contains('médio') || p.contains('medio')) return Icons.compare_arrows;
    if (p.contains('avançado') || p.contains('avancado')) return Icons.sports_soccer;
    return Icons.person;
  }

  String _normalizarPosicao(String posicao) {
    final p = posicao.trim();
    if (p.isEmpty) return 'Outra posição';
    return p;
  }

  List<Widget> _buildJogadoresAgrupadosPorPosicao() {
    final jogadoresOrdenados = [..._jogadores]
      ..sort((a, b) {
        final posicao = _ordemPosicao(a.posicao).compareTo(_ordemPosicao(b.posicao));
        if (posicao != 0) return posicao;
        return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      });

    final widgets = <Widget>[];
    String? posicaoAtual;

    for (final jogador in jogadoresOrdenados) {
      final posicao = _normalizarPosicao(jogador.posicao);
      if (posicaoAtual != posicao) {
        posicaoAtual = posicao;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
            child: Row(
              children: [
                Icon(
                  _iconePosicao(posicao),
                  color: const Color(0xFF2E8B3D),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  posicao,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8B3D),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      widgets.add(
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E8B3D),
              foregroundColor: Colors.white,
              child: Icon(_iconePosicao(jogador.posicao), size: 20),
            ),
            title: Text(
              jogador.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(jogador.numeroCamisola > 0 ? 'N.º ${jogador.numeroCamisola}' : 'Sem número'),
            trailing: IconButton(
              tooltip: _edicaoBloqueada
                  ? 'Bloqueado porque a época já começou'
                  : 'Remover jogador',
              icon: Icon(
                Icons.delete,
                color: _edicaoBloqueada ? Colors.grey : Colors.red,
              ),
              onPressed: (_isSaving || _edicaoBloqueada)
                  ? null
                  : () => _removerJogador(jogador),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final equipas = _equipasComId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Gerir Jogadores'),
        backgroundColor: const Color(0xFF2E8B3D),
        foregroundColor: Colors.white,
      ),
      body: equipas.isEmpty
          ? const Center(
              child: Text('Cria primeiro equipas para poderes adicionar jogadores.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _equipaSelecionadaId,
                        decoration: const InputDecoration(
                          labelText: 'Equipa',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        items: equipas.map((equipa) {
                          return DropdownMenuItem<String>(
                            value: equipa.id,
                            child: Text(equipa.nome),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setState(() => _equipaSelecionadaId = value);
                          await _carregarJogadores();
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_edicaoBloqueada) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.orange.shade900,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'A época já começou. O plantel está bloqueado e não podes adicionar ou remover jogadores.',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _nomeController,
                              enabled: !_edicaoBloqueada,
                              decoration: const InputDecoration(
                                labelText: 'Nome do jogador',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 95,
                            child: TextField(
                              controller: _numeroController,
                              enabled: !_edicaoBloqueada,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Nº',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _posicaoSelecionada,
                              decoration: const InputDecoration(
                                labelText: 'Posição',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                              items: _posicoes.map((posicao) {
                                return DropdownMenuItem<String>(
                                  value: posicao,
                                  child: Text(posicao),
                                );
                              }).toList(),
                              onChanged: _edicaoBloqueada
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _posicaoSelecionada = value);
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: (_isSaving || _edicaoBloqueada)
                                ? null
                                : _adicionarJogador,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E8B3D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 14,
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: const Text('Adicionar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _erro!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _jogadores.length >= 11
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _jogadores.length >= 11
                            ? const Color(0xFF2E8B3D)
                            : Colors.orange,
                      ),
                    ),
                    child: Text(
                      _jogadores.length >= 11
                          ? 'Plantel válido: ${_jogadores.length}/11 jogadores mínimos.'
                          : 'Plantel insuficiente: ${_jogadores.length}/11 jogadores. Faltam ${11 - _jogadores.length}.',
                      style: TextStyle(
                        color: _jogadores.length >= 11
                            ? const Color(0xFF2E8B3D)
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _carregarJogadores,
                          child: _jogadores.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 120),
                                    Center(
                                      child: Text('Esta equipa ainda não tem jogadores.'),
                                    ),
                                  ],
                                )
                              : ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: _buildJogadoresAgrupadosPorPosicao(),
                                ),
                        ),
                ),
              ],
            ),
    );
  }
}