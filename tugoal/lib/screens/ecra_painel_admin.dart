import 'package:flutter/material.dart';

import '../models/equipa.dart';
import '../models/jogo.dart';
import '../services/api_service.dart';
import 'ecra_registar_jogos.dart';
import 'ecra_gerir_jogadores.dart';
import 'ecra_reiniciar_epoca.dart';
import 'ecra_gerir_equipas.dart';
import 'ecra_area_adepto.dart';

class TuGoalDashboardScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const TuGoalDashboardScreen({
    super.key,
    this.onLogout,
  });

  @override
  State<TuGoalDashboardScreen> createState() => _TuGoalDashboardScreenState();
}

class _TuGoalDashboardScreenState extends State<TuGoalDashboardScreen> {
  final ApiService _apiService = ApiService();

  final List<Equipa> _equipas = [];
  final List<Jogo> _jogos = [];

  String? _equipaFavoritaGlobal;
  bool _isLoading = true;
  bool _isWorking = false;
  String? _erro;

  bool get _epocaIniciada => _jogos.any((j) => j.realizado);
  bool get _temEquipasSuficientesParaCalendario => _equipas.length >= 2;
  bool get _numeroParEquipasParaCalendario =>
      _equipas.length >= 2 && _equipas.length.isEven;

  bool get _calendarioEstaDesatualizado {
    if (!_numeroParEquipasParaCalendario) return false;
    if (_jogos.isEmpty) return true;

    final totalJogosEsperado = (_equipas.length * (_equipas.length - 1)) ~/ 2;
    if (_jogos.length != totalJogosEsperado) return true;

    final nomesEquipasAtivas = _equipas.map((e) => e.nome.toUpperCase()).toSet();
    final nomesUsadosNosJogos = <String>{};

    for (final jogo in _jogos) {
      nomesUsadosNosJogos.add(jogo.equipaCasa.nome.toUpperCase());
      nomesUsadosNosJogos.add(jogo.equipaFora.nome.toUpperCase());
    }

    return !nomesEquipasAtivas.every(nomesUsadosNosJogos.contains) ||
        !nomesUsadosNosJogos.every(nomesEquipasAtivas.contains);
  }

  @override
  void initState() {
    super.initState();
    _carregarDadosDaApi();
  }

  Future<void> _carregarDadosDaApi() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      await _apiService.loadAll();
      _sincronizarDadosLocais();

      if (!mounted) return;
      setState(() {
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

  void _sincronizarDadosLocais() {
    _equipas
      ..clear()
      ..addAll(_apiService.equipas);
    _jogos
      ..clear()
      ..addAll(_apiService.jogos);
    _recalcularTabelaClassificativaSemSetState();
  }

  void _recalcularTabelaClassificativaSemSetState() {
    for (var e in _equipas) {
      e.jogos = 0;
      e.vitorias = 0;
      e.empates = 0;
      e.derrotas = 0;
      e.golosMarcados = 0;
      e.golosSofridos = 0;
      e.pontos = 0;
    }

    for (var jogo in _jogos) {
      if (jogo.realizado && jogo.golosCasa != null && jogo.golosFora != null) {
        final equipaCasa = _equipas.where((e) => e.nome == jogo.equipaCasa.nome).toList();
        final equipaFora = _equipas.where((e) => e.nome == jogo.equipaFora.nome).toList();
        if (equipaCasa.isEmpty || equipaFora.isEmpty) continue;

        equipaCasa.first.jogos += 1;
        equipaFora.first.jogos += 1;
        equipaCasa.first.golosMarcados += jogo.golosCasa!;
        equipaCasa.first.golosSofridos += jogo.golosFora!;
        equipaFora.first.golosMarcados += jogo.golosFora!;
        equipaFora.first.golosSofridos += jogo.golosCasa!;

        if (jogo.golosCasa! > jogo.golosFora!) {
          equipaCasa.first.vitorias += 1;
          equipaFora.first.derrotas += 1;
          equipaCasa.first.pontos += 3;
        } else if (jogo.golosCasa! < jogo.golosFora!) {
          equipaFora.first.vitorias += 1;
          equipaCasa.first.derrotas += 1;
          equipaFora.first.pontos += 3;
        } else {
          equipaCasa.first.empates += 1;
          equipaFora.first.empates += 1;
          equipaCasa.first.pontos += 1;
          equipaFora.first.pontos += 1;
        }
      }
    }

    _equipas.sort((a, b) {
      final cmp = b.pontos.compareTo(a.pontos);
      if (cmp != 0) return cmp;
      final diffB = b.golosMarcados - b.golosSofridos;
      final diffA = a.golosMarcados - a.golosSofridos;
      final cmpDiff = diffB.compareTo(diffA);
      if (cmpDiff != 0) return cmpDiff;
      return b.golosMarcados.compareTo(a.golosMarcados);
    });
  }

  void _recalcularTabelaClassificativa() {
    if (!mounted) return;
    setState(_recalcularTabelaClassificativaSemSetState);
  }

  Future<Map<Equipa, int>> _equipasComPlantelInsuficiente() async {
    final equipasInsuficientes = <Equipa, int>{};

    for (final equipa in _equipas) {
      if (equipa.id.isEmpty) {
        equipasInsuficientes[equipa] = 0;
        continue;
      }

      final jogadores = await _apiService.loadPlayersByTeam(equipa.id);
      if (jogadores.length < 11) {
        equipasInsuficientes[equipa] = jogadores.length;
      }
    }

    return equipasInsuficientes;
  }

  Future<bool> _validarPlantelMinimoParaComecarEpoca({
    bool mostrarAviso = true,
  }) async {
    if (!_numeroParEquipasParaCalendario) {
      if (mostrarAviso && mounted) {
        final totalEquipas = _equipas.length;
        final mensagem = totalEquipas < 2
            ? 'Precisas de pelo menos 2 equipas para registar/simular jornadas.\n\n'
                'Além disso, o número de equipas tem de ser par.'
            : 'Não é possível registar/simular jornadas com $totalEquipas equipas.\n\n'
                'O número de equipas tem de ser par, porque se for ímpar uma equipa fica sempre sem jogar.';

        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Número de equipas inválido'),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    final equipasInsuficientes = await _equipasComPlantelInsuficiente();
    if (equipasInsuficientes.isEmpty) return true;

    if (mostrarAviso && mounted) {
      final detalhes = equipasInsuficientes.entries
          .map((entry) => '• ${entry.key.nome}: ${entry.value}/11 jogadores')
          .join('\n');

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Plantel insuficiente'),
          content: Text(
            'Não é possível começar a época.\n\n'
            'Todas as equipas têm de ter pelo menos 11 jogadores.\n\n'
            '$detalhes',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return false;
  }

  Future<bool> _gerarCalendarioSeNecessario({
    bool validarPlantel = false,
    bool mostrarAvisoPlantel = false,
  }) async {
    if (_epocaIniciada) return true;

    if (validarPlantel) {
      final podeComecar = await _validarPlantelMinimoParaComecarEpoca(
        mostrarAviso: mostrarAvisoPlantel,
      );
      if (!podeComecar) return false;
    }

    if (!_numeroParEquipasParaCalendario) return false;

    if (!_calendarioEstaDesatualizado) return true;

    await _apiService.generateCalendar();
    _sincronizarDadosLocais();
    return true;
  }

  Future<void> _abrirRegistarJogos() async {
    if (_isWorking) return;

    var podeAbrirRegisto = true;

    setState(() => _isWorking = true);
    try {
      await _apiService.loadTeams();
      _sincronizarDadosLocais();

      if (!_epocaIniciada) {
        podeAbrirRegisto = await _gerarCalendarioSeNecessario(
          validarPlantel: true,
          mostrarAvisoPlantel: true,
        );
      }
    } catch (e) {
      podeAbrirRegisto = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao preparar jornadas: $e')),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }

    if (!mounted || !podeAbrirRegisto) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMatchesScreen(
          jogos: _jogos,
          onSaved: _recalcularTabelaClassificativa,
          onMatchSaved: _guardarResultadoApi,
          onRoundSimulated: _simularJornadaApi,
        ),
      ),
    );

    if (mounted) {
      await _carregarDadosDaApi();
    }
  }

  Future<void> _adicionarEquipaApi(String nome) async {
    await _apiService.addTeam(nome, nome);
    _sincronizarDadosLocais();

    if (!_epocaIniciada) {
      await _gerarCalendarioSeNecessario(
        validarPlantel: true,
        mostrarAvisoPlantel: false,
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _editarEquipaApi(Equipa equipa, String novoNome) async {
    if (equipa.id.isEmpty) {
      throw Exception('Esta equipa não tem ID vindo da API.');
    }

    await _apiService.updateTeam(
      id: equipa.id,
      name: novoNome,
      emblem: novoNome,
    );
    _sincronizarDadosLocais();

    if (!_epocaIniciada) {
      await _gerarCalendarioSeNecessario(
        validarPlantel: true,
        mostrarAvisoPlantel: false,
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _removerEquipaApi(Equipa equipa) async {
    if (equipa.id.isEmpty) {
      throw Exception('Esta equipa não tem ID vindo da API.');
    }

    await _apiService.removeTeam(equipa.id);
    _sincronizarDadosLocais();

    if (!_epocaIniciada) {
      await _gerarCalendarioSeNecessario(
        validarPlantel: true,
        mostrarAvisoPlantel: false,
      );
    }

    if (_equipaFavoritaGlobal == equipa.nome) {
      _equipaFavoritaGlobal = null;
    }

    if (mounted) setState(() {});
  }

  Future<void> _guardarResultadoApi(Jogo jogo) async {
    if (jogo.id.isEmpty || jogo.golosCasa == null || jogo.golosFora == null) {
      return;
    }

    if (!_epocaIniciada) {
      final podeComecar = await _validarPlantelMinimoParaComecarEpoca(
        mostrarAviso: true,
      );
      if (!podeComecar) {
        throw Exception('Para começar a época, é necessário ter número par de equipas e pelo menos 11 jogadores em cada equipa.');
      }
    }

    await _apiService.finishMatch(
      id: jogo.id,
      homeGoals: jogo.golosCasa!,
      awayGoals: jogo.golosFora!,
    );
    _sincronizarDadosLocais();
    if (mounted) setState(() {});
  }

  Future<void> _simularJornadaApi(int jornada) async {
    if (!_epocaIniciada) {
      final podeComecar = await _validarPlantelMinimoParaComecarEpoca(
        mostrarAviso: true,
      );
      if (!podeComecar) {
        throw Exception('Para começar a época, é necessário ter número par de equipas e pelo menos 11 jogadores em cada equipa.');
      }
    }

    await _apiService.simulateRound(jornada);
    _sincronizarDadosLocais();
    if (mounted) setState(() {});
  }

  Future<void> _resetEpoca() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);

    try {
      await _apiService.resetSeason();
      _sincronizarDadosLocais();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reiniciar época: $e')),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    Widget destinationPage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
          if (mounted) {
            await _carregarDadosDaApi();
          }
        },
        borderRadius: BorderRadius.circular(25),
        child: _menuButtonContent(title),
      ),
    );
  }

  Widget _buildMenuActionButton(
    BuildContext context,
    String title,
    Future<void> Function() onTapAction,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: _isWorking ? null : () async => await onTapAction(),
        borderRadius: BorderRadius.circular(25),
        child: _menuButtonContent(_isWorking ? 'A preparar...' : title),
      ),
    );
  }

  Widget _menuButtonContent(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }


  Future<void> _voltarAoLogin() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voltar ao login?'),
        content: const Text('A sessão atual será terminada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    _apiService.logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2E8B3D),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_erro != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2E8B3D),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Erro ao carregar dados da API',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _erro!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _carregarDadosDaApi,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _voltarAoLogin,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Voltar ao login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2E8B3D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/logo_2.png',
                        width: 235,
                        height: 54,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BECAUSE FOOTBALL IS YOU',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      if (_apiService.nome != null)
                        Text(
                          'Sessão: ${_apiService.nome}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.82),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Atualizar dados',
                    onPressed: _carregarDadosDaApi,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: 'Voltar ao login',
                    onPressed: _voltarAoLogin,
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'MENU',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              _buildMenuButton(
                context,
                'Área do Adepto (Resultados e Classificação)',
                TuGoalFanAreaApp(
                  equipas: _equipas,
                  jogos: _jogos,
                  equipaFavoritaInicial: _equipaFavoritaGlobal,
                  onEquipaAlterada: (novaEquipa) {
                    setState(() {
                      _equipaFavoritaGlobal = novaEquipa;
                    });
                  },
                  onLogout: _voltarAoLogin,
                ),
              ),
              if (_apiService.isAdmin) ...[
                _buildMenuButton(
                  context,
                  'Gerir Equipas',
                  AdminTeamsScreen(
                    equipas: _equipas,
                    epocaIniciada: _epocaIniciada,
                    onUpdated: _carregarDadosDaApi,
                    onAddTeam: _adicionarEquipaApi,
                    onEditTeam: _editarEquipaApi,
                    onRemoveTeam: _removerEquipaApi,
                  ),
                ),
                _buildMenuButton(
                  context,
                  'Gerir Jogadores',
                  AdminPlayersScreen(
                    equipas: _equipas,
                    epocaIniciada: _epocaIniciada,
                  ),
                ),
                _buildMenuActionButton(
                  context,
                  'Registar Jogos',
                  _abrirRegistarJogos,
                ),
                _buildMenuButton(
                  context,
                  'Reiniciar Época',
                  AdminResetScreen(onResetConfirmed: _resetEpoca),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}