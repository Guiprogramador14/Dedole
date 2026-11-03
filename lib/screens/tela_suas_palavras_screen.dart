
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../database/banco_dedole.dart';
import '../utils/fila_dedole.dart';

class TelaSuasPalavras extends StatefulWidget {
  const TelaSuasPalavras({super.key});

  @override
  State<TelaSuasPalavras> createState() =>
      _TelaSuasPalavrasState();
}

class _TelaSuasPalavrasState extends State<TelaSuasPalavras> {
  final FilaDedole fila = FilaDedole.instance;

  List<Map<String, dynamic>> palavras = [];
  bool carregando = true;
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

  Color get corDesabilitada =>
      Theme.of(context).disabledColor;

  // ==========================================
  // INICIALIZAÇÃO
  // ==========================================

  @override
  void initState() {
    super.initState();

    anterior = fila.mensagem;
    fila.addListener(atualizar);

    carregarPalavras();
    fila.preparar();
  }

  // ==========================================
  // ATUALIZAÇÃO E ACESSIBILIDADE
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
  // MENSAGENS
  // ==========================================

  void aviso(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
      ),
    );

    SemanticsService.sendAnnouncement(
      View.of(context),
      texto,
      TextDirection.ltr,
    );
  }

  // ==========================================
  // CARREGAR PALAVRAS DO SQLITE
  // ==========================================

  Future<void> carregarPalavras() async {
    try {
      final resultado = await BancoDedole.buscarPalavras();

      if (!mounted) return;

      setState(() {
        palavras = resultado;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => carregando = false);

      aviso('Erro ao carregar palavras: $e');
    }
  }

  // ==========================================
  // ADICIONAR OU EDITAR PALAVRA
  // ==========================================

  Future<void> editar({
    Map<String, dynamic>? registro,
  }) async {
    if (fila.reproduzindo || fila.ocupado) return;

    final editando = registro != null;

    final controller = TextEditingController(
      text: editando
          ? registro['palavra'].toString()
          : '',
    );

    String? erro;

    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, atualizarDialogo) => AlertDialog(
          title: Text(
            editando
                ? 'Editar palavra'
                : 'Adicionar palavra',
          ),

          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization:
                TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z]'),
              ),
            ],
            decoration: InputDecoration(
              labelText: 'Palavra',
              hintText: 'CASA',
              errorText: erro,
              border: const OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                final valor =
                    FilaDedole.validar(controller.text);

                if (valor == null) {
                  atualizarDialogo(() {
                    erro =
                        'Use letras A a Z, sem espaços ou acentos.';
                  });
                } else {
                  Navigator.pop(ctx, valor);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (resultado == null || !mounted) return;

    if (fila.reproduzindo || fila.ocupado) {
      aviso(
        'Aguarde o fim da reprodução para alterar palavras.',
      );
      return;
    }

    try {
      if (editando) {
        await BancoDedole.editarPalavra(
          registro['id'] as int,
          resultado,
        );
      } else {
        await BancoDedole.adicionarPalavra(
          resultado,
        );
      }

      await carregarPalavras();

      aviso(
        editando
            ? 'Palavra atualizada.'
            : 'Palavra salva.',
      );
    } catch (e) {
      aviso('Erro ao salvar: $e');
    }
  }

  // ==========================================
  // EXCLUIR PALAVRA
  // ==========================================

  Future<void> excluir(
    Map<String, dynamic> registro,
  ) async {
    if (fila.reproduzindo || fila.ocupado) return;

    final nome = registro['palavra'].toString();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir palavra?'),
        content: Text(
          'Excluir "$nome" do banco de dados?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),

          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true ||
        !mounted ||
        fila.reproduzindo ||
        fila.ocupado) {
      return;
    }

    try {
      await BancoDedole.excluirPalavra(
        registro['id'] as int,
      );

      await carregarPalavras();

      aviso('Palavra $nome excluída.');
    } catch (e) {
      aviso('Erro ao excluir: $e');
    }
  }

  // ==========================================
  // ADICIONAR PALAVRA À FILA
  // ==========================================

  void adicionarFila(String nome) {
    if (fila.adicionar(nome)) {
      aviso(
        '$nome adicionado ao final da fila.',
      );
    } else {
      aviso(
        'Não foi possível adicionar $nome.',
      );
    }
  }

  // ==========================================
  // REPRODUZIR OU PARAR PALAVRA
  // ==========================================

  Future<void> selecionarPalavra(
    String nome,
  ) async {
    // Mantém o comportamento já corrigido:
    // se a palavra está ativa, o botão para.
    // Caso contrário, inicia a reprodução.

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
  // CABEÇALHO
  // ==========================================

  Widget _buildCabecalho(
    bool bloqueioEdicao,
  ) {
    return Row(
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
            'Suas palavras',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: corTexto,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        IconButton(
          tooltip: 'Adicionar palavra ao banco',
          onPressed: bloqueioEdicao
              ? null
              : () => editar(),
          icon: Icon(
            Icons.add_circle_outline,
            color: bloqueioEdicao
                ? corDesabilitada
                : corPrincipal,
            size: 30,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MENSAGEM DA FILA
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
  // ITEM DA LISTA
  // ==========================================

  Widget _buildItemPalavra(
    Map<String, dynamic> registro,
    bool bloqueioEdicao,
  ) {
    final nome = registro['palavra']
        .toString()
        .toUpperCase();

    final ativa = fila.reproduzindo &&
        fila.palavraEmExecucao == nome;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 5,
      ),

      // NOME DA PALAVRA

      title: Text(
        nome,
        softWrap: true,
        style: TextStyle(
          color: corTexto,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),

      // PROGRESSO DA REPRODUÇÃO

      subtitle: ativa
          ? Text(
              'Letra ${fila.letraAtual} '
              '(${fila.indiceLetra + 1} '
              'de ${nome.length})',
              softWrap: true,
              style: TextStyle(
                color: corTexto,
                fontSize: 12,
              ),
            )
          : null,

      // CONTROLES

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ADICIONAR À FILA

          IconButton(
            tooltip: 'Adicionar $nome ao final da fila',
            onPressed: () => adicionarFila(nome),
            icon: Icon(
              Icons.playlist_add,
              color: corPrincipal,
            ),
          ),

          // EDITAR / EXCLUIR

          PopupMenuButton<String>(
            tooltip: 'Opções de $nome',
            enabled: !bloqueioEdicao,
            icon: Icon(
              Icons.more_vert,
              color: bloqueioEdicao
                  ? corDesabilitada
                  : corPrincipal,
            ),
            onSelected: (acao) {
              if (acao == 'editar') {
                editar(registro: registro);
              }

              if (acao == 'excluir') {
                excluir(registro);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'editar',
                child: Text('Editar'),
              ),
              PopupMenuItem(
                value: 'excluir',
                child: Text('Excluir'),
              ),
            ],
          ),

          // PLAY / STOP

          IconButton(
            tooltip: ativa
                ? 'Parar reprodução de $nome'
                : 'Reproduzir $nome, prioridade máxima',
            onPressed: () =>
                selecionarPalavra(nome),
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
    );
  }

  // ==========================================
  // INTERFACE PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
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

              _buildCabecalho(
                bloqueioEdicao,
              ),

              const SizedBox(height: 24),

              // INSTRUÇÕES

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Escolha uma palavra para reproduzir '
                  'ou adicionar à fila',
                  softWrap: true,
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // MENSAGEM DA FILA

              _buildMensagem(),

              const SizedBox(height: 12),

              // LISTA DE PALAVRAS

              Expanded(
                child: carregando
                    ? const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    : palavras.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhuma palavra salva. '
                              'Toque em + para adicionar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: corTexto,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: palavras.length,

                            separatorBuilder:
                                (_, __) => Divider(
                              height: 1,
                              color: corDivisoria,
                            ),

                            itemBuilder: (context, i) {
                              final registro = palavras[i];

                              return _buildItemPalavra(
                                registro,
                                bloqueioEdicao,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
