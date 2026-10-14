import 'package:flutter/material.dart';
import '../database/banco_dedole.dart';

/// Preferências persistidas no mesmo SQLite das palavras e da fila.
class PreferenciasDedole extends ChangeNotifier {
  PreferenciasDedole._();
  static final PreferenciasDedole instance = PreferenciasDedole._();

  String tema = 'sistema'; // claro, escuro ou sistema
  bool altoContraste = false;
  bool textoAmpliado = false;
  bool _inicializado = false;
  Future<void> _gravacao = Future<void>.value();

  Future<void> inicializar() async {
    if (_inicializado) return;
    final valores = await BancoDedole.carregarPreferencias();
    final salvo = valores['tema'];
    if (salvo == 'claro' || salvo == 'escuro' || salvo == 'sistema') tema = salvo!;
    altoContraste = valores['alto_contraste'] == '1';
    textoAmpliado = valores['texto_ampliado'] == '1';
    _inicializado = true;
    notifyListeners();
  }

  void _salvar() {
    final copia = <String, String>{
      'tema': tema,
      'alto_contraste': altoContraste ? '1' : '0',
      'texto_ampliado': textoAmpliado ? '1' : '0',
    };
    _gravacao = _gravacao.then((_) => BancoDedole.salvarPreferencias(copia));
    _gravacao = _gravacao.catchError((Object erro) {
      debugPrint('Erro ao salvar preferências do Dedolê: $erro');
    });
  }

  void definirTema(String novo) {
    if (!['claro', 'escuro', 'sistema'].contains(novo)) return;
    tema = novo;
    _salvar();
    notifyListeners();
  }

  void definirContraste(bool valor) {
    altoContraste = valor;
    _salvar();
    notifyListeners();
  }

  void definirTextoAmpliado(bool valor) {
    textoAmpliado = valor;
    _salvar();
    notifyListeners();
  }

  ThemeMode get themeMode => switch (tema) {
    'claro' => ThemeMode.light,
    'escuro' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
