import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import '../database/banco_dedole.dart';
import '../utils/fila_dedole.dart';

class TelaSuasPalavras extends StatefulWidget {
  const TelaSuasPalavras({super.key});
  @override
  State<TelaSuasPalavras> createState() => _TelaSuasPalavrasState();
}

class _TelaSuasPalavrasState extends State<TelaSuasPalavras> {
  static const cor = Color(0xFF1B2161);
  static const fundo = Color(0xFFF6F7FF);
  final fila = FilaDedole.instance;
  List<Map<String, dynamic>> palavras = [];
  bool carregando = true;
  String? anterior;

  @override
  void initState() {
    super.initState();
    anterior = fila.mensagem;
    fila.addListener(atualizar);
    carregarPalavras();
    fila.preparar();
  }

  void atualizar() {
    if (!mounted) return;
    setState(() {});
    if (anterior != fila.mensagem) {
      anterior = fila.mensagem;
      SemanticsService.sendAnnouncement(View.of(context), fila.mensagem, TextDirection.ltr);
    }
  }

  void aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
    SemanticsService.sendAnnouncement(View.of(context), texto, TextDirection.ltr);
  }

  Future<void> carregarPalavras() async {
    try {
      final resultado = await BancoDedole.buscarPalavras();
      if (!mounted) return;
      setState(() { palavras = resultado; carregando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => carregando = false);
      aviso('Erro ao carregar palavras: $e');
    }
  }

  Future<void> editar({Map<String, dynamic>? registro}) async {
    if (fila.reproduzindo || fila.ocupado) return;
    final editando = registro != null;
    final controller = TextEditingController(text: editando ? registro['palavra'].toString() : '');
    String? erro;
    final resultado = await showDialog<String>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, atualizarDialogo) => AlertDialog(
        title: Text(editando ? 'Editar palavra' : 'Adicionar palavra'),
        content: TextField(controller: controller, autofocus: true, maxLength: 40,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
          decoration: InputDecoration(labelText: 'Palavra', hintText: 'CASA',
            errorText: erro, border: const OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final valor = FilaDedole.validar(controller.text);
            if (valor == null) atualizarDialogo(() => erro = 'Use letras A a Z, sem espaços ou acentos.');
            else Navigator.pop(ctx, valor);
          }, child: const Text('Salvar')),
        ],
      )));
    controller.dispose();
    if (resultado == null || !mounted) return;
    if (fila.reproduzindo || fila.ocupado) {
      aviso('Aguarde o fim da reprodução para alterar palavras.');
      return;
    }
    try {
      if (editando) await BancoDedole.editarPalavra(registro['id'] as int, resultado);
      else await BancoDedole.adicionarPalavra(resultado);
      await carregarPalavras();
      aviso(editando ? 'Palavra atualizada.' : 'Palavra salva.');
    } catch (e) { aviso('Erro ao salvar: $e'); }
  }

  Future<void> excluir(Map<String, dynamic> registro) async {
    if (fila.reproduzindo || fila.ocupado) return;
    final nome = registro['palavra'].toString();
    final confirmar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Excluir palavra?'), content: Text('Excluir "$nome" do banco de dados?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
      ],
    ));
    if (confirmar != true || !mounted || fila.reproduzindo || fila.ocupado) return;
    try {
      await BancoDedole.excluirPalavra(registro['id'] as int);
      await carregarPalavras();
      aviso('Palavra $nome excluída.');
    } catch (e) { aviso('Erro ao excluir: $e'); }
  }

  void adicionarFila(String nome) {
    if (fila.adicionar(nome)) aviso('$nome adicionado ao final da fila.');
    else aviso('Não foi possível adicionar $nome.');
  }

  @override
  void dispose() {
    fila.removeListener(atualizar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloqueioEdicao = fila.reproduzindo || fila.ocupado;
    return Scaffold(backgroundColor: fundo,
      body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(children: [
          Row(children: [
            IconButton(tooltip: 'Voltar', onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: cor)),
            const Expanded(child: Text('Suas palavras', textAlign: TextAlign.center,
              style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(tooltip: 'Adicionar palavra ao banco',
              onPressed: bloqueioEdicao ? null : () => editar(),
              icon: const Icon(Icons.add_circle_outline, color: cor, size: 30)),
          ]),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text('Escolha uma palavra para reproduzir ou adicionar à fila',
            style: TextStyle(color: cor, fontSize: 14))),
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: Container(width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD8DCEF))),
            child: Text(fila.mensagem, style: const TextStyle(color: cor, fontSize: 14)))),
          const SizedBox(height: 12),
          Expanded(child: carregando ? const Center(child: CircularProgressIndicator())
            : palavras.isEmpty ? const Center(child: Text('Nenhuma palavra salva. Toque em + para adicionar.',
                textAlign: TextAlign.center, style: TextStyle(color: cor)))
            : ListView.separated(itemCount: palavras.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD8DCEF)),
                itemBuilder: (context, i) {
                  final registro = palavras[i];
                  final nome = registro['palavra'].toString().toUpperCase();
                  final ativa = fila.palavraEmExecucao == nome;
                  return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                    title: Text(nome, style: const TextStyle(color: cor, fontSize: 19, fontWeight: FontWeight.w600)),
                    subtitle: ativa ? Text('Letra ${fila.letraAtual} (${fila.indiceLetra + 1} de ${nome.length})',
                      style: const TextStyle(color: cor, fontSize: 12)) : null,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(tooltip: 'Adicionar $nome ao final da fila',
                        onPressed: () => adicionarFila(nome),
                        icon: const Icon(Icons.playlist_add, color: cor)),
                      PopupMenuButton<String>(tooltip: 'Opções de $nome', enabled: !bloqueioEdicao,
                        icon: const Icon(Icons.more_vert, color: cor),
                        onSelected: (acao) {
                          if (acao == 'editar') editar(registro: registro);
                          if (acao == 'excluir') excluir(registro);
                        }, itemBuilder: (_) => const [
                          PopupMenuItem(value: 'editar', child: Text('Editar')),
                          PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                        ]),
                      IconButton(tooltip: 'Play $nome, prioridade máxima',
                        onPressed: () => fila.play(nome),
                        iconSize: 36, icon: const Icon(Icons.play_circle_outline, color: cor)),
                    ]),
                  );
                })),
        ]),
      )),
    );
  }
}
