import 'package:flutter/material.dart';
import '../models/equipa.dart';
import '../models/jogo.dart';
import '../models/noticia.dart';
import 'ecra_detalhe_noticia.dart';

class HomeTabScreen extends StatelessWidget {
  final List<Equipa> equipas;
  final List<Jogo> jogos;
  final String? equipaFavorita;

  const HomeTabScreen({
    super.key,
    required this.equipas,
    required this.jogos,
    this.equipaFavorita,
  });

  Jogo? _obterJogoDestaque() {
    if (jogos.isEmpty) return null;

    if (equipaFavorita != null) {
      try {
        return jogos.firstWhere(
          (j) =>
              !j.realizado &&
              (j.equipaCasa.nome == equipaFavorita ||
                  j.equipaFora.nome == equipaFavorita),
        );
      } catch (_) {}
    }

    try {
      return jogos.firstWhere((j) => !j.realizado);
    } catch (_) {}

    return jogos.last;
  }

  List<Noticia> _gerarNoticiasDinamicas() {
    final jogosRealizados = jogos
        .where((j) => j.realizado && j.golosCasa != null && j.golosFora != null)
        .toList();

    final noticias = <Noticia>[];

    if (equipaFavorita != null && equipas.any((e) => e.nome == equipaFavorita)) {
      final equipa = equipas.firstWhere((e) => e.nome == equipaFavorita);
      noticias.add(
        Noticia(
          titulo: 'Novidades do ${equipa.nome}',
          resumo:
              'Acompanha o momento da tua equipa favorita no campeonato TuGoal.',
          corpo:
              'O ${equipa.nome} soma ${equipa.pontos} pontos em ${equipa.jogos} jogos, com ${equipa.vitorias} vitórias, ${equipa.empates} empates e ${equipa.derrotas} derrotas. A equipa marcou ${equipa.golosMarcados} golos e sofreu ${equipa.golosSofridos}. Os adeptos esperam que as próximas jornadas tragam ainda mais emoção.',
          categoria: 'EXCLUSIVO ADEPTO',
        ),
      );
    }

    if (jogosRealizados.isEmpty) {
      noticias.addAll([
        Noticia(
          titulo:
              'Equipas aceleram os preparativos para o arranque oficial da época',
          resumo:
              'Os plantéis ultimam detalhes para entrar fortes na primeira jornada.',
          corpo:
              'A ansiedade toma conta dos balneários. Os treinadores focam-se na preparação física e na organização tática. Esperam-se jogos muito renhidos neste campeonato, onde cada ponto pode fazer diferença na luta pelo título.',
          categoria: 'PRÉ-ÉPOCA',
        ),
        Noticia(
          titulo: 'Tudo pronto para uma nova época cheia de emoção',
          resumo:
              'A organização confirmou que o calendário será atualizado com as equipas registadas.',
          corpo:
              'O TuGoal prepara-se para receber uma nova época. Assim que as equipas estiverem definidas e o calendário for gerado, os adeptos vão poder acompanhar jogos, resultados, tabela classificativa e novidades diretamente na aplicação.',
          categoria: 'ORGANIZAÇÃO',
        ),
      ]);
      return noticias;
    }

    for (final jogo in jogosRealizados) {
      final diferenca = (jogo.golosCasa! - jogo.golosFora!).abs();
      if (diferenca >= 3) {
        final vencedor = jogo.golosCasa! > jogo.golosFora!
            ? jogo.equipaCasa.nome
            : jogo.equipaFora.nome;
        final vencido = jogo.golosCasa! > jogo.golosFora!
            ? jogo.equipaFora.nome
            : jogo.equipaCasa.nome;

        noticias.add(
          Noticia(
            titulo:
                'Exibição avassaladora! $vencedor goleia $vencido por ${jogo.golosCasa}-${jogo.golosFora}',
            resumo:
                'Uma eficácia ofensiva impressionante marcou a Jornada ${jogo.jornada}.',
            corpo:
                'O encontro foi dominado pelo $vencedor, que mostrou grande capacidade ofensiva e controlo emocional. O $vencido vai ter de corrigir erros defensivos antes da próxima jornada para voltar a entrar na luta pelos pontos.',
            categoria: 'CRÓNICA DE JOGO',
          ),
        );
      }
    }

    final equipasComPontos = [...equipas]
      ..sort((a, b) {
        final cmpPontos = b.pontos.compareTo(a.pontos);
        if (cmpPontos != 0) return cmpPontos;
        final saldoB = b.golosMarcados - b.golosSofridos;
        final saldoA = a.golosMarcados - a.golosSofridos;
        final cmpSaldo = saldoB.compareTo(saldoA);
        if (cmpSaldo != 0) return cmpSaldo;
        return b.golosMarcados.compareTo(a.golosMarcados);
      });

    if (equipasComPontos.isNotEmpty && equipasComPontos.first.pontos > 0) {
      final lider = equipasComPontos.first;
      noticias.add(
        Noticia(
          titulo: '${lider.nome} assume o protagonismo na frente da tabela',
          resumo:
              'Com ${lider.pontos} pontos, a equipa mostra consistência no campeonato.',
          corpo:
              'O ${lider.nome} está a viver um bom momento competitivo. Com ${lider.golosMarcados} golos marcados e ${lider.golosSofridos} sofridos, a equipa demonstra equilíbrio entre ataque e defesa, deixando os adeptos confiantes para as próximas jornadas.',
          categoria: 'FASE INCRÍVEL',
        ),
      );
    }

    for (final jogo in jogosRealizados) {
      if (jogo.golosCasa == jogo.golosFora) {
        noticias.add(
          Noticia(
            titulo:
                'Equilíbrio total dita empate entre ${jogo.equipaCasa.nome} e ${jogo.equipaFora.nome}',
            resumo:
                'A Jornada ${jogo.jornada} trouxe um duelo muito disputado até ao fim.',
            corpo:
                'Nenhuma das equipas conseguiu superiorizar-se no marcador. O resultado de ${jogo.golosCasa}-${jogo.golosFora} reflete uma partida equilibrada, com momentos de perigo para ambos os lados e muita luta no meio-campo.',
            categoria: 'DIFÍCIL',
          ),
        );
      }
    }

    if (noticias.length < 2) {
      noticias.add(
        Noticia(
          titulo: 'Balanço das jornadas revela competitividade feroz',
          resumo:
              'A margem de erro está cada vez mais reduzida para quem quer subir na tabela.',
          corpo:
              'Os resultados recentes mostram que nenhuma equipa pode facilitar. Cada jornada traz mudanças importantes na classificação e qualquer detalhe pode ser decisivo na luta pelos primeiros lugares.',
          categoria: 'ANÁLISE',
        ),
      );
    }

    return noticias;
  }

  Widget _buildNoticiaCard(BuildContext context, Noticia noticia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaginaDetalheNoticia(noticia: noticia),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.newspaper, size: 48, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E8B3D).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      noticia.categoria,
                      style: const TextStyle(
                        color: Color(0xFF2E8B3D),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    noticia.titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    noticia.resumo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jogoDestaque = _obterJogoDestaque();
    final noticias = _gerarNoticiasDinamicas();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8B3D),
        elevation: 0,
        title: const Text(
          'TUGOAL NEWS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Não tens novas notificações.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Jogo em Destaque',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          if (jogoDestaque != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.shield, size: 30, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          jogoDestaque.equipaCasa.sigla,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: jogoDestaque.realizado
                              ? const Color(0xFF2E8B3D)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          jogoDestaque.realizado
                              ? '${jogoDestaque.golosCasa} - ${jogoDestaque.golosFora}'
                              : 'J${jogoDestaque.jornada}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: jogoDestaque.realizado
                                ? Colors.white
                                : const Color(0xFF2E8B3D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jogoDestaque.realizado ? 'Terminado' : 'Por jogar',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.shield, size: 30, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          jogoDestaque.equipaFora.sigla,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Ainda não há jogos no calendário.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Últimas Notícias',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...noticias.map((noticia) => _buildNoticiaCard(context, noticia)),
        ],
      ),
    );
  }
}
