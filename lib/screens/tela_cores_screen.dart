
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../utils/fila_dedole.dart';

class TelaCores extends StatefulWidget {
  const TelaCores({super.key});

  @override
  State<TelaCores> createState() => _TelaCoresState();
}

class _TelaCoresState extends State<TelaCores> {
  // ==========================================
  // LISTA DE CORES
  // ==========================================
  // As cores originais são preservadas em
  // todos os temas do aplicativo.

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

    mensagemAnterior = fila.mensagem;
    fila.addListener(atualizar);
    fila.preparar();
  }

  // ==========================================
  // ATUALIZAÇÃO DA FILA
  // ==========================================

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

  // ==========================================
  // MENSAGENS E ACESSIBILIDADE
  // ==========================================

  void aviso(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

    SemanticsService.sendAnnouncement(
      View.of(context),
      texto,
      TextDirection.ltr,
    );
  }

  // ==========================================
  // ADICIONAR COR À FILA
  // ==========================================

  void adicionarFila(String nome) {
    if (fila.adicionar(nome)) {
      aviso('$nome adicionado ao final da fila.');
    } else {
      aviso('Não foi possível adicionar $nome à fila.');
    }
  }

  // ==========================================
  // REPRODUZIR OU PARAR COR
  // ==========================================

  Future<void> selecionarCor(String nome) async {
    // Mantém o mesmo comportamento original:
    // - Se a cor estiver em reprodução, para.
    // - Caso contrário, reproduz a cor.
    // - Um novo Play pode substituir a reprodução
    //   anterior, mesmo durante uma operação BLE.

    if (fila.reproduzindo &&
        fila.palavraEmExecucao == nome) {
      await fila.parar();
    } else {
      await fila.play(nome);
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
  // CRIAR ITEM DE COR
  // ==========================================

  Widget criarCor(({String nome, Color cor}) item) {
    final ativa = fila.reproduzindo &&
        fila.palavraEmExecucao == item.nome;

    final acao = ativa
        ? 'Parar cor ${item.nome}'
        : 'Reproduzir cor ${item.nome}';

    // Mantém as dimensões originais, mas permite
    // que os textos sejam ampliados pelo tema global.

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 5,
          ),

          // ==================================
          // CÍRCULO COLORIDO
          // ==================================

          leading: ExcludeSemantics(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.cor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: corTexto.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),

          // ==================================
          // NOME DA COR
          // ==================================

          title: Text(
            item.nome,
            softWrap: true,
            style: TextStyle(
              color: corTexto,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          // ==================================
          // PROGRESSO DA REPRODUÇÃO
          // ==================================

          subtitle: ativa
              ? Text(
                  'Letra ${fila.letraAtual} '
                  '(${fila.indiceLetra + 1} '
                  'de ${item.nome.length})',
                  softWrap: true,
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 13,
                  ),
                )
              : null,

          // ==================================
          // BOTÕES DA COR
          // ==================================

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ADICIONAR À FILA

              IconButton(
                tooltip:
                    'Adicionar cor ${item.nome} ao final da fila',
                onPressed: () => adicionarFila(item.nome),
                icon: Icon(
                  Icons.playlist_add,
                  color: corPrincipal,
                ),
              ),

              // PLAY / STOP

              IconButton(
                tooltip: acao,
                onPressed: () => selecionarCor(item.nome),
                iconSize: 40,
                color: corPrincipal,
                icon: Icon(
                  ativa
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
                ),
              ),
            ],
          ),
        ),

        // DIVISÓRIA QUE ACOMPANHA O TEMA

        Divider(
          height: 1,
          color: corDivisoria,
        ),
      ],
    );
  }

  // ==========================================
  // INTERFACE PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
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
              // ==================================
              // CABEÇALHO
              // ==================================

              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
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

              // ==================================
              // INSTRUÇÕES
              // ==================================

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecione uma cor para representar '
                  'em Braille ou adicionar à fila',
                  softWrap: true,
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================
              // ESTADO DA ATIVIDADE
              // ==================================

              Semantics(
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
              ),

              const SizedBox(height: 12),

              // ==================================
              // LISTA DE CORES
              // ==================================

              Expanded(
                child: ListView.builder(
                  itemCount: cores.length,
                  itemBuilder: (context, i) =>
                      criarCor(cores[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
