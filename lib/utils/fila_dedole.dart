import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'bluetooth_service.dart';

/// Controlador compartilhado de palavras, letras, cores e algarismos.
class FilaDedole extends ChangeNotifier {
  FilaDedole._();
  static final FilaDedole instance = FilaDedole._();

  static const String respostaUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26aa';
  static const String _numerosBraille = 'JABCDEFGHI';
  final List<String> _itens = [];
  List<String> get itens => List.unmodifiable(_itens);

  String? ultimaPalavra;
  String? palavraEmExecucao;
  int indiceLetra = 0;
  String mensagem = 'Adicione palavras à fila ou escolha uma palavra.';
  bool ocupado = false;
  bool _iniciado = false;
  bool _processando = false;
  bool _aguardandoSinalNumero = false;
  int _geracao = 0;
  StreamSubscription<List<int>>? _respostas;
  StreamSubscription<BluetoothConnectionState>? _conexao;
  Future<void> _comandos = Future<void>.value();

  bool get reproduzindo => palavraEmExecucao != null;
  bool get aguardandoSinalNumero => reproduzindo && _aguardandoSinalNumero;
  bool get numeroEmExecucao => reproduzindo && RegExp(r'^[0-9]$').hasMatch(palavraEmExecucao!);
  String get letraAtual {
    if (!reproduzindo) return '';
    if (numeroEmExecucao) {
      return _aguardandoSinalNumero ? '#' : _numerosBraille[int.parse(palavraEmExecucao!)];
    }
    return palavraEmExecucao![indiceLetra];
  }

  static String? validar(String texto) {
    final palavra = texto.trim().toUpperCase();
    if (palavra.isEmpty || !RegExp(r'^[A-Z]+$').hasMatch(palavra)) return null;
    return palavra;
  }

  static String? _validarItem(String texto) {
    final item = texto.trim().toUpperCase();
    if (RegExp(r'^[0-9]$').hasMatch(item)) return item;
    return validar(item);
  }

  bool adicionar(String texto) {
    final item = _validarItem(texto);
    if (item == null) return false;
    _itens.add(item);
    mensagem = '$item adicionado ao final da fila.';
    notifyListeners();
    return true;
  }

  void remover(int index) {
    if (reproduzindo || ocupado || index < 0 || index >= _itens.length) return;
    _itens.removeAt(index);
    notifyListeners();
  }

  void limpar() {
    if (reproduzindo || ocupado) return;
    _itens.clear();
    mensagem = 'Fila limpa.';
    notifyListeners();
  }

  void reordenar(int anterior, int novo) {
    if (reproduzindo || ocupado || anterior < 0 || anterior >= _itens.length) return;
    if (novo > anterior) novo--;
    if (novo < 0 || novo >= _itens.length) return;
    final item = _itens.removeAt(anterior);
    _itens.insert(novo, item);
    notifyListeners();
  }

  Future<void> preparar() async {
    if (_respostas != null && BluetoothService.instance.conectado) return;
    if (!BluetoothService.instance.conectado || BluetoothService.instance.dispositivo == null) {
      mensagem = 'Conecte o Dedolê pelo Bluetooth.';
      notifyListeners();
      return;
    }
    if (_iniciado) {
      while (_iniciado) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      return;
    }
    _iniciado = true;
    try {
      final device = BluetoothService.instance.dispositivo!;
      await _conexao?.cancel();
      _conexao = device.connectionState.listen((estado) {
        if (estado == BluetoothConnectionState.disconnected) {
          _geracao++;
          palavraEmExecucao = null;
          indiceLetra = 0;
          ocupado = false;
          _processando = false;
          _aguardandoSinalNumero = false;
          _iniciado = false;
          _respostas?.cancel();
          _respostas = null;
          mensagem = 'Dedolê desconectado. Reprodução interrompida.';
          notifyListeners();
        }
      });
      final servicos = await device.discoverServices();
      for (final servico in servicos) {
        if (servico.uuid.toString().toLowerCase() != BluetoothService.serviceUuid.toLowerCase()) continue;
        for (final caracteristica in servico.characteristics) {
          if (caracteristica.uuid.toString().toLowerCase() != respostaUuid) continue;
          await _respostas?.cancel();
          _respostas = caracteristica.onValueReceived.listen((bytes) {
            final resposta = String.fromCharCodes(bytes).trim().toUpperCase();
            if (!resposta.startsWith('ACERTOU:')) return;
            final letra = resposta.substring('ACERTOU:'.length).trim();
            if (reproduzindo && !ocupado && !_processando && letra == letraAtual) {
              _avancar();
            }
          });
          await caracteristica.setNotifyValue(true);
          _iniciado = false;
          return;
        }
      }
      mensagem = 'Característica de resposta do ESP32 não encontrada.';
      notifyListeners();
    } catch (e) {
      mensagem = 'Erro ao configurar Bluetooth: $e';
      notifyListeners();
    } finally {
      _iniciado = false;
    }
  }

  Future<void> _enfileirarComando(Future<void> Function() tarefa) {
    final resultado = _comandos.then((_) => tarefa());
    _comandos = resultado.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return resultado;
  }

  Future<void> play(String texto, {bool retirarDaFila = false}) async {
    final item = _validarItem(texto);
    if (item == null) {
      mensagem = 'Use letras A a Z ou um único algarismo de 0 a 9.';
      notifyListeners();
      return;
    }
    final versao = ++_geracao;
    palavraEmExecucao = null;
    indiceLetra = 0;
    _aguardandoSinalNumero = false;
    ocupado = true;
    mensagem = 'Preparando $item...';
    notifyListeners();
    await preparar();
    if (versao != _geracao) return;
    if (!BluetoothService.instance.conectado || _respostas == null) {
      ocupado = false;
      mensagem = 'Conecte o Dedolê para reproduzir.';
      notifyListeners();
      return;
    }
    final ehNumero = RegExp(r'^[0-9]$').hasMatch(item);
    try {
      await _enfileirarComando(() async {
        if (versao != _geracao) return;
        await BluetoothService.instance.enviarComando('RESET');
        if (versao != _geracao) return;
        await BluetoothService.instance.enviarComando(ehNumero ? 'NUM' : item[0]);
      });
      if (versao != _geracao) return;
      palavraEmExecucao = item;
      ultimaPalavra = item;
      indiceLetra = 0;
      _aguardandoSinalNumero = ehNumero;
      if (retirarDaFila) {
        final indice = _itens.indexOf(item);
        if (indice >= 0) _itens.removeAt(indice);
      }
      mensagem = ehNumero
          ? 'Número $item. Sinal numérico: pressione os pontos 3, 4, 5 e 6.'
          : 'Reproduzindo $item. Letra ${item[0]}.';
    } catch (e) {
      if (versao == _geracao) mensagem = 'Erro ao iniciar $item: $e';
    } finally {
      if (versao == _geracao) {
        ocupado = false;
        notifyListeners();
      }
    }
  }

  Future<void> tocarPrimeiro() async {
    if (_itens.isEmpty) return;
    await play(_itens.first, retirarDaFila: true);
  }

  Future<void> retomarUltima() async {
    if (ultimaPalavra != null) await play(ultimaPalavra!);
  }

  Future<void> parar() async {
    final versao = ++_geracao;
    palavraEmExecucao = null;
    indiceLetra = 0;
    _aguardandoSinalNumero = false;
    ocupado = true;
    mensagem = 'Parando reprodução...';
    notifyListeners();
    try {
      await _enfileirarComando(() async {
        if (versao == _geracao && BluetoothService.instance.conectado) {
          await BluetoothService.instance.enviarComando('RESET');
        }
      });
      if (versao == _geracao) mensagem = 'Reprodução parada. Fila mantida.';
    } catch (e) {
      if (versao == _geracao) mensagem = 'Erro ao parar: $e';
    } finally {
      if (versao == _geracao) {
        ocupado = false;
        notifyListeners();
      }
    }
  }

  Future<void> _avancar() async {
    if (!reproduzindo || _processando) return;
    final versao = _geracao;
    final item = palavraEmExecucao!;
    final concluida = letraAtual;
    _processando = true;
    ocupado = true;
    notifyListeners();
    try {
      if (numeroEmExecucao && _aguardandoSinalNumero) {
        final letra = _numerosBraille[int.parse(item)];
        await _enfileirarComando(() async {
          if (versao == _geracao) await BluetoothService.instance.enviarComando(letra);
        });
        if (versao != _geracao) return;
        _aguardandoSinalNumero = false;
        mensagem = 'Correto! Sinal numérico concluído. Algarismo $item representado. Pressione os pontos correspondentes.';
      } else {
        final proximo = indiceLetra + 1;
        if (numeroEmExecucao || proximo >= item.length) {
          if (versao != _geracao) return;
          palavraEmExecucao = null;
          indiceLetra = 0;
          _aguardandoSinalNumero = false;
          mensagem = RegExp(r'^[0-9]$').hasMatch(item)
              ? 'Correto! Número $item concluído.'
              : 'Correto! Palavra $item concluída.';
        } else {
          await _enfileirarComando(() async {
            if (versao == _geracao) await BluetoothService.instance.enviarComando(item[proximo]);
          });
          if (versao != _geracao) return;
          indiceLetra = proximo;
          mensagem = 'Correto! Letra $concluida. Próxima letra: ${item[proximo]}.';
        }
      }
    } catch (e) {
      if (versao == _geracao) mensagem = 'Falha ao avançar: $e';
    } finally {
      _processando = false;
      if (versao == _geracao) {
        ocupado = false;
        notifyListeners();
      }
    }
  }
}
