import 'package:flutter/material.dart';
import '../models/equipa.dart';

class TableTabScreen extends StatelessWidget {
  final List<Equipa> equipas;
  final String? equipaFavorita;

  const TableTabScreen({
    super.key,
    required this.equipas,
    this.equipaFavorita,
  });

  @override
  Widget build(BuildContext context) {
    if (equipas.isEmpty) {
      return const Center(child: Text('Ainda não existem equipas registadas.'));
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: const Row(
              children: [
                SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 4, child: Text('CLUBE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 1, child: Text('P', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 1, child: Text('J', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 1, child: Text('V', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text('GM-GS', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: equipas.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final equipa = equipas[index];
                final isFavorita = equipa.nome == equipaFavorita;

                return Container(
                  color: isFavorita ? Colors.green.withOpacity(0.1) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index < 3 ? const Color(0xFF2E8B3D) : (index >= equipas.length - 2 ? Colors.red : Colors.black87),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            if (isFavorita) const Icon(Icons.star, color: Colors.amber, size: 16),
                            if (isFavorita) const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                equipa.nome,
                                style: TextStyle(
                                  fontWeight: isFavorita ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('${equipa.pontos}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('${equipa.jogos}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('${equipa.vitorias}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('${equipa.golosMarcados}-${equipa.golosSofridos}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                      ),
                    ],
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