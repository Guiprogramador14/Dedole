import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import '../utils/bluetooth_service.dart';

class TelaAlfabeto extends StatefulWidget {
  const TelaAlfabeto({super.key});

  @override
  State<TelaAlfabeto> createState() => _TelaAlfabetoState();
}

class _TelaAlfabetoState extends State<TelaAlfabeto> {
  static const Color cor = Color(0xFF1B2161);
  static const Color fundo = Color(0xFFF6F7FF);
  static const String respostaUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26aa';
  static const String letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  bool enviando = false;
  String? letraAtiva;
  String status = 'Selecione uma letra para representar em Braille.';
  BluetoothCharacteristic? resposta;
  StreamSubscription<List<int>>? assinatura;
  StreamSubscription<BluetoothConnectionState>? conexao;

  @override
  void initState() {
    super.initState();
    iniciarNotificacoes();
  }

  void falar(String mensagem) {
    if (!mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      mensagem,
      TextDirection.ltr,
    );
  }

  void informar(String mensagem, {bool mostrarAviso = false}) {
    if (!mounted) return;
    setState(() => status = mensagem);
    falar(mensagem);
    if (mostrarAviso) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
    }
  }

  Future<void> iniciarNotificacoes() async {
    final device = BluetoothService.instance.dispositivo;
    if (device == null || !BluetoothService.instance.conectado) return;

    try {
      conexao = device.connectionState.listen((estado) {
        if (!mounted) return;
        if (estado == BluetoothConnectionState.disconnected) {
          setState(() => letraAtiva = null);
          informar('Dedolê desconectado. Conecte a máquina para continuar.',
              mostrarAviso: true);
        }
      });

      final servicos = await device.discoverServices();
      for (final servico in servicos) {
        if (servico.uuid.toString().toLowerCase() !=
            BluetoothService.serviceUuid.toLowerCase()) {
          continue;
        }
        for (final caracteristica in servico.characteristics) {
          if (caracteristica.uuid.toString().toLowerCase() != respostaUuid) {
            continue;
          }

          resposta = caracteristica;
          assinatura = caracteristica.onValueReceived.listen((bytes) {
            final mensagem = String.fromCharCodes(bytes).trim().toUpperCase();
            if (!mounted) return;

            if (mensagem.startsWith('ACERTOU:')) {
              final letra = mensagem.substring('ACERTOU:'.length).trim();
              if (letra == letraAtiva) {
                setState(() => letraAtiva = null);
                informar('Correto! Letra $letra representada corretamente. '
                    'Todos os pontos voltaram à posição inicial.',
                    mostrarAviso: true);
              }
            }
          });
          await caracteristica.setNotifyValue(true);
          return;
        }
      }
      informar('Não foi possível encontrar as respostas da máquina.',
          mostrarAviso: true);
    } catch (e) {
      informar('Não foi possível ativar as respostas da máquina.',
          mostrarAviso: true);
    }
  }

  Future<void> selecionar(String letra) async {
    if (enviando) return;
    if (!BluetoothService.instance.conectado) {
      informar('Dedolê não conectado. Conecte a máquina pelo Bluetooth primeiro.',
          mostrarAviso: true);
      return;
    }

    final cancelando = letraAtiva == letra;
    setState(() => enviando = true);
    try {
      if (cancelando) {
        await BluetoothService.instance.enviarComando('RESET');
        if (!mounted) return;
        setState(() => letraAtiva = null);
        informar('Letra $letra cancelada. Pontos enviados para a posição inicial.');
      } else {
        await BluetoothService.instance.enviarComando(letra);
        if (!mounted) return;
        setState(() => letraAtiva = letra);
        informar('Letra $letra enviada ao Dedolê. '
            'Toque nos botões físicos correspondentes aos pontos Braille.');
      }
    } catch (e) {
      informar('Falha na comunicação com o Dedolê. Tente novamente.',
          mostrarAviso: true);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  Future<void> voltar() async {
    if (enviando) return;
    if (letraAtiva != null && BluetoothService.instance.conectado) {
      try {
        await BluetoothService.instance.enviarComando('RESET');
      } catch (_) {
        if (mounted) {
          informar('Não foi possível reiniciar os pontos da máquina.',
              mostrarAviso: true);
        }
        return;
      }
    }
    if (mounted) Navigator.maybePop(context);
  }

  @override
  void dispose() {
    assinatura?.cancel();
    conexao?.cancel();
    super.dispose();
  }

  Widget criarLetra(String letra) {
    final ativa = letraAtiva == letra;
    final acao = ativa ? 'Parar' : 'Representar';

    return Column(children: [
      Semantics(
        container: true,
        explicitChildNodes: true,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          title: Text('LETRA $letra',
              style: const TextStyle(
                  color: cor, fontSize: 21, fontWeight: FontWeight.w600)),
          subtitle: ativa
              ? const Text('Aguardando resposta nos botões físicos',
                  style: TextStyle(color: cor, fontSize: 12))
              : null,
          trailing: IconButton(
            tooltip: '$acao letra $letra',
            onPressed: enviando ? null : () => selecionar(letra),
            iconSize: 40,
            color: cor,
            icon: Icon(ativa
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline),
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
                onPressed: enviando ? null : voltar,
              ),
              const Expanded(
                child: Text('Alfabeto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cor, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Selecione uma letra para representar em Braille',
                  style: TextStyle(color: cor, fontSize: 14)),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              label: 'Estado da atividade: $status',
              child: ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(status,
                      style: const TextStyle(
                          color: cor, fontSize: 13, fontWeight: FontWeight.w500)),
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
