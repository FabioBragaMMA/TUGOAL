import 'package:flutter/material.dart';
import '../models/equipa.dart';

class AdminTeamsScreen extends StatefulWidget {
  final List<Equipa> equipas;
  final bool epocaIniciada;
  final Future<void> Function() onUpdated;
  final Future<void> Function(String nome)? onAddTeam;
  final Future<void> Function(Equipa equipa, String novoNome)? onEditTeam;
  final Future<void> Function(Equipa equipa)? onRemoveTeam;

  const AdminTeamsScreen({
    super.key,
    required this.equipas,
    required this.epocaIniciada,
    required this.onUpdated,
    this.onAddTeam,
    this.onEditTeam,
    this.onRemoveTeam,
  });

  @override
  State<AdminTeamsScreen> createState() => _AdminTeamsScreenState();
}

class _AdminTeamsScreenState extends State<AdminTeamsScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;
  late List<Equipa> _equipasVisiveis;

  @override
  void initState() {
    super.initState();
    _sincronizarEquipasVisiveis();
  }

  @override
  void didUpdateWidget(covariant AdminTeamsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizarEquipasVisiveis();
  }

  void _sincronizarEquipasVisiveis() {
    _equipasVisiveis = List<Equipa>.from(widget.equipas);
  }

  void _atualizarListaDepoisDaApi() {
    if (!mounted) return;
    setState(_sincronizarEquipasVisiveis);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _adicionarEquipa() async {
    final nome = _nameController.text.trim();
    if (nome.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      if (widget.onAddTeam != null) {
        await widget.onAddTeam!(nome);
      } else {
        widget.equipas.add(Equipa(id: '', nome: nome, sigla: nome));
        await widget.onUpdated();
      }
      _atualizarListaDepoisDaApi();
      _nameController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipa adicionada com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar equipa: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removerEquipa(Equipa equipa, int index) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      if (widget.onRemoveTeam != null) {
        await widget.onRemoveTeam!(equipa);
      } else {
        widget.equipas.removeAt(index);
        await widget.onUpdated();
      }
      _atualizarListaDepoisDaApi();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipa removida com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover equipa: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _editarEquipa(Equipa e) {
    _nameController.text = e.nome;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nome da Equipa'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome da equipa',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final novoNome = _nameController.text.trim();
              if (novoNome.isEmpty) return;

              try {
                if (widget.onEditTeam != null) {
                  await widget.onEditTeam!(e, novoNome);
                } else {
                  e.nome = novoNome;
                  await widget.onUpdated();
                }
                _atualizarListaDepoisDaApi();
                _nameController.clear();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Equipa editada com sucesso!')),
                );
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao editar equipa: $error')),
                );
              }
            },
            child: const Text('Gravar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Gerir Equipas')),
      body: Column(
        children: [
          if (widget.epocaIniciada)
            Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.2),
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A época já foi iniciada. Não é possível adicionar, editar ou eliminar clubes.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _equipasVisiveis.length,
              itemBuilder: (context, index) {
                final team = _equipasVisiveis[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.shield, color: Color(0xFF2E8B3D)),
                    title: Text(
                      team.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: team.id.isEmpty ? null : Text('ID: ${team.id}'),
                    trailing: widget.epocaIniciada
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editarEquipa(team),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _removerEquipa(team, index),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
          if (!widget.epocaIniciada)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Nome da nova equipa',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _adicionarEquipa,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B3D),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}