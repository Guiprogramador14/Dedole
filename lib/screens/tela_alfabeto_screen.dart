import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../utils/fila_dedole.dart';

class TelaAlfabeto extends StatefulWidget {
  const TelaAlfabeto({super.key});

  @override
  State<TelaAlfabeto> createState() => _TelaAlfabetoState();
}

class _TelaAlfabetoState extends State<TelaAlfabeto> {
  static const Color cor = Color(0xFF1B2161);
  static const Color fundo = Color(0xFFF6F7FF);
  static const String letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final FilaDedole fila = FilaDedole.instance;
  String? mensagemAnterior;

  @override
  void initState() {
    super.initState();
    mensagemAnterior = fila.mensagem;
    fila.addListener(atualizar);
    fila.preparar();
  }

  void falar(String mensagem) {
    if (!mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      mensagem,
      TextDirection.ltr,
    );
  }

  void atualizar() {
    if (!mounted) return;
    setState(() {});
    if (mensagemAnterior != fila.mensagem) {
      mensagemAnterior = fila.mensagem;
      falar(fila.mensagem);
    }
  }

  void informar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    falar(mensagem);
  }

  void adicionarFila(String letra) {
    if (fila.adicionar(letra)) {
      informar('Letra $letra adicionada ao final da fila.');
    } else {
      informar('Não foi possível adicionar a letra $letra.');
    }
  }

  Future<void> selecionar(String letra) async {
    // A letra em execução pode ser interrompida, mas um novo Play
    // continua disponível mesmo se outro comando estiver em andamento.
    if (fila.reproduzindo && fila.palavraEmExecucao == letra) {
      await fila.parar();
    } else {
      await fila.play(letra);
    }
  }

  @override
  void dispose() {
    fila.removeListener(atualizar);
    super.dispose();
  }

  Widget criarLetra(String letra) {
    final bool ativa = fila.reproduzindo &&
        fila.palavraEmExecucao == letra;
    final String acao = ativa ? 'Parar' : 'Reproduzir';

    return Column(children: [
      Semantics(
        container: true,
        explicitChildNodes: true,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          title: Text(
            'LETRA $letra',
            style: const TextStyle(
              color: cor,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: ativa
              ? const Text(
                  'Aguardando resposta nos botões físicos',
                  style: TextStyle(color: cor, fontSize: 12),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Adicionar letra $letra ao final da fila',
                onPressed: () => adicionarFila(letra),
                icon: const Icon(Icons.playlist_add, color: cor),
              ),
              IconButton(
                tooltip: '$acao letra $letra',
                onPressed: () => selecionar(letra),
                iconSize: 40,
                color: cor,
                icon: Icon(ativa
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline),
              ),
            ],
          ),
        ),
      ),
      const Divider(height: 1, color: Color(0xFFD8DCEF)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(children: [
            Row(children: [
              IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Voltar',
                icon: const Icon(Icons.arrow_back_ios_new, color: cor),
                onPressed: () => Navigator.maybePop(context),
              ),
              const Expanded(
                child: Text(
                  'Alfabeto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selecione uma letra para representar em Braille',
                style: TextStyle(color: cor, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              label: 'Estado da atividade: ${fila.mensagem}',
              child: ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fila.mensagem,
                    style: const TextStyle(
                      color: cor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: letras.length,
                itemBuilder: (_, i) => criarLetra(letras[i]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
