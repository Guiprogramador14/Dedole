import 'dart:async';

import 'package:flutter/semantics.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;

import '../utils/bluetooth_service.dart';



class TelaCores extends StatefulWidget {

  const TelaCores({super.key});



  @override

  State<TelaCores> createState() => _TelaCoresState();

}



class _TelaCoresState extends State<TelaCores> {

  static const Color corTexto = Color(0xFF1B2161);

  static const Color fundo = Color(0xFFF6F7FF);

  static const String respostaUuid =

      'beb5483e-36e1-4688-b7f5-ea07361b26aa';



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



  BluetoothCharacteristic? resposta;

  StreamSubscription<List<int>>? assinatura;

  StreamSubscription<BluetoothConnectionState>? conexao;



  String? corAtiva;

  int indiceLetra = 0;

  bool enviando = false;

  bool processandoAcerto = false;

  String mensagem = 'Selecione uma cor para começar.';

  int versaoOperacao = 0;



  @override

  void initState() {

    super.initState();

    iniciarNotificacoes();

  }



  String get letraAtual {

    final palavra = corAtiva;

    if (palavra == null || indiceLetra >= palavra.length) return '';

    return palavra[indiceLetra];

  }



void falar(String texto) {

  if (!mounted) return;



  setState(() => mensagem = texto);



  SemanticsService.sendAnnouncement(

    View.of(context),

    texto,

    TextDirection.ltr,

  );

}



  void aviso(String texto) {

    if (!mounted) return;

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

        if (estado == BluetoothConnectionState.disconnected && mounted) {

          versaoOperacao++;

          setState(() {

            corAtiva = null;

            indiceLetra = 0;

            enviando = false;

            processandoAcerto = false;

          });

          aviso('Dedolê desconectado. Conecte a máquina para continuar.');

        }

      });



      final servicos = await device.discoverServices();

      if (!mounted) return;

      for (final servico in servicos) {

        if (servico.uuid.toString().toLowerCase() !=

            BluetoothService.serviceUuid.toLowerCase()) {

          continue;

        }

        for (final caracteristica in servico.characteristics) {

          if (caracteristica.uuid.toString().toLowerCase() == respostaUuid) {

            resposta = caracteristica;

            assinatura = caracteristica.onValueReceived.listen((bytes) {

              final msg = String.fromCharCodes(bytes).trim().toUpperCase();

              if (msg.startsWith('ACERTOU:')) {

                final letra = msg.substring('ACERTOU:'.length).trim();

                if (letra == letraAtual && !processandoAcerto && !enviando) {

                  processarAcerto();

                }

              }

            });

            await caracteristica.setNotifyValue(true);

            return;

          }

        }

      }

      aviso('O Dedolê não disponibilizou a confirmação dos botões físicos.');

    } catch (e) {

      aviso('Não foi possível ativar as respostas do Dedolê: $e');

    }

  }



  Future<void> selecionarCor(String nome) async {

    if (enviando || processandoAcerto) return;

    if (!BluetoothService.instance.conectado) {

      aviso('Dedolê não conectado. Conecte a máquina pelo Bluetooth primeiro.');

      return;

    }



    final operacao = ++versaoOperacao;

    final cancelando = corAtiva == nome;

    setState(() => enviando = true);

    try {

      if (cancelando) {

        await BluetoothService.instance.enviarComando('RESET');

        if (!mounted || operacao != versaoOperacao) return;

        setState(() {

          corAtiva = null;

          indiceLetra = 0;

        });

        falar('Cor ${nome.toLowerCase()} cancelada. Pontos retornaram à posição inicial.');

      } else {

        // O firmware do ESP32 faz RESET antes de representar cada letra.

        await BluetoothService.instance.enviarComando(nome[0]);

        if (!mounted || operacao != versaoOperacao) return;

        setState(() {

          corAtiva = nome;

          indiceLetra = 0;

        });

        falar('Cor ${nome.toLowerCase()}. Letra ${nome[0]} enviada para a máquina. Pressione os botões físicos correspondentes.');

      }

    } catch (e) {

      aviso('Erro ao comunicar com o Dedolê: $e');

    } finally {

      if (mounted && operacao == versaoOperacao) {

        setState(() => enviando = false);

      }

    }

  }



  Future<void> processarAcerto() async {

    final palavra = corAtiva;

    if (palavra == null || processandoAcerto) return;

    final operacao = versaoOperacao;

    final letraConcluida = letraAtual;

    processandoAcerto = true;



    try {

      final proximoIndice = indiceLetra + 1;

      if (proximoIndice >= palavra.length) {

        if (!mounted || operacao != versaoOperacao) return;

        setState(() {

          corAtiva = null;

          indiceLetra = 0;

        });

        falar('Correto! Letra $letraConcluida concluída. Você completou a cor ${palavra.toLowerCase()}!');

        return;

      }



      final proximaLetra = palavra[proximoIndice];

      if (!mounted || operacao != versaoOperacao) return;

      setState(() => enviando = true);

      // O ESP32 retorna à posição inicial e representa a próxima letra.

      await BluetoothService.instance.enviarComando(proximaLetra);

      if (!mounted || operacao != versaoOperacao) return;

      setState(() => indiceLetra = proximoIndice);

      falar('Correto! Letra $letraConcluida concluída. Próxima letra: $proximaLetra, enviada para a máquina.');

    } catch (e) {

      aviso('Erro ao avançar para a próxima letra: $e. Use Parar para reiniciar.');

    } finally {

      processandoAcerto = false;

      if (mounted && operacao == versaoOperacao) {

        setState(() => enviando = false);

      }

    }

  }



  Future<void> voltar() async {

    if (enviando || processandoAcerto) return;

    if (corAtiva != null && BluetoothService.instance.conectado) {

      try {

        await BluetoothService.instance.enviarComando('RESET');

      } catch (_) {

        // Mesmo sem comunicação, permite sair da tela.

      }

    }

    if (mounted) Navigator.maybePop(context);

  }



  @override

  void dispose() {

    versaoOperacao++;

    assinatura?.cancel();

    conexao?.cancel();

    super.dispose();

  }



  Widget criarCor(({String nome, Color cor}) item) {

    final ativa = corAtiva == item.nome;

    final bloqueado = enviando || processandoAcerto;

    final acao = ativa ? 'Parar cor ${item.nome}' : 'Representar cor ${item.nome}';



    return Column(

      children: [

        ListTile(

          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),

          leading: ExcludeSemantics(

            child: Container(

              width: 30,

              height: 30,

              decoration: BoxDecoration(

                color: item.cor,

                shape: BoxShape.circle,

                border: Border.all(color: corTexto.withValues(alpha: 0.4)),

              ),

            ),

          ),

          title: Text(item.nome,

              style: const TextStyle(

                  color: corTexto, fontSize: 20, fontWeight: FontWeight.w600)),

          subtitle: ativa

              ? Text('Letra ${letraAtual} (${indiceLetra + 1} de ${item.nome.length})',

                  style: const TextStyle(color: corTexto, fontSize: 13))

              : null,

          trailing: Semantics(

            button: true,

            label: acao,

            hint: ativa

                ? 'Cancela a cor e abaixa os pontos Braille'

                : 'Inicia a representação letra por letra no Dedolê',

            child: IconButton(

              tooltip: acao,

              onPressed: bloqueado ? null : () => selecionarCor(item.nome),

              iconSize: 40,

              color: corTexto,

              icon: Icon(ativa

                  ? Icons.stop_circle_outlined

                  : Icons.play_circle_outline),

            ),

          ),

        ),

        const Divider(height: 1, color: Color(0xFFD8DCEF)),

      ],

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: fundo,

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

          child: Column(

            children: [

              Row(

                children: [

                  IconButton(

                    padding: EdgeInsets.zero,

                    tooltip: 'Voltar',

                    onPressed: voltar,

                    icon: const Icon(Icons.arrow_back_ios_new, color: corTexto),

                  ),

                  const Expanded(

                    child: Text('Cores',

                        textAlign: TextAlign.center,

                        style: TextStyle(

                            color: corTexto,

                            fontSize: 18,

                            fontWeight: FontWeight.bold)),

                  ),

                  const SizedBox(width: 48),

                ],

              ),

              const SizedBox(height: 24),

              const Align(

                alignment: Alignment.centerLeft,

                child: Text('Selecione uma cor para representar em Braille',

                    style: TextStyle(color: corTexto, fontSize: 14)),

              ),

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

                  child: Text(mensagem,

                      style: const TextStyle(color: corTexto, fontSize: 14)),

                ),

              ),

              const SizedBox(height: 12),

              Expanded(

                child: ListView.builder(

                  itemCount: cores.length,

                  itemBuilder: (context, i) => criarCor(cores[i]),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}
