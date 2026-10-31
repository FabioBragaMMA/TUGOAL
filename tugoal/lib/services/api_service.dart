import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/equipa.dart';
import '../models/jogo.dart';
import '../models/jogador.dart';

class ApiService extends ChangeNotifier {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  String? nome;
  String? perfil;

  List<Equipa> _equipas = [];
  List<Jogo> _jogos = [];

  List<Equipa> get equipas => List.unmodifiable(_equipas);
  List<Jogo> get jogos => List.unmodifiable(_jogos);
  
  bool get isLoggedIn => _token != null;
  bool get isAdmin => perfil == 'Administrador';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String _messageFromResponse(http.Response response) {
    if (response.body.isEmpty) return 'Erro ${response.statusCode}';

    try {
      final decoded = _decode(response);
      if (decoded is Map<String, dynamic>) {
        return decoded['mensagem']?.toString() ??
            decoded['message']?.toString() ??
            decoded['erro']?.toString() ??
            decoded.toString();
      }
      return decoded.toString();
    } catch (_) {
      return utf8.decode(response.bodyBytes);
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromResponse(response));
    }
  }

  Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } catch (e) {
      final help = kIsWeb
          ? 'Verifica se a API está aberta em http://localhost:5177 e se o CORS está ativo no Program.cs.'
          : 'Verifica se a API está aberta e se o URL em api_config.dart está correto.';
      throw Exception('Não foi possível ligar à API. $help\nDetalhe: $e');
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _safeRequest(() => http.post(
          _uri('/Auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ));

    _ensureSuccess(response);
    final data = _decode(response) as Map<String, dynamic>;
    _token = (data['token'] ?? data['Token']).toString();
    nome = (data['nome'] ?? data['Nome'] ?? '').toString();
    perfil = (data['perfil'] ?? data['Perfil'] ?? '').toString();

    await loadAll();
    notifyListeners();
  }

  void logout() {
    _token = null;
    nome = null;
    perfil = null;
    _equipas = [];
    _jogos = [];
    notifyListeners();
  }

  Future<void> entrarComoConvidado() async {
    _token = null;
    nome = 'Convidado';
    perfil = 'Convidado';
    await loadAll();
    notifyListeners();
  }

  Future<void> register({
    required String nome,
    required String email,
    required String password,
  }) async {
    final response = await _safeRequest(() => http.post(
          _uri('/Auth/registar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nome': nome,
            'email': email,
            'passwordHash': password,
            'perfil': 'Adepto',
            'ativo': true,
          }),
        ));
    _ensureSuccess(response);
  }

  Future<void> loadAll() async {
    await loadTeams();
    await loadMatches();
  }

  Future<void> loadTeams() async {
    final response = await _safeRequest(
      () => http.get(_uri('/Equipas'), headers: _headers),
    );
    _ensureSuccess(response);
    final data = _decode(response) as List<dynamic>;
    _equipas = data
        .map((item) => Equipa.daApi(item as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> loadClassification() async {
    final response = await _safeRequest(
      () => http.get(_uri('/Estatisticas/classificacao'), headers: _headers),
    );
    _ensureSuccess(response);
    final data = _decode(response) as List<dynamic>;
    _equipas = data
        .map((item) => Equipa.daApi(item as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> loadMatches() async {
    if (_equipas.isEmpty) {
      await loadTeams();
    }

    final response = await _safeRequest(
      () => http.get(_uri('/Jogos'), headers: _headers),
    );
    _ensureSuccess(response);
    final data = _decode(response) as List<dynamic>;
    _jogos = data
        .map((item) => Jogo.daApi(item as Map<String, dynamic>, _equipas))
        .toList();
    notifyListeners();
  }

  Future<void> addTeam(String name, String acronym) async {
    final response = await _safeRequest(() => http.post(
          _uri('/Equipas'),
          headers: _headers,
          body: jsonEncode({
            'nome': name.trim(),
            'ano_Fundacao': null,
            'emblema': acronym.trim().isEmpty ? name.trim() : acronym.trim(),
            'ativo': true,
          }),
        ));
    _ensureSuccess(response);
    await loadTeams();
  }

  Future<void> updateTeam({
    required String id,
    required String name,
    String? emblem,
  }) async {
    final response = await _safeRequest(() => http.put(
          _uri('/Equipas/$id'),
          headers: _headers,
          body: jsonEncode({
            'nome': name.trim(),
            'ano_Fundacao': null,
            'emblema': (emblem == null || emblem.trim().isEmpty)
                ? name.trim()
                : emblem.trim(),
            'ativo': true,
          }),
        ));
    _ensureSuccess(response);
    await loadTeams();
  }

  Future<void> removeTeam(String id) async {
    final response = await _safeRequest(
      () => http.delete(_uri('/Equipas/$id'), headers: _headers),
    );
    _ensureSuccess(response);
    await loadTeams();
  }

  Future<void> generateCalendar() async {
    final response = await _safeRequest(
      () => http.post(_uri('/Jogos/gerar-calendario'), headers: _headers),
    );
    _ensureSuccess(response);
    await loadMatches();
  }

  Future<void> simulateRound(int round) async {
    final response = await _safeRequest(
      () => http.post(_uri('/Jogos/simular-jornada/$round'), headers: _headers),
    );
    _ensureSuccess(response);
    await loadMatches();
  }

  Future<void> finishMatch({
    required String id,
    required int homeGoals,
    required int awayGoals,
  }) async {
    final response = await _safeRequest(() => http.put(
          _uri('/Jogos/$id/terminar'),
          headers: _headers,
          body: jsonEncode({
            'golos_Casa': homeGoals,
            'golos_Fora': awayGoals,
          }),
        ));
    _ensureSuccess(response);
    await loadMatches();
  }

  Future<List<Jogador>> loadPlayersByTeam(String teamId) async {
    final response = await _safeRequest(
      () => http.get(_uri('/Jogadores/equipa/$teamId'), headers: _headers),
    );
    _ensureSuccess(response);
    final data = _decode(response) as List<dynamic>;
    return data
        .map((item) => Jogador.daApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addPlayer({
    required String teamId,
    required String name,
    required int number,
    required String position,
  }) async {
    final response = await _safeRequest(() => http.post(
          _uri('/Jogadores'),
          headers: _headers,
          body: jsonEncode({
            'nome': name.trim(),
            'posicao': position.trim(),
            'numero_Camisola': number,
            'iD_Equipa': int.tryParse(teamId) ?? 0,
            'ativo': true,
          }),
        ));
    _ensureSuccess(response);
  }

  Future<void> removePlayer(String playerId) async {
    final response = await _safeRequest(
      () => http.delete(_uri('/Jogadores/$playerId'), headers: _headers),
    );
    _ensureSuccess(response);
  }

  Future<void> resetSeason() async {
    final response = await _safeRequest(
      () => http.post(_uri('/Jogos/resetar-epoca'), headers: _headers),
    );
    _ensureSuccess(response);
    _jogos = [];
    await loadAll();
    notifyListeners();
  }
}