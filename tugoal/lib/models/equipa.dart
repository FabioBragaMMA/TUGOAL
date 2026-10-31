class Equipa {
  final String id;
  String nome;
  String sigla;
  int jogos;
  int vitorias;
  int empates;
  int derrotas;
  int golosMarcados;
  int golosSofridos;
  int pontos;

  Equipa({
    required this.id,
    required this.nome,
    required this.sigla,
    this.jogos = 0,
    this.vitorias = 0,
    this.empates = 0,
    this.derrotas = 0,
    this.golosMarcados = 0,
    this.golosSofridos = 0,
    this.pontos = 0,
  });

  static String _lerString(Map<String, dynamic> json, List<String> chaves) {
    for (final chave in chaves) {
      final valor = json[chave];
      if (valor != null) return valor.toString();
    }
    return '';
  }

  static int _lerInt(Map<String, dynamic> json, List<String> chaves) {
    for (final chave in chaves) {
      final valor = json[chave];
      if (valor is int) return valor;
      if (valor is num) return valor.toInt();
      if (valor is String) return int.tryParse(valor) ?? 0;
    }
    return 0;
  }

  factory Equipa.daApi(Map<String, dynamic> json) {
    final nomeEquipa = _lerString(json, ['nome', 'Nome', 'equipa', 'Equipa']);
    final siglaEquipa = nomeEquipa
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(3)
        .join()
        .toUpperCase();

    return Equipa(
      id: _lerString(json, ['iD_Equipa', 'ID_Equipa', 'id_Equipa', 'id']),
      nome: nomeEquipa.toUpperCase(),
      sigla: siglaEquipa,
      jogos: _lerInt(json, ['jogosDisputados', 'JogosDisputados', 'jogos']),
      vitorias: _lerInt(json, ['vitorias', 'Vitorias', 'wins']),
      empates: _lerInt(json, ['empates', 'Empates', 'draws']),
      derrotas: _lerInt(json, ['derrotas', 'Derrotas', 'losses']),
      pontos: _lerInt(json, ['pontos', 'Pontos', 'points']),
    );
  }
}