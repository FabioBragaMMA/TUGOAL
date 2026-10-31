import 'equipa.dart';

class Jogo {
  final String id;
  final Equipa equipaCasa;
  final Equipa equipaFora;
  int? golosCasa;
  int? golosFora;
  final String dataHora;
  final String estadio;
  final int jornada;
  bool realizado;

  Jogo({
    required this.id,
    required this.equipaCasa,
    required this.equipaFora,
    this.golosCasa,
    this.golosFora,
    required this.dataHora,
    required this.estadio,
    this.jornada = 1,
    this.realizado = false,
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

  static int? _lerIntNulo(Map<String, dynamic> json, List<String> chaves) {
    for (final chave in chaves) {
      final valor = json[chave];
      if (valor == null) continue;
      if (valor is int) return valor;
      if (valor is num) return valor.toInt();
      if (valor is String) return int.tryParse(valor);
    }
    return null;
  }

  factory Jogo.daApi(Map<String, dynamic> json, List<Equipa> equipas) {
    final idCasa = _lerString(json, ['iD_Equipa_Casa', 'ID_Equipa_Casa', 'idEquipaCasa']);
    final idFora = _lerString(json, ['iD_Equipa_Fora', 'ID_Equipa_Fora', 'idEquipaFora']);

    Equipa encontrarEquipa(String id) => equipas.firstWhere(
          (equipa) => equipa.id == id,
          orElse: () => Equipa(
            id: id,
            nome: 'EQUIPA $id',
            sigla: 'EQ',
          ),
        );

    final estadoJogo = _lerString(json, ['estado_Jogo', 'Estado_Jogo', 'estadoJogo']);

    return Jogo(
      id: _lerString(json, ['iD_Jogo', 'ID_Jogo', 'id_Jogo', 'id']),
      equipaCasa: encontrarEquipa(idCasa),
      equipaFora: encontrarEquipa(idFora),
      golosCasa: _lerIntNulo(json, ['golos_Casa', 'Golos_Casa', 'golosCasa']),
      golosFora: _lerIntNulo(json, ['golos_Fora', 'Golos_Fora', 'golosFora']),
      dataHora: _lerString(json, ['data_Hora', 'Data_Hora', 'dataHora']),
      estadio: 'A definir',
      jornada: _lerInt(json, ['jornada', 'Jornada']),
      realizado: estadoJogo.toLowerCase() == 'terminado',
    );
  }
}