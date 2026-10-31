class Jogador {
  final String id;
  final String nome;
  final int numeroCamisola;
  final String posicao;
  final int golos;
  final int? equipaId;

  Jogador({
    required this.id,
    required this.nome,
    required this.numeroCamisola,
    required this.posicao,
    this.golos = 0,
    this.equipaId,
  });

  // Funções auxiliares de conversão (típicas de quem consome APIs)
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

  factory Jogador.daApi(Map<String, dynamic> json) {
    return Jogador(
      id: _lerString(json, ['iD_Jogador', 'ID_Jogador', 'id_Jogador', 'id']),
      nome: _lerString(json, ['nome', 'Nome', 'name']),
      posicao: _lerString(json, ['posicao', 'Posicao', 'position']),
      numeroCamisola: _lerInt(json, ['numero_Camisola', 'Numero_Camisola', 'numeroCamisola', 'number']),
      equipaId: _lerInt(json, ['iD_Equipa', 'ID_Equipa', 'id_Equipa', 'teamId']),
    );
  }
}