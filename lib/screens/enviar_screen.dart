
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../utils/fila_dedole.dart';

class TelaEnviar extends StatefulWidget {
  const TelaEnviar({super.key});

  @override
  State<TelaEnviar> createState() => _TelaEnviarState();
}

class _TelaEnviarState extends State<TelaEnviar> {
  final FilaDedole fila = FilaDedole.instance;
  String? anterior;

  // ==========================================
  // CORES DINÂMICAS DO TEMA
  // ==========================================

  Color get corPrincipal =>
      Theme.of(context).colorScheme.primary;

  Color get corTexto =>
      Theme.of(context).colorScheme.onSurface;

  Color get corFundo =>
      Theme.of(context).scaffoldBackgroundColor;

  Color get corSuperficie =>
      Theme.of(context).colorScheme.surface;

  Color get corDivisoria =>
      Theme.of(context).dividerColor;

  // ==========================================
  // INICIALIZAÇÃO
  // ==========================================

  @override
  void initState() {
    super.initState();

    anterior = fila.mensagem;
    fila.addListener(atualizar);
    fila.preparar();
  }

  // ==========================================
  // ATUALIZAÇÃO DA FILA E ACESSIBILIDADE
  // ==========================================

  void atualizar() {
    if (!mounted) return;

    setState(() {});

    if (anterior != fila.mensagem) {
      anterior = fila.mensagem;

      SemanticsService.sendAnnouncement(
        View.of(context),
        fila.mensagem,
        TextDirection.ltr,
      );
    }
  }

  // ==========================================
  // CONFIRMAR LIMPEZA DA FILA
  // ==========================================

  Future<void> confirmarLimpeza() async {
    if (fila.reproduzindo ||
        fila.ocupado ||
        fila.itens.isEmpty) {
      return;
    }

    final sim = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar fila?'),
        content: const Text(
          'As palavras pendentes serão removidas. '
          'As palavras salvas não serão apagadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (sim == true) {
      fila.limpar();
    }
  }

  // ==========================================
  // FINALIZAÇÃO
  // ==========================================

  @override
  void dispose() {
    fila.removeListener(atualizar);
    super.dispose();
  }

  // ==========================================
  // CAIXA DE MENSAGEM DA FILA
  // ==========================================

  Widget _buildMensagem() {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: corSuperficie,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: corDivisoria,
          ),
        ),
        child: Text(
          fila.mensagem,
          softWrap: true,
          style: TextStyle(
            color: corTexto,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CARTÃO DA PALAVRA ATUAL
  // ==========================================

  Widget _buildPalavraAtual(String? atual) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corSuperficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: corDivisoria,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Palavra atual',
            style: TextStyle(
              color: corTexto,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            atual ?? 'Nenhuma',
            softWrap: true,
            style: TextStyle(
              color: corTexto,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (fila.reproduzindo &&
              fila.palavraEmExecucao != null)
            Text(
              'Letra ${fila.letraAtual} '
              '(${fila.indiceLetra + 1} de '
              '${fila.palavraEmExecucao!.length})',
              softWrap: true,
              style: TextStyle(
                color: corTexto,
              ),
            ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              // PARAR REPRODUÇÃO

              OutlinedButton.icon(
                onPressed:
                    fila.reproduzindo ? fila.parar : null,
                icon: const Icon(
                  Icons.stop_circle_outlined,
                ),
                label: const Text('Parar'),
              ),

              // REPRODUZIR PRIMEIRA PALAVRA DA FILA

              FilledButton.icon(
                onPressed: fila.itens.isNotEmpty
                    ? fila.tocarPrimeiro
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play da fila'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÚLTIMA PALAVRA
  // ==========================================

  Widget _buildUltimaPalavra() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Última palavra',
            style: TextStyle(
              color: corTexto,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            fila.ultimaPalavra ?? 'Nenhuma',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: corTexto,
            ),
          ),
        ),

        IconButton(
          tooltip: 'Retomar última palavra',
          onPressed: fila.ultimaPalavra == null
              ? null
              : fila.retomarUltima,
          icon: Icon(
            Icons.replay,
            color: corPrincipal,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CABEÇALHO DA FILA
  // ==========================================

  Widget _buildCabecalhoFila(bool bloqueioEdicao) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Fila de palavras',
            softWrap: true,
            style: TextStyle(
              color: corTexto,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          '${fila.itens.length}',
          style: TextStyle(
            color: corTexto,
          ),
        ),

        const SizedBox(width: 4),

        TextButton.icon(
          onPressed: !bloqueioEdicao &&
                  fila.itens.isNotEmpty
              ? confirmarLimpeza
              : null,
          icon: const Icon(
            Icons.delete_sweep_outlined,
          ),
          label: const Text('Limpar'),
        ),
      ],
    );
  }

  // ==========================================
  // LISTA DE PALAVRAS
  // ==========================================

  Widget _buildListaFila(bool bloqueioEdicao) {
    if (fila.itens.isEmpty) {
      return Center(
        child: Text(
          'Fila vazia. Adicione palavras em Suas Palavras.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: corTexto,
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: fila.itens.length,

      // Mantém o bloqueio de reordenação
      // durante a reprodução.

      onReorder: bloqueioEdicao
          ? (_, __) {}
          : fila.reordenar,

      itemBuilder: (context, i) {
        final palavra = fila.itens[i];

        return Container(
          key: ValueKey('$i-$palavra'),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: corDivisoria,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 5,
            ),

            // PALAVRA DA FILA

            title: Text(
              palavra,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: corTexto,
                fontSize: 19,
              ),
            ),

            // CONTROLES

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PLAY COM PRIORIDADE MÁXIMA

                IconButton(
                  tooltip:
                      'Play $palavra, prioridade máxima',
                  onPressed: () => fila.play(
                    palavra,
                    retirarDaFila: true,
                  ),
                  icon: Icon(
                    Icons.play_circle_outline,
                    color: corPrincipal,
                  ),
                ),

                // REMOVER PALAVRA

                IconButton(
                  tooltip: 'Remover $palavra',
                  onPressed: bloqueioEdicao
                      ? null
                      : () => fila.remover(i),
                  icon: Icon(
                    Icons.delete_outline,
                    color: corPrincipal,
                  ),
                ),

                // REORDENAR PALAVRA

                ReorderableDragStartListener(
                  index: i,
                  enabled: !bloqueioEdicao,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle,
                      color: bloqueioEdicao
                          ? Theme.of(context)
                              .disabledColor
                          : corPrincipal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // INTERFACE PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final atual = fila.palavraEmExecucao ??
        (fila.itens.isEmpty
            ? null
            : fila.itens.first);

    final bloqueioEdicao =
        fila.reproduzindo || fila.ocupado;

    return Scaffold(
      backgroundColor: corFundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            children: [
              // CABEÇALHO

              Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () =>
                        Navigator.maybePop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: corPrincipal,
                    ),
                  ),

                  Expanded(
                    child: Text(
                      'Enviar',
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

              const SizedBox(height: 20),

              // STATUS DA FILA

              _buildMensagem(),

              const SizedBox(height: 16),

              // PALAVRA ATUAL E CONTROLES

              _buildPalavraAtual(atual),

              const SizedBox(height: 12),

              // ÚLTIMA PALAVRA

              _buildUltimaPalavra(),

              Divider(
                color: corDivisoria,
              ),

              // FILA DE PALAVRAS

              _buildCabecalhoFila(bloqueioEdicao),

              Expanded(
                child: _buildListaFila(bloqueioEdicao),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
