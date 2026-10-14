import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../utils/fila_dedole.dart';

class TelaCores extends StatefulWidget {
  const TelaCores({super.key});

  @override
  State<TelaCores> createState() => _TelaCoresState();
}

class _TelaCoresState extends State<TelaCores> {
  static const Color corTexto = Color(0xFF1B2161);
  static const Color fundo = Color(0xFFF6F7FF);

  static const List<({String nome, Color cor})> cores = [
    (nome: 'VERMELHO', cor: Colors.red),
    (nome: 'AZUL', cor: Colors.blue),
    (nome: 'VERDE', cor: Colors.green),
    (nome: 'AMARELO', cor: Colors.yellow),
    (nome: 'LARANJA', cor: Colors.orange),
    (nome: 'ROXO', cor: Colors.purple),
    (nome: 'ROSA', cor: Colors.pink),
    (nome: 'MARROM', cor: Colors.brown),
    (nome: 'PRETO', cor: Colors.black),
    (nome: 'BRANCO', cor: Colors.white),
    (nome: 'CINZA', cor: Colors.grey),
  ];

  final FilaDedole fila = FilaDedole.instance;
  String? mensagemAnterior;

  @override
  void initState() {
    super.initState();
    mensagemAnterior = fila.mensagem;
    fila.addListener(atualizar);
    fila.preparar();
  }

  void atualizar() {
    if (!mounted) return;
    setState(() {});
    if (mensagemAnterior != fila.mensagem) {
      mensagemAnterior = fila.mensagem;
      SemanticsService.sendAnnouncement(
        View.of(context),
        fila.mensagem,
        TextDirection.ltr,
      );
    }
  }

  void aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    SemanticsService.sendAnnouncement(View.of(context), texto, TextDirection.ltr);
  }

  void adicionarFila(String nome) {
    if (fila.adicionar(nome)) {
      aviso('$nome adicionado ao final da fila.');
    } else {
      aviso('Não foi possível adicionar $nome à fila.');
    }
  }

  Future<void> selecionarCor(String nome) async {
    // O Play sempre pode substituir outra reprodução, mesmo durante uma
    // operação BLE. Apenas a cor atualmente ativa oferece o botão Parar.
    if (fila.reproduzindo && fila.palavraEmExecucao == nome) {
      await fila.parar();
    } else {
      await fila.play(nome);
    }
  }

  @override
  void dispose() {
    fila.removeListener(atualizar);
    super.dispose();
  }

  Widget criarCor(({String nome, Color cor}) item) {
    final ativa = fila.reproduzindo && fila.palavraEmExecucao == item.nome;
    final acao = ativa ? 'Parar cor ${item.nome}' : 'Reproduzir cor ${item.nome}';

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          leading: ExcludeSemantics(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.cor,
                shape: BoxShape.circle,
                border: Border.all(color: corTexto.withValues(alpha: 0.4)),
              ),
            ),
          ),
          title: Text(
            item.nome,
            style: const TextStyle(
              color: corTexto,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: ativa
              ? Text(
                  'Letra ${fila.letraAtual} (${fila.indiceLetra + 1} de ${item.nome.length})',
                  style: const TextStyle(color: corTexto, fontSize: 13),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Adicionar cor ${item.nome} ao final da fila',
                onPressed: () => adicionarFila(item.nome),
                icon: const Icon(Icons.playlist_add, color: corTexto),
              ),
              IconButton(
                tooltip: acao,
                onPressed: () => selecionarCor(item.nome),
                iconSize: 40,
                color: corTexto,
                icon: Icon(ativa
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFD8DCEF)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: corTexto),
                  ),
                  const Expanded(
                    child: Text(
                      'Cores',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: corTexto,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecione uma cor para representar em Braille ou adicionar à fila',
                  style: TextStyle(color: corTexto, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD8DCEF)),
                  ),
                  child: Text(
                    fila.mensagem,
                    style: const TextStyle(color: corTexto, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: cores.length,
                  itemBuilder: (context, i) => criarCor(cores[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
