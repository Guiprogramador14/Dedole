import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/bluetooth_service.dart' as dedole;

// ============================================================
// UUID DO SERVIÇO E DA CHARACTERISTIC DO DEDOLÊ
// ============================================================

const String serviceUuid =
    "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

const String controleCharacteristicUuid =
    "beb5483e-36e1-4688-b7f5-ea07361b26a8";

// ============================================================
// TELA
// ============================================================

class TelaBluetooth extends StatefulWidget {
  const TelaBluetooth({super.key});

  @override
  State<TelaBluetooth> createState() => _TelaBluetoothState();
}

class _TelaBluetoothState extends State<TelaBluetooth> {
  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  static const String nomeEsp32 = "DEDOLE_ESP32";

  // ============================================================
  // VARIÁVEIS
  // ============================================================

  BluetoothDevice? dispositivoConectado;

  BluetoothCharacteristic? caracteristicaControle;

  bool procurando = false;
  bool conectando = false;

  List<ScanResult> dispositivos = [];

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothConnectionState>?
      connectionSubscription;

  // ============================================================
  // CICLO DE VIDA
  // ============================================================

  @override
  void initState() {
    super.initState();
    iniciarBluetooth();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // PERMISSÕES
  // ============================================================

  Future<bool> pedirPermissoes() async {
    final scan =
        await Permission.bluetoothScan.request();

    final connect =
        await Permission.bluetoothConnect.request();

    final location =
        await Permission.locationWhenInUse.request();

    debugPrint("Bluetooth Scan: $scan");
    debugPrint("Bluetooth Connect: $connect");
    debugPrint("Localização: $location");

    return scan.isGranted &&
        connect.isGranted;
  }

  // ============================================================
  // INICIALIZAR BLUETOOTH
  // ============================================================

  Future<void> iniciarBluetooth() async {
    final permitido = await pedirPermissoes();

    if (!permitido) {
      mostrarMensagem(
        "Permissões do Bluetooth negadas.",
      );
      return;
    }

    final estado =
        await FlutterBluePlus.adapterState.first;

    debugPrint(
      "Estado do Bluetooth: $estado",
    );

    if (estado != BluetoothAdapterState.on) {
      mostrarMensagem(
        "Ligue o Bluetooth do celular.",
      );
      return;
    }

    procurarDispositivos();
  }

  // ============================================================
  // PROCURAR DISPOSITIVOS
  // ============================================================

  Future<void> procurarDispositivos() async {
    if (conectando) return;

    if (mounted) {
      setState(() {
        procurando = true;
        dispositivos.clear();
      });
    }

    try {
      await FlutterBluePlus.stopScan();

      await scanSubscription?.cancel();

      // ========================================================
      // ESCUTA DOS RESULTADOS
      // ========================================================

      scanSubscription =
          FlutterBluePlus.scanResults.listen(
        (resultados) {
          if (!mounted) return;

          for (final resultado in resultados) {
            final nomePlatform =
                resultado.device.platformName.trim();

            final nomeAnunciado =
                resultado.advertisementData.advName.trim();

            debugPrint(
              "BLE ENCONTRADO:"
              " nome=$nomePlatform"
              " | advName=$nomeAnunciado"
              " | id=${resultado.device.remoteId}",
            );
          }

          // ====================================================
          // FILTRA O DEDOLÊ
          // ====================================================

          final encontrados =
              resultados.where((resultado) {
            final nomePlatform =
                resultado.device.platformName.trim();

            final nomeAnunciado =
                resultado.advertisementData.advName.trim();

            final encontrouPorNome =
                nomePlatform == nomeEsp32 ||
                nomeAnunciado == nomeEsp32;

            // Também verifica o UUID do serviço.
            final possuiServico =
                resultado.advertisementData.serviceUuids
                    .any(
              (uuid) =>
                  uuid.toString().toLowerCase() ==
                  serviceUuid.toLowerCase(),
            );

            return encontrouPorNome ||
                possuiServico;
          }).toList();

          setState(() {
            dispositivos = encontrados;
          });
        },
        onError: (erro) {
          debugPrint(
            "Erro no scan BLE: $erro",
          );
        },
      );

      // ========================================================
      // INICIAR SCAN
      // ========================================================

      debugPrint(
        "================================",
      );
      debugPrint(
        "INICIANDO SCAN BLE",
      );
      debugPrint(
        "Procurando: $nomeEsp32",
      );
      debugPrint(
        "================================",
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        procurando = false;
      });

      debugPrint(
        "SCAN FINALIZADO",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        procurando = false;
      });

      debugPrint(
        "ERRO AO PROCURAR: $e",
      );

      mostrarMensagem(
        "Erro ao procurar dispositivos.",
      );
    }
  }

  // ============================================================
  // CONECTAR AO ESP32
  // ============================================================

  Future<void> conectar(
    BluetoothDevice dispositivo,
  ) async {
    if (conectando) return;

    setState(() {
      conectando = true;
    });

    try {
      await FlutterBluePlus.stopScan();

      debugPrint(
        "================================",
      );
      debugPrint(
        "CONECTANDO AO DEDOLÊ",
      );
      debugPrint(
        "Nome: ${dispositivo.platformName}",
      );
      debugPrint(
        "ID: ${dispositivo.remoteId}",
      );
      debugPrint(
        "================================",
      );

      // ========================================================
      // CONECTAR
      // ========================================================

      await dispositivo.connect(
        timeout: const Duration(seconds: 10),
      );

      debugPrint(
        "ESP32 conectado!",
      );

      // ========================================================
      // MONITORAR CONEXÃO
      // ========================================================

      await connectionSubscription?.cancel();

      connectionSubscription =
          dispositivo.connectionState.listen(
        (estado) {
          debugPrint(
            "Estado da conexão: $estado",
          );

          if (estado ==
              BluetoothConnectionState
                  .disconnected) {
            if (mounted) {
              setState(() {
                dispositivoConectado = null;
                caracteristicaControle = null;
              });
            }
          }
        },
      );

      // ========================================================
      // DESCOBRIR SERVIÇOS
      // ========================================================

      final services =
          await dispositivo.discoverServices();

      debugPrint(
        "================================",
      );
      debugPrint(
        "SERVIÇOS ENCONTRADOS",
      );
      debugPrint(
        "================================",
      );

      BluetoothCharacteristic?
          controleEncontrado;

      for (final service in services) {
        debugPrint(
          "Serviço: ${service.uuid}",
        );

        for (final characteristic
            in service.characteristics) {
          debugPrint(
            "  Characteristic: "
            "${characteristic.uuid}",
          );

          // ==================================================
          // ENCONTRA A CHARACTERISTIC DOS COMANDOS
          // ==================================================

          if (characteristic.uuid
                  .toString()
                  .toLowerCase() ==
              controleCharacteristicUuid
                  .toLowerCase()) {
            controleEncontrado =
                characteristic;

            debugPrint(
              ">>> CHARACTERISTIC DO DEDOLÊ ENCONTRADA!",
            );
          }
        }
      }

      // ========================================================
      // VERIFICAR SE ENCONTROU
      // ========================================================

      if (controleEncontrado == null) {
        debugPrint(
          "ERRO: Characteristic do Dedolê não encontrada.",
        );

        await dispositivo.disconnect();

        if (!mounted) return;

        setState(() {
          conectando = false;
          dispositivoConectado = null;
        });

        mostrarMensagem(
          "Serviço de controle do Dedolê não encontrado.",
        );

        return;
      }

      // ========================================================
      // SALVAR CHARACTERISTIC
      // ========================================================

      caracteristicaControle =
          controleEncontrado;

      // ========================================================
      // CONFIGURAR BLUETOOTH SERVICE
      // ========================================================

      await dedole.BluetoothService.instance
          .configurar(dispositivo);

      debugPrint(
        ">>> BLUETOOTH SERVICE CONFIGURADO!",
      );

      // ========================================================
      // SALVAR DISPOSITIVO
      // ========================================================

      if (!mounted) return;

      setState(() {
        dispositivoConectado =
            dispositivo;

        conectando = false;
      });

      mostrarMensagem(
        "ESP32 conectado com sucesso!",
      );
    } catch (e) {
      debugPrint(
        "================================",
      );
      debugPrint(
        "ERRO AO CONECTAR",
      );
      debugPrint(
        "$e",
      );
      debugPrint(
        "================================",
      );

      if (!mounted) return;

      setState(() {
        conectando = false;
        dispositivoConectado = null;
        caracteristicaControle = null;
      });

      mostrarMensagem(
        "Não foi possível conectar ao ESP32.",
      );
    }
  }

  // ============================================================
  // DESCONECTAR
  // ============================================================

  Future<void> desconectar() async {
    if (dispositivoConectado == null) {
      return;
    }

    try {
      await dispositivoConectado!.disconnect();

      await connectionSubscription?.cancel();

      caracteristicaControle = null;

      if (!mounted) return;

      setState(() {
        dispositivoConectado = null;
      });

      mostrarMensagem(
        "ESP32 desconectado.",
      );
    } catch (e) {
      debugPrint(
        "Erro ao desconectar: $e",
      );
    }
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mostrarMensagem(
    String mensagem,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Conectar ESP32",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip:
                "Procurar novamente",
            onPressed:
                procurando || conectando
                    ? null
                    : procurarDispositivos,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStatusCard(),

              const SizedBox(
                height: 25,
              ),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  "ESP32 disponível",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Expanded(
                child:
                    _buildConteudo(),
              ),

              const SizedBox(
                height: 15,
              ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      procurando ||
                              conectando
                          ? null
                          : procurarDispositivos,
                  icon: procurando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .bluetooth_searching,
                        ),
                  label: Text(
                    procurando
                        ? "Procurando..."
                        : "Procurar ESP32",
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DE STATUS
  // ============================================================

  Widget _buildStatusCard() {
    final conectado =
        dispositivoConectado != null;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: conectado
            ? Colors.green
                .withOpacity(0.12)
            : Colors.blue
                .withOpacity(0.10),
        border: Border.all(
          color: conectado
              ? Colors.green
                  .withOpacity(0.35)
              : Colors.blue
                  .withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(
              shape: BoxShape.circle,
              color: conectado
                  ? Colors.green
                      .withOpacity(0.18)
                  : Colors.blue
                      .withOpacity(0.15),
            ),
            child: Icon(
              conectado
                  ? Icons
                      .bluetooth_connected
                  : Icons.bluetooth,
              color: conectado
                  ? Colors.green
                  : Colors.blue,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  conectado
                      ? "ESP32 conectado"
                      : "Bluetooth",
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  conectado
                      ? (dispositivoConectado!
                              .platformName
                              .isEmpty
                          ? nomeEsp32
                          : dispositivoConectado!
                              .platformName)
                      : procurando
                          ? "Procurando o seu ESP32..."
                          : "Pronto para conectar",
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          if (conectado)
            IconButton(
              tooltip: "Desconectar",
              onPressed:
                  desconectar,
              icon: const Icon(
                Icons.link_off,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _buildConteudo() {
    // ==========================================================
    // CONECTANDO
    // ==========================================================

    if (conectando) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 45,
              height: 45,
              child:
                  CircularProgressIndicator(),
            ),

            SizedBox(
              height: 20,
            ),

            Text(
              "Conectando ao ESP32...",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // PROCURANDO
    // ==========================================================

    if (procurando) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 65,
              color: Colors.blue,
            ),

            SizedBox(
              height: 15,
            ),

            Text(
              "Procurando seu ESP32...",
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w500,
              ),
            ),

            SizedBox(
              height: 5,
            ),

            Text(
              "Isso pode levar alguns segundos.",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // NENHUM DISPOSITIVO
    // ==========================================================

    if (dispositivos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 70,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              "Nenhum ESP32 encontrado",
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              "Verifique se o ESP32 está ligado\n"
              "e com o Bluetooth ativo.",
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // LISTA
    // ==========================================================

    return ListView.builder(
      itemCount:
          dispositivos.length,

      itemBuilder:
          (context, index) {
        final resultado =
            dispositivos[index];

        final dispositivo =
            resultado.device;

        final nome =
            dispositivo
                    .platformName
                    .isNotEmpty
                ? dispositivo
                    .platformName
                : resultado
                    .advertisementData
                    .advName
                    .isNotEmpty
                    ? resultado
                        .advertisementData
                        .advName
                    : "DEDOLE_ESP32";

        return Container(
          margin:
              const EdgeInsets.only(
            bottom: 12,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: Colors.grey
                  .withOpacity(0.2),
            ),
          ),

          child: ListTile(
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            leading: Container(
              width: 48,
              height: 48,
              decoration:
                  BoxDecoration(
                color: Colors.blue
                    .withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Icon(
                Icons.developer_board,
                color: Colors.blue,
              ),
            ),

            title: Text(
              nome,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            subtitle: Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),
              child: Text(
                dispositivo
                    .remoteId
                    .toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors
                      .grey.shade600,
                ),
              ),
            ),

            trailing:
                const Icon(
              Icons
                  .arrow_forward_ios,
              size: 18,
            ),

            onTap: () {
              conectar(
                dispositivo,
              );
            },
          ),
        );
      },
    );
  }
}