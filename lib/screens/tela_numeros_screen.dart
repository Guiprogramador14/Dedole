import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../utils/fila_dedole.dart';

class TelaNumeros extends StatefulWidget {
  const TelaNumeros({super.key});

  @override
  State<TelaNumeros> createState() => _TelaNumerosState();
}

class _TelaNumerosState extends State<TelaNumeros> {
  static const cor = Color(0xFF1B2161);
  static const fundo = Color(0xFFF6F7FF);
  static const digitos = '0123456789';
  final fila = FilaDedole.instance;
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
        View.of(context), fila.mensagem, TextDirection.ltr,
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
      ));
    SemanticsService.sendAnnouncement(View.of(context), texto, TextDirection.ltr);
  }

  void adicionarFila(String numero) {
    if (fila.adicionar(numero)) {
      aviso('Número $numero adicionado ao final da fila.');
    } else {
      aviso('Não foi possível adicionar o número $numero.');
    }
  }

  Future<void> selecionar(String numero) async {
    if (fila.palavraEmExecucao == numero) {
      await fila.parar();
    } else {
      await fila.play(numero);
    }
  }

  @override
  void dispose() {
    fila.removeListener(atualizar);
    super.dispose();
  }

  Widget criarNumero(String numero) {
    final ativo = fila.palavraEmExecucao == numero;
    final acao = ativo ? 'Parar número $numero' : 'Reproduzir número $numero';
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        title: Text('NÚMERO $numero', style: const TextStyle(
          color: cor, fontSize: 21, fontWeight: FontWeight.w600,
        )),
        subtitle: ativo
            ? Text(
                fila.aguardandoSinalNumero
                    ? 'Sinal de número: pontos 3, 4, 5 e 6'
                    : 'Algarismo $numero: aguardando resposta',
                style: const TextStyle(color: cor, fontSize: 12),
              )
            : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'Adicionar número $numero ao final da fila',
            onPressed: () => adicionarFila(numero),
            icon: const Icon(Icons.playlist_add, color: cor),
          ),
          IconButton(
            tooltip: acao,
            onPressed: () => selecionar(numero),
            iconSize: 40,
            color: cor,
            icon: Icon(ativo
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline),
          ),
        ]),
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
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: cor),
              ),
              const Expanded(child: Text('Números',
                textAlign: TextAlign.center,
                style: TextStyle(color: cor, fontSize: 18,
                    fontWeight: FontWeight.bold),
              )),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerLeft,
              child: Text('Selecione um número para representar em Braille ou adicionar à fila',
                style: TextStyle(color: cor, fontSize: 14)),
            ),
            const SizedBox(height: 12),
            Semantics(liveRegion: true, child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFCFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8DCEF)),
              ),
              child: Text(fila.mensagem,
                style: const TextStyle(color: cor, fontSize: 14)),
            )),
            const SizedBox(height: 12),
            Expanded(child: ListView.builder(
              itemCount: digitos.length,
              itemBuilder: (context, i) => criarNumero(digitos[i]),
            )),
          ]),
        ),
      ),
    );
  }
}
