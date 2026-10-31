import 'package:flutter/material.dart';
import '../models/equipa.dart';

class TeamsTabScreen extends StatelessWidget {
  final List<Equipa> equipas;
  final String? equipaFavoritaAtual;
  final ValueChanged<String?> onFavoritoAlterado;

  const TeamsTabScreen({
    super.key,
    required this.equipas,
    this.equipaFavoritaAtual,
    required this.onFavoritoAlterado,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Equipas da Liga',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: equipas.isEmpty
          ? const Center(child: Text('Ainda não existem equipas registadas.'))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: equipas.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Todos os Clubes',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                      _buildTeamItem(equipas[index]),
                    ],
                  );
                }
                return _buildTeamItem(equipas[index]);
              },
            ),
    );
  }

  Widget _buildTeamItem(Equipa equipa) {
    final bool isFavorito = equipa.nome == equipaFavoritaAtual;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isFavorito ? const Color(0xFF2E8B3D).withOpacity(0.1) : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shield,
          color: isFavorito ? const Color(0xFF2E8B3D) : Colors.grey,
        ),
      ),
      title: Text(
        equipa.nome,
        style: TextStyle(
          fontWeight: isFavorito ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: const Text(
        'Liga Portugal',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorito ? Icons.star : Icons.star_border,
          color: isFavorito ? Colors.amber : Colors.grey,
        ),
        onPressed: () {
          onFavoritoAlterado(isFavorito ? null : equipa.nome);
        },
      ),
    );
  }
}