import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class TelaBluetooth extends StatefulWidget {
  const TelaBluetooth({super.key});

  @override
  State<TelaBluetooth> createState() => _TelaBluetoothState();
}

class _TelaBluetoothState extends State<TelaBluetooth> {
  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  // Nome que o ESP32 deve anunciar via Bluetooth.
  // Se o nome do seu ESP32 for diferente, altere aqui.
  static const String nomeEsp32 = "DEDOLE_ESP32";

  // ============================================================
  // VARIÁVEIS
  // ============================================================

  BluetoothDevice? dispositivoConectado;

  bool procurando = false;
  bool conectando = false;

  List<ScanResult> dispositivos = [];

  StreamSubscription<List<ScanResult>>? scanSubscription;

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
    super.dispose();
  }

  // ============================================================
  // PERMISSÕES
  // ============================================================

  Future<bool> pedirPermissoes() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();

    // Mantido para compatibilidade com versões/configurações
    // do Android que ainda exigem localização para Bluetooth.
    final location = await Permission.locationWhenInUse.request();

    if (scan.isGranted &&
        connect.isGranted &&
        (location.isGranted || !location.isDenied)) {
      return true;
    }

    return false;
  }

  // ============================================================
  // INICIALIZAÇÃO DO BLUETOOTH
  // ============================================================

  Future<void> iniciarBluetooth() async {
    final permitido = await pedirPermissoes();

    if (!permitido) {
      mostrarMensagem("Permissão do Bluetooth negada.");
      return;
    }

    final estado = await FlutterBluePlus.adapterState.first;

    if (estado != BluetoothAdapterState.on) {
      mostrarMensagem("Ligue o Bluetooth do celular.");
      return;
    }

    procurarDispositivos();
  }

  // ============================================================
  // PROCURAR ESP32
  // ============================================================

  Future<void> procurarDispositivos() async {
    if (conectando) return;

    setState(() {
      procurando = true;
      dispositivos.clear();
    });

    try {
      // Para uma busca anterior, caso exista.
      await FlutterBluePlus.stopScan();

      // Cancela o listener anterior para evitar
      // vários listeners acumulados.
      await scanSubscription?.cancel();

      scanSubscription = FlutterBluePlus.scanResults.listen((resultados) {
        if (!mounted) return;

        // FILTRO DO ESP32
        final encontrados = resultados.where((resultado) {
          final nome = resultado.device.platformName.trim();

          return nome == nomeEsp32;
        }).toList();

        setState(() {
          dispositivos = encontrados;
        });
      });

      // Começa a procurar dispositivos Bluetooth.
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );

      if (!mounted) return;

      setState(() {
        procurando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        procurando = false;
      });

      mostrarMensagem("Erro ao procurar dispositivos.");
      debugPrint("Erro no Bluetooth: $e");
    }
  }

  // ============================================================
  // CONECTAR AO ESP32
  // ============================================================

  Future<void> conectar(BluetoothDevice dispositivo) async {
    if (conectando) return;

    setState(() {
      conectando = true;
    });

    try {
      // Para a procura antes de conectar.
      await FlutterBluePlus.stopScan();

      debugPrint("Conectando ao ESP32...");
      debugPrint("Nome: ${dispositivo.platformName}");
      debugPrint("ID: ${dispositivo.remoteId}");

      await dispositivo.connect(
        timeout: const Duration(seconds: 10),
      );

      debugPrint("ESP32 conectado!");

      // Descobre os serviços Bluetooth disponíveis.
      final services = await dispositivo.discoverServices();

      debugPrint("Serviços encontrados:");

      for (final service in services) {
        debugPrint("Serviço: ${service.uuid}");

        for (final characteristic in service.characteristics) {
          debugPrint("  Característica: ${characteristic.uuid}");
        }
      }

      if (!mounted) return;

      setState(() {
        dispositivoConectado = dispositivo;
        conectando = false;
      });

      mostrarMensagem("ESP32 conectado com sucesso!");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        conectando = false;
        dispositivoConectado = null;
      });

      debugPrint("Erro ao conectar: $e");

      mostrarMensagem("Não foi possível conectar ao ESP32.");
    }
  }

  // ============================================================
  // DESCONECTAR
  // ============================================================

  Future<void> desconectar() async {
    if (dispositivoConectado == null) return;

    try {
      await dispositivoConectado!.disconnect();

      if (!mounted) return;

      setState(() {
        dispositivoConectado = null;
      });

      mostrarMensagem("ESP32 desconectado.");
    } catch (e) {
      debugPrint("Erro ao desconectar: $e");
    }
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // TELA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Conectar ESP32",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        // Botão atualizar
        actions: [
          IconButton(
            tooltip: "Procurar novamente",
            onPressed: procurando || conectando
                ? null
                : procurarDispositivos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ==================================================
              // CARD DE STATUS
              // ==================================================

              _buildStatusCard(),

              const SizedBox(height: 25),

              // ==================================================
              // TÍTULO
              // ==================================================

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ESP32 disponível",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // CONTEÚDO
              // ==================================================

              Expanded(
                child: _buildConteudo(),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // BOTÃO PROCURAR
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: procurando || conectando
                      ? null
                      : procurarDispositivos,
                  icon: procurando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(
                    procurando
                        ? "Procurando..."
                        : "Procurar ESP32",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
    final conectado = dispositivoConectado != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: conectado
            ? Colors.green.withOpacity(0.12)
            : Colors.blue.withOpacity(0.10),
        border: Border.all(
          color: conectado
              ? Colors.green.withOpacity(0.35)
              : Colors.blue.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: conectado
                  ? Colors.green.withOpacity(0.18)
                  : Colors.blue.withOpacity(0.15),
            ),
            child: Icon(
              conectado
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth,
              color: conectado
                  ? Colors.green
                  : Colors.blue,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conectado
                      ? "ESP32 conectado"
                      : "Bluetooth",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  conectado
                      ? dispositivoConectado!.platformName
                      : procurando
                          ? "Procurando o seu ESP32..."
                          : "Pronto para conectar",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          if (conectado)
            IconButton(
              tooltip: "Desconectar",
              onPressed: desconectar,
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
  // CONTEÚDO DA LISTA
  // ============================================================

  Widget _buildConteudo() {
    // Está conectando
    if (conectando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 45,
              height: 45,
              child: CircularProgressIndicator(),
            ),

            SizedBox(height: 20),

            Text(
              "Conectando ao ESP32...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Está procurando
    if (procurando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 65,
              color: Colors.blue,
            ),

            SizedBox(height: 15),

            Text(
              "Procurando seu ESP32...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 5),

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

    // Nenhum ESP32 encontrado
    if (dispositivos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 70,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              "Nenhum ESP32 encontrado",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              "Verifique se o ESP32 está ligado\ne com o Bluetooth ativo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Lista dos ESP32 encontrados
    return ListView.builder(
      itemCount: dispositivos.length,
      itemBuilder: (context, index) {
        final resultado = dispositivos[index];

        final dispositivo = resultado.device;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            // Ícone
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.developer_board,
                color: Colors.blue,
              ),
            ),

            // Nome
            title: Text(
              dispositivo.platformName.isEmpty
                  ? nomeEsp32
                  : dispositivo.platformName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            // ID
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                dispositivo.remoteId.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            // Botão
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),

            onTap: () {
              conectar(dispositivo);
            },
          ),
        );
      },
    );
  }
}