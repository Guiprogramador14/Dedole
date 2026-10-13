import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import '../utils/bluetooth_service.dart';

class TelaAlfabeto extends StatefulWidget {
  const TelaAlfabeto({super.key});
  @override
  State<TelaAlfabeto> createState() => _TelaAlfabetoState();
}

class _TelaAlfabetoState extends State<TelaAlfabeto> {
  static const cor = Color(0xFF1B2161);
  static const fundo = Color(0xFFF6F7FF);
  static const respostaUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26aa';
  static const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  bool enviando = false;
  String? letraAtiva;
  BluetoothCharacteristic? resposta;
  StreamSubscription<List<int>>? assinatura;
  StreamSubscription<BluetoothConnectionState>? conexao;

  @override
  void initState() {
    super.initState();
    iniciarNotificacoes();
  }

  Future<void> iniciarNotificacoes() async {
    final device = BluetoothService.instance.dispositivo;
    if (device == null || !BluetoothService.instance.conectado) return;
    try {
      conexao = device.connectionState.listen((estado) {
        if (estado == BluetoothConnectionState.disconnected && mounted) {
          setState(() => letraAtiva = null);
        }
      });
      final servicos = await device.discoverServices();
      for (final servico in servicos) {
        if (servico.uuid.toString().toLowerCase() != BluetoothService.serviceUuid) continue;
        for (final caracteristica in servico.characteristics) {
          if (caracteristica.uuid.toString().toLowerCase() == respostaUuid) {
            resposta = caracteristica;
            assinatura = caracteristica.onValueReceived.listen((bytes) {
              final mensagem = String.fromCharCodes(bytes).trim().toUpperCase();
              if (!mounted) return;
              if (mensagem.startsWith('ACERTOU:')) {
                final letra = mensagem.substring(8);
                if (letra == letraAtiva) {
                  setState(() => letraAtiva = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Correto! Letra $letra concluída.')),
                  );
                }
              }
            });
            await caracteristica.setNotifyValue(true);
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) aviso('Não foi possível ativar as respostas: $e');
    }
  }

  Future<void> selecionar(String letra) async {
    if (enviando) return;
    if (!BluetoothService.instance.conectado) {
      aviso('Conecte o Dedolê pelo Bluetooth primeiro.');
      return;
    }
    setState(() => enviando = true);
    try {
      if (letraAtiva == letra) {
        await BluetoothService.instance.enviarComando('RESET');
        if (mounted) setState(() => letraAtiva = null);
      } else {
        // O ESP32 executa RESET antes de levantar a nova letra.
        await BluetoothService.instance.enviarComando(letra);
        if (mounted) setState(() => letraAtiva = letra);
      }
    } catch (e) {
      aviso('Erro na comunicação: $e');
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  void aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  void dispose() {
    assinatura?.cancel();
    conexao?.cancel();
    // Não envia RESET no dispose: envio assíncrono aqui seria inseguro.
    super.dispose();
  }

  Widget criarLetra(String letra) {
    final ativa = letraAtiva == letra;
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        title: Text('LETRA $letra', style: const TextStyle(
          color: cor, fontSize: 21, fontWeight: FontWeight.w600,
        )),
        subtitle: ativa ? const Text('Aguardando resposta nos botões físicos',
          style: TextStyle(color: cor, fontSize: 12)) : null,
        trailing: Semantics(
          button: true,
          label: ativa ? 'Parar letra $letra' : 'Reproduzir letra $letra',
          child: IconButton(
            tooltip: ativa ? 'Parar letra $letra' : 'Reproduzir letra $letra',
            onPressed: enviando ? null : () => selecionar(letra),
            iconSize: 40,
            color: cor,
            icon: Icon(ativa ? Icons.stop_circle_outlined : Icons.play_circle_outline),
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
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(children: [
          Row(children: [
            IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Voltar',
              icon: const Icon(Icons.arrow_back_ios_new, color: cor),
              onPressed: () async {
                if (letraAtiva != null && !enviando) {
                  try { await BluetoothService.instance.enviarComando('RESET'); } catch (_) {}
                }
                if (context.mounted) Navigator.maybePop(context);
              },
            ),
            const Expanded(child: Text('Alfabeto', textAlign: TextAlign.center,
              style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 48),
          ]),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft,
            child: Text('Selecione uma letra para representar em Braille',
              style: TextStyle(color: cor, fontSize: 14))),
          const SizedBox(height: 12),
          Expanded(child: ListView.builder(
            itemCount: letras.length,
            itemBuilder: (_, i) => criarLetra(letras[i]),
          )),
        ]),
      )),
    );
  }
}
