import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import '../utils/bluetooth_service.dart';

class TelaNumeros extends StatefulWidget {
  const TelaNumeros({super.key});
  @override
  State<TelaNumeros> createState() => _TelaNumerosState();
}

class _TelaNumerosState extends State<TelaNumeros> {
  static const cor = Color(0xFF1B2161);
  static const fundo = Color(0xFFF6F7FF);
  static const respostaUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26aa';
  static const digitos = '0123456789';
  static const letrasDosNumeros = 'JABCDEFGHI';

  String? numeroAtivo;
  bool aguardandoSinal = false;
  bool enviando = false;
  bool processando = false;
  String mensagem = 'Selecione um número para representar em Braille.';
  int versao = 0;
  StreamSubscription<List<int>>? assinatura;
  StreamSubscription<BluetoothConnectionState>? conexao;

  @override
  void initState() {
    super.initState();
    iniciarNotificacoes();
  }

  void falar(String texto) {
    if (!mounted) return;
    setState(() => mensagem = texto);
    SemanticsService.sendAnnouncement(View.of(context), texto, TextDirection.ltr);
  }

  void aviso(String texto) {
    falar(texto);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> iniciarNotificacoes() async {
    final device = BluetoothService.instance.dispositivo;
    if (device == null || !BluetoothService.instance.conectado) return;
    try {
      conexao = device.connectionState.listen((estado) {
        if (!mounted || estado != BluetoothConnectionState.disconnected) return;
        versao++;
        setState(() {
          numeroAtivo = null;
          aguardandoSinal = false;
          enviando = false;
          processando = false;
        });
        aviso('Dedolê desconectado. Conecte a máquina para continuar.');
      });
      final servicos = await device.discoverServices();
      if (!mounted) return;
      for (final servico in servicos) {
        if (servico.uuid.toString().toLowerCase() != BluetoothService.serviceUuid.toLowerCase()) continue;
        for (final caracteristica in servico.characteristics) {
          if (caracteristica.uuid.toString().toLowerCase() != respostaUuid) continue;
          assinatura = caracteristica.onValueReceived.listen((bytes) {
            if (!mounted || numeroAtivo == null || enviando || processando) return;
            final texto = String.fromCharCodes(bytes).trim().toUpperCase();
            final esperado = aguardandoSinal
                ? 'ACERTOU:#'
                : 'ACERTOU:${letrasDosNumeros[int.parse(numeroAtivo!)]}';
            if (texto == esperado) avancar();
          });
          await caracteristica.setNotifyValue(true);
          return;
        }
      }
      aviso('A máquina não disponibilizou as confirmações dos botões físicos.');
    } catch (e) {
      aviso('Não foi possível ativar as respostas: $e');
    }
  }

  Future<void> selecionar(String numero) async {
    if (enviando || processando) return;
    if (!BluetoothService.instance.conectado) {
      aviso('Dedolê não conectado. Conecte a máquina pelo Bluetooth primeiro.');
      return;
    }
    final operacao = ++versao;
    final cancelar = numeroAtivo == numero;
    setState(() => enviando = true);
    try {
      if (cancelar) {
        await BluetoothService.instance.enviarComando('RESET');
        if (!mounted || operacao != versao) return;
        setState(() {
          numeroAtivo = null;
          aguardandoSinal = false;
        });
        falar('Número $numero cancelado. Pontos retornaram à posição inicial.');
      } else {
        // NUM é o comando especial para o sinal Braille de número (3456).
        await BluetoothService.instance.enviarComando('NUM');
        if (!mounted || operacao != versao) return;
        setState(() {
          numeroAtivo = numero;
          aguardandoSinal = true;
        });
        falar('Número $numero. Sinal de número representado na máquina. Pressione os pontos 3, 4, 5 e 6.');
      }
    } catch (e) {
      aviso('Erro na comunicação: $e');
    } finally {
      if (mounted && operacao == versao) setState(() => enviando = false);
    }
  }

  Future<void> avancar() async {
    final numero = numeroAtivo;
    if (numero == null || processando) return;
    final operacao = versao;
    processando = true;
    try {
      if (aguardandoSinal) {
        final letra = letrasDosNumeros[int.parse(numero)];
        setState(() => enviando = true);
        // O firmware abaixa tudo antes de representar a nova célula.
        await BluetoothService.instance.enviarComando(letra);
        if (!mounted || operacao != versao) return;
        setState(() => aguardandoSinal = false);
        falar('Correto! Sinal de número concluído. Agora o algarismo $numero foi representado na máquina. Pressione os pontos correspondentes.');
      } else {
        if (!mounted || operacao != versao) return;
        setState(() {
          numeroAtivo = null;
          aguardandoSinal = false;
        });
        falar('Correto! Número $numero representado corretamente. Todos os pontos voltaram à posição inicial.');
      }
    } catch (e) {
      aviso('Erro ao avançar: $e. Use Parar para reiniciar.');
    } finally {
      processando = false;
      if (mounted && operacao == versao) setState(() => enviando = false);
    }
  }

  Future<void> voltar() async {
    if (enviando || processando) return;
    if (numeroAtivo != null && BluetoothService.instance.conectado) {
      try {
        await BluetoothService.instance.enviarComando('RESET');
      } catch (_) {}
    }
    if (mounted) Navigator.maybePop(context);
  }

  @override
  void dispose() {
    versao++;
    assinatura?.cancel();
    conexao?.cancel();
    super.dispose();
  }

  Widget criarNumero(String numero) {
    final ativo = numeroAtivo == numero;
    final acao = ativo ? 'Parar número $numero' : 'Representar número $numero';
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        title: Text('NÚMERO $numero', style: const TextStyle(color: cor, fontSize: 21, fontWeight: FontWeight.w600)),
        subtitle: ativo
            ? Text(aguardandoSinal ? 'Sinal de número: pontos 3, 4, 5 e 6' : 'Algarismo $numero: aguardando resposta',
                style: const TextStyle(color: cor, fontSize: 12))
            : null,
        trailing: Semantics(
          button: true,
          label: acao,
          hint: ativo ? 'Cancela a representação e abaixa os pontos' : 'Inicia o sinal de número e depois o algarismo',
          child: IconButton(
            tooltip: acao,
            onPressed: (enviando || processando) ? null : () => selecionar(numero),
            iconSize: 40,
            color: cor,
            icon: Icon(ativo ? Icons.stop_circle_outlined : Icons.play_circle_outline),
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
                onPressed: voltar,
                icon: const Icon(Icons.arrow_back_ios_new, color: cor),
              ),
              const Expanded(child: Text('Números', textAlign: TextAlign.center,
                  style: TextStyle(color: cor, fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerLeft,
              child: Text('Selecione um número para representar em Braille', style: TextStyle(color: cor, fontSize: 14))),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD8DCEF)),
                ),
                child: Text(mensagem, style: const TextStyle(color: cor, fontSize: 14)),
              ),
            ),
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
