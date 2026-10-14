import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../database/banco_dedole.dart';
import '../utils/preferencias_dedole.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  final prefs = PreferenciasDedole.instance;
  bool excluindo = false;

  @override
  void initState() {
    super.initState();
    prefs.addListener(_atualizar);
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    prefs.removeListener(_atualizar);
    super.dispose();
  }

  void _avisar(String texto) {
    if (!mounted) return;
    SemanticsService.sendAnnouncement(View.of(context), texto, TextDirection.ltr);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _confirmarLimpeza() async {
    if (excluindo) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpar banco de palavras?'),
        content: const Text(
          'Todas as palavras cadastradas em “Suas Palavras” serão excluídas permanentemente. '
          'A fila de reprodução e as configurações serão mantidas. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir palavras'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => excluindo = true);
    try {
      final total = await BancoDedole.limparPalavras();
      _avisar('$total palavra(s) excluída(s). A fila foi mantida.');
    } catch (e) {
      _avisar('Não foi possível limpar as palavras: $e');
    } finally {
      if (mounted) setState(() => excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Cores calculadas diretamente das preferências: esta tela reage mesmo
    // quando outras telas ainda usam cores fixas.
    final escuro = prefs.tema == 'escuro' ||
        (prefs.tema == 'sistema' &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final contraste = prefs.altoContraste;
    final fundo = contraste
        ? (escuro ? const Color(0xFF111100) : const Color(0xFFFFF4AE))
        : (escuro ? const Color(0xFF151829) : const Color(0xFFF6F7FF));
    final cor = contraste
        ? (escuro ? const Color(0xFFFFFF65) : const Color(0xFF191900))
        : (escuro ? const Color(0xFFF6F7FF) : const Color(0xFF1B2161));
    final superficie = contraste
        ? (escuro ? const Color(0xFF252500) : const Color(0xFFFFF9D6))
        : (escuro ? const Color(0xFF23273B) : Colors.white);
    final temaLocal = tema.copyWith(
      brightness: escuro ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: fundo,
      cardTheme: CardThemeData(color: superficie),
      colorScheme: tema.colorScheme.copyWith(
        brightness: escuro ? Brightness.dark : Brightness.light,
        primary: cor,
        onPrimary: fundo,
        surface: superficie,
        onSurface: cor,
      ),
      textTheme: tema.textTheme.apply(bodyColor: cor, displayColor: cor),
      listTileTheme: ListTileThemeData(textColor: cor, iconColor: cor),
      iconTheme: IconThemeData(color: cor),
    );
    return Theme(
      data: temaLocal,
      child: Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_ios_new, color: cor),
                ),
                Expanded(
                  child: Text('Configurações', textAlign: TextAlign.center,
                      style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 48),
              ]),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(children: [
                  Text('Aparência', style: temaLocal.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.palette_outlined),
                          title: Text('Tema do aplicativo'),
                          subtitle: Text('Escolha o modo claro, escuro ou o tema do celular'),
                        ),
                        RadioListTile<String>(
                          title: const Text('Claro'), value: 'claro',
                          groupValue: prefs.tema, onChanged: (v) { if (v != null) prefs.definirTema(v); },
                        ),
                        RadioListTile<String>(
                          title: const Text('Escuro'), value: 'escuro',
                          groupValue: prefs.tema, onChanged: (v) { if (v != null) prefs.definirTema(v); },
                        ),
                        RadioListTile<String>(
                          title: const Text('Seguir o sistema'), value: 'sistema',
                          groupValue: prefs.tema, onChanged: (v) { if (v != null) prefs.definirTema(v); },
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Acessibilidade', style: temaLocal.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(child: Column(children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.contrast),
                      title: const Text('Alto contraste'),
                      subtitle: const Text('Paleta amarela e texto com maior contraste'),
                      value: prefs.altoContraste,
                      onChanged: prefs.definirContraste,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.format_size),
                      title: const Text('Texto ampliado'),
                      subtitle: const Text('Aumentar as letras em 20%'),
                      value: prefs.textoAmpliado,
                      onChanged: prefs.definirTextoAmpliado,
                    ),
                  ])),
                  const SizedBox(height: 18),
                  Text('Dados do aplicativo', style: temaLocal.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(child: ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                    title: const Text('Limpar banco de palavras'),
                    subtitle: const Text('Excluir todas as palavras salvas em “Suas Palavras”'),
                    trailing: excluindo ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
                    enabled: !excluindo,
                    onTap: excluindo ? null : _confirmarLimpeza,
                  )),
                  const SizedBox(height: 20),
                  const Center(child: Text('Dedolê • Tecnologia assistiva', textAlign: TextAlign.center)),
                ]),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
