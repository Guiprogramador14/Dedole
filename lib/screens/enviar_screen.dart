import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import '../utils/fila_dedole.dart';

class TelaEnviar extends StatefulWidget {
  const TelaEnviar({super.key});
  @override
  State<TelaEnviar> createState() => _TelaEnviarState();
}

class _TelaEnviarState extends State<TelaEnviar> {
  static const cor = Color(0xFF1B2161);
  static const fundo = Color(0xFFF6F7FF);
  final fila = FilaDedole.instance;
  String? anterior;

  @override
  void initState() {
    super.initState();
    anterior = fila.mensagem;
    fila.addListener(atualizar);
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

  Future<void> confirmarLimpeza() async {
    if (fila.reproduzindo || fila.ocupado || fila.itens.isEmpty) return;
    final sim = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Limpar fila?'),
      content: const Text('As palavras pendentes serão removidas. As palavras salvas não serão apagadas.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Limpar')),
      ],
    ));
    if (sim == true) fila.limpar();
  }

  @override
  void dispose() {
    fila.removeListener(atualizar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atual = fila.palavraEmExecucao ?? (fila.itens.isEmpty ? null : fila.itens.first);
    final bloqueioEdicao = fila.reproduzindo || fila.ocupado;
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(children: [
          Row(children: [
            IconButton(tooltip: 'Voltar', onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: cor)),
            const Expanded(child: Text('Enviar', textAlign: TextAlign.center,
              style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 20),
          Semantics(liveRegion: true, child: Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD8DCEF))),
            child: Text(fila.mensagem, style: const TextStyle(color: cor, fontSize: 14)),
          )),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8DCEF))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Palavra atual', style: TextStyle(color: cor)),
              const SizedBox(height: 8),
              Text(atual ?? 'Nenhuma', style: const TextStyle(color: cor, fontSize: 28, fontWeight: FontWeight.bold)),
              if (fila.reproduzindo) Text('Letra ${fila.letraAtual} (${fila.indiceLetra + 1} de ${fila.palavraEmExecucao!.length})',
                style: const TextStyle(color: cor)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, children: [
                OutlinedButton.icon(onPressed: fila.reproduzindo ? fila.parar : null,
                  icon: const Icon(Icons.stop_circle_outlined), label: const Text('Parar')),
                FilledButton.icon(onPressed: fila.itens.isNotEmpty ? fila.tocarPrimeiro : null,
                  icon: const Icon(Icons.play_arrow), label: const Text('Play da fila')),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Text('Última palavra', style: TextStyle(color: cor, fontWeight: FontWeight.w600))),
            Flexible(child: Text(fila.ultimaPalavra ?? 'Nenhuma', overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: cor))),
            IconButton(tooltip: 'Retomar última palavra', onPressed: fila.ultimaPalavra == null ? null : fila.retomarUltima,
              icon: const Icon(Icons.replay, color: cor)),
          ]),
          const Divider(color: Color(0xFFD8DCEF)),
          Row(children: [
            const Expanded(child: Text('Fila de palavras', style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.bold))),
            Text('${fila.itens.length}', style: const TextStyle(color: cor)),
            TextButton.icon(onPressed: !bloqueioEdicao && fila.itens.isNotEmpty ? confirmarLimpeza : null,
              icon: const Icon(Icons.delete_sweep_outlined), label: const Text('Limpar')),
          ]),
          Expanded(child: fila.itens.isEmpty
            ? const Center(child: Text('Fila vazia. Adicione palavras em Suas Palavras.',
                textAlign: TextAlign.center, style: TextStyle(color: cor)))
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: fila.itens.length,
                onReorder: bloqueioEdicao ? (_, __) {} : fila.reordenar,
                itemBuilder: (context, i) {
                  final palavra = fila.itens[i];
                  return Container(key: ValueKey('$i-$palavra'),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFD8DCEF)))),
                    child: ListTile(title: Text(palavra, style: const TextStyle(color: cor, fontSize: 19)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(tooltip: 'Play $palavra, prioridade máxima',
                          onPressed: () => fila.play(palavra, retirarDaFila: true),
                          icon: const Icon(Icons.play_circle_outline, color: cor)),
                        IconButton(tooltip: 'Remover $palavra', onPressed: bloqueioEdicao ? null : () => fila.remover(i),
                          icon: const Icon(Icons.delete_outline, color: cor)),
                        ReorderableDragStartListener(index: i, enabled: !bloqueioEdicao,
                          child: const Padding(padding: EdgeInsets.all(8),
                            child: Icon(Icons.drag_handle, color: cor))),
                      ])),
                  );
                },
              )),
        ]),
      )),
    );
  }
}
