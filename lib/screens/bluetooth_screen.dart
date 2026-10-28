import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/bluetooth_service.dart' as dedole;

class TelaBluetooth extends StatefulWidget {
  const TelaBluetooth({super.key});

  @override
  State<TelaBluetooth> createState() => _TelaBluetoothState();
}

class _TelaBluetoothState extends State<TelaBluetooth> {
  static const Duration tempoExpiracao = Duration(seconds: 20);

  final dedole.BluetoothService bluetooth = dedole.BluetoothService.instance;
  final TextEditingController pesquisa = TextEditingController();
  final Map<String, ScanResult> encontrados = {};
  final Map<String, DateTime> vistosEm = {};
  final Map<String, String> apelidos = {};

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothAdapterState>? adapterSubscription;
  Timer? limpezaTimer;

  bool procurando = false;
  bool buscaAutomatica = true;
  bool rotinaAtiva = false;
  bool conectando = false;
  bool somenteDedole = true;
  bool bluetoothLigado = false;

  @override
  void initState() {
    super.initState();
    bluetooth.estadoConexao.addListener(atualizar);
    limpezaTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => limparAntigos(),
    );
    adapterSubscription = FlutterBluePlus.adapterState.listen((estado) {
      if (!mounted) return;
      final ligado = estado == BluetoothAdapterState.on;
      setState(() {
        bluetoothLigado = ligado;
        if (!ligado) {
          encontrados.clear();
          vistosEm.clear();
        }
      });
      if (!ligado) {
        suspenderBusca();
      } else if (buscaAutomatica && !bluetooth.conectado && !conectando) {
        iniciarBusca();
      }
    });
    iniciar();
  }

  void atualizar() {
    if (!mounted) return;
    setState(() {});
    // Quando a conexão é perdida, volta a procurar automaticamente.
    if (!bluetooth.conectado && !conectando && bluetoothLigado) {
      buscaAutomatica = true;
      iniciarBusca();
    }
  }

  void limparAntigos() {
    if (!mounted || vistosEm.isEmpty) return;
    final agora = DateTime.now();
    final expirados = vistosEm.entries
        .where((entrada) => agora.difference(entrada.value) > tempoExpiracao)
        .map((entrada) => entrada.key)
        .toList();
    if (expirados.isEmpty) return;
    setState(() {
      for (final id in expirados) {
        vistosEm.remove(id);
        encontrados.remove(id);
      }
    });
  }

  @override
  void dispose() {
    buscaAutomatica = false;
    limpezaTimer?.cancel();
    scanSubscription?.cancel();
    adapterSubscription?.cancel();
    bluetooth.estadoConexao.removeListener(atualizar);
    pesquisa.dispose();
    // Não desconecta o ESP32 ao sair desta tela.
    // Evita interromper buscas iniciadas por outras telas.
    if (rotinaAtiva) FlutterBluePlus.stopScan();
    super.dispose();
  }

  String identificador(BluetoothDevice device) => device.remoteId.toString();

  String nomeOriginal(ScanResult resultado) {
    final anuncio = resultado.advertisementData.advName.trim();
    if (anuncio.isNotEmpty) return anuncio;
    final nome = resultado.device.platformName.trim();
    return nome.isNotEmpty ? nome : 'Dispositivo sem nome';
  }

  String nomeExibido(ScanResult resultado) =>
      apelidos[identificador(resultado.device)] ?? nomeOriginal(resultado);

  bool ehDedole(ScanResult resultado) {
    final nomes = [
      resultado.device.platformName.toUpperCase(),
      resultado.advertisementData.advName.toUpperCase(),
    ];
    return nomes.any((nome) => nome.startsWith('DEDOLE_')) ||
        resultado.advertisementData.serviceUuids.any(
          (uuid) => uuid.toString().toLowerCase() ==
              dedole.BluetoothService.serviceUuid.toLowerCase(),
        );
  }

  List<ScanResult> get listaFiltrada {
    final termo = pesquisa.text.trim().toLowerCase();
    final idConectado = bluetooth.conectado && bluetooth.dispositivo != null
        ? identificador(bluetooth.dispositivo!)
        : null;
    final lista = encontrados.values.where((resultado) {
      // Um dispositivo conectado nunca aparece novamente na lista de busca.
      if (identificador(resultado.device) == idConectado) return false;
      if (somenteDedole && !ehDedole(resultado)) return false;
      return nomeExibido(resultado).toLowerCase().contains(termo) ||
          nomeOriginal(resultado).toLowerCase().contains(termo) ||
          identificador(resultado.device).toLowerCase().contains(termo);
    }).toList();
    lista.sort((a, b) => b.rssi.compareTo(a.rssi));
    return lista;
  }

  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    for (final chave in prefs.getKeys()) {
      if (chave.startsWith('dedole_nome_')) {
        final nome = prefs.getString(chave);
        if (nome != null) {
          apelidos[chave.substring('dedole_nome_'.length)] = nome;
        }
      }
    }
    if (!mounted) return;
    setState(() {});
    iniciarBusca();
  }

  Future<bool> pedirPermissoes() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    return scan.isGranted && connect.isGranted;
  }

  Future<void> ativarBluetooth() async {
    try {
      if (!await pedirPermissoes()) {
        mensagem('Autorize o acesso ao Bluetooth nas configurações.');
        return;
      }
      await FlutterBluePlus.turnOn();
      await FlutterBluePlus.adapterState
          .firstWhere((estado) => estado == BluetoothAdapterState.on)
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        buscaAutomatica = true;
        iniciarBusca();
      }
    } catch (_) {
      mensagem('Ative o Bluetooth nas configurações do celular.');
    }
  }

  Future<void> suspenderBusca() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    if (mounted) setState(() => procurando = false);
  }

  Future<void> pararBusca() async {
    buscaAutomatica = false;
    await suspenderBusca();
  }

  Future<void> iniciarBusca() async {
    if (rotinaAtiva || conectando || bluetooth.conectado || !buscaAutomatica) {
      return;
    }
    rotinaAtiva = true;
    try {
      if (!await pedirPermissoes()) {
        buscaAutomatica = false;
        mensagem('Permissões do Bluetooth não concedidas.');
        return;
      }
      final estado = await FlutterBluePlus.adapterState
          .firstWhere((e) => e != BluetoothAdapterState.unknown)
          .timeout(const Duration(seconds: 8));
      if (!mounted || estado != BluetoothAdapterState.on) return;

      await scanSubscription?.cancel();
      // onScanResults entrega resultados novos de cada busca. scanResults pode
      // devolver resultados antigos em cache e impedir a expiração correta.
      scanSubscription = FlutterBluePlus.onScanResults.listen((resultados) {
        if (!mounted || !buscaAutomatica || bluetooth.conectado) return;
        final agora = DateTime.now();
        setState(() {
          for (final resultado in resultados) {
            final id = identificador(resultado.device);
            encontrados[id] = resultado;
            vistosEm[id] = agora;
          }
        });
      });

      while (mounted && bluetoothLigado && buscaAutomatica &&
          !conectando && !bluetooth.conectado) {
        setState(() => procurando = true);
        try {
          await FlutterBluePlus.startScan(
            timeout: const Duration(seconds: 10),
          );
          await FlutterBluePlus.isScanning
              .where((ativo) => !ativo)
              .first
              .timeout(const Duration(seconds: 13));
        } catch (e) {
          if (mounted && buscaAutomatica) {
            mensagem('Falha na busca Bluetooth: $e');
          }
          await suspenderBusca();
        }
        if (mounted) setState(() => procurando = false);
        // A expiração continua funcionando durante a pausa entre buscas.
        for (var i = 0; i < 3; i++) {
          if (!mounted || !buscaAutomatica || conectando || bluetooth.conectado) {
            break;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    } catch (e) {
      if (mounted && buscaAutomatica) mensagem('Erro no Bluetooth: $e');
    } finally {
      rotinaAtiva = false;
      if (mounted) setState(() => procurando = false);
    }
  }

  Future<void> alternarBusca() async {
    if (buscaAutomatica) {
      await pararBusca();
    } else {
      while (rotinaAtiva && mounted) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (mounted) {
        buscaAutomatica = true;
        iniciarBusca();
      }
    }
  }

  Future<void> salvarApelido(BluetoothDevice device, String nomeAtual) async {
    final id = identificador(device);
    final controller = TextEditingController(text: apelidos[id] ?? nomeAtual);
    final novoNome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear máquina'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            labelText: 'Apelido no aplicativo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (novoNome == null || novoNome.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dedole_nome_$id', novoNome);
    if (!mounted) return;
    setState(() => apelidos[id] = novoNome);
    mensagem('Apelido salvo!');
  }

  Future<void> conectar(BluetoothDevice device) async {
    if (conectando || bluetooth.conectado) return;
    setState(() => conectando = true);
    buscaAutomatica = false;
    try {
      await FlutterBluePlus.stopScan();
      await bluetooth.configurar(device);
      if (!mounted) return;
      // Retira o dispositivo conectado da lista e de sua expiração.
      final id = identificador(device);
      setState(() {
        encontrados.remove(id);
        vistosEm.remove(id);
      });
      mensagem('Dedolê conectado com sucesso!');
    } catch (e) {
      mensagem('Não foi possível conectar: $e');
    } finally {
      if (mounted) {
        setState(() => conectando = false);
        if (!bluetooth.conectado && bluetoothLigado) {
          buscaAutomatica = true;
          // Aguarda o ciclo anterior encerrar antes de reiniciar.
          retomarBuscaQuandoPossivel();
        }
      }
    }
  }

  Future<void> retomarBuscaQuandoPossivel() async {
    while (mounted && rotinaAtiva) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted && buscaAutomatica && !bluetooth.conectado && bluetoothLigado) {
      iniciarBusca();
    }
  }

  Future<void> desconectar() async {
    try {
      await bluetooth.desconectar();
      if (!mounted) return;
      mensagem('Dedolê desconectado.');
      buscaAutomatica = true;
      retomarBuscaQuandoPossivel();
    } catch (e) {
      mensagem('Erro ao desconectar: $e');
    }
  }

  void mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    // Cores derivadas do tema global; acompanham claro, escuro e alto contraste.
    final tema = Theme.of(context);
    final azul = tema.colorScheme.primary;
    final fundo = tema.scaffoldBackgroundColor;
    final branco = tema.colorScheme.surface;
    final texto = tema.colorScheme.onSurface;

    final conectado = bluetooth.conectado && bluetooth.dispositivo != null;
    final lista = listaFiltrada;
    final dispositivoConectado = conectado ? bluetooth.dispositivo! : null;
    final nomeConectado = dispositivoConectado == null
        ? ''
        : (apelidos[identificador(dispositivoConectado)] ??
            (dispositivoConectado.platformName.isNotEmpty
                ? dispositivoConectado.platformName
                : 'Dedolê'));

    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Voltar',
                    icon: Icon(Icons.arrow_back_ios_new, color: azul),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Conectar Bluetooth',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: texto,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 28),
              Card(
                color: branco,
                child: ListTile(
                  leading: Icon(
                    conectado ? Icons.bluetooth_connected : Icons.bluetooth,
                    color: azul,
                  ),
                  title: Text(
                    conectado
                        ? 'Máquina conectada'
                        : bluetoothLigado
                            ? 'Bluetooth ativado'
                            : 'Bluetooth desligado',
                    style: TextStyle(color: texto, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    conectado ? nomeConectado : 'Selecione uma máquina para conectar',
                    style: TextStyle(color: texto),
                  ),
                  trailing: conectado
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Renomear máquina conectada',
                              icon: Icon(Icons.edit_outlined, color: azul),
                              onPressed: () => salvarApelido(
                                dispositivoConectado!,
                                nomeConectado,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Desconectar',
                              icon: const Icon(Icons.link_off, color: Colors.red),
                              onPressed: desconectar,
                            ),
                          ],
                        )
                      : !bluetoothLigado
                          ? TextButton(
                              onPressed: ativarBluetooth,
                              child: Text('Ativar', style: TextStyle(color: azul)),
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 14),
              if (conectado) ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'Dedolê conectado.\nUse os botões acima para renomear ou desconectar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: texto, fontSize: 16),
                    ),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: pesquisa,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: texto),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: branco,
                    prefixIcon: Icon(Icons.search, color: azul),
                    hintText: 'Pesquisar pelo nome ou identificador',
                    hintStyle: TextStyle(color: texto.withValues(alpha: 0.75)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: azul, width: 1.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: azul, width: 1.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Somente máquinas Dedolê',
                    style: TextStyle(color: texto, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Desative para ver outros dispositivos BLE',
                    style: TextStyle(color: texto),
                  ),
                  value: somenteDedole,
                  activeThumbColor: azul,
                  onChanged: (valor) => setState(() => somenteDedole = valor),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dispositivos encontrados',
                        style: TextStyle(
                          color: texto,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text('${lista.length}', style: TextStyle(color: texto)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: conectando
                      ? const Center(child: CircularProgressIndicator())
                      : lista.isEmpty
                          ? Center(
                              child: Text(
                                procurando
                                    ? 'Procurando dispositivos...'
                                    : 'Nenhum dispositivo encontrado.',
                                style: TextStyle(color: texto),
                              ),
                            )
                          : ListView.builder(
                              itemCount: lista.length,
                              itemBuilder: (context, index) {
                                final resultado = lista[index];
                                final device = resultado.device;
                                return Card(
                                  color: branco,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(Icons.developer_board, color: azul),
                                    title: Text(
                                      nomeExibido(resultado),
                                      style: TextStyle(
                                        color: texto,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${nomeOriginal(resultado)} · ${resultado.rssi} dBm',
                                      style: TextStyle(color: texto),
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Renomear',
                                      icon: Icon(Icons.edit_outlined, color: azul),
                                      onPressed: () => salvarApelido(
                                        device,
                                        nomeOriginal(resultado),
                                      ),
                                    ),
                                    onTap: conectando ? null : () => conectar(device),
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: branco,
                      foregroundColor: azul,
                      side: BorderSide(color: azul, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: conectando
                        ? null
                        : !bluetoothLigado
                            ? ativarBluetooth
                            : alternarBusca,
                    icon: Icon(
                      !bluetoothLigado
                          ? Icons.bluetooth
                          : buscaAutomatica
                              ? Icons.stop_circle_outlined
                              : Icons.bluetooth_searching,
                    ),
                    label: Text(
                      !bluetoothLigado
                          ? 'Ativar Bluetooth'
                          : buscaAutomatica
                              ? 'Parar busca automática'
                              : 'Iniciar busca automática',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
