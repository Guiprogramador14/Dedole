import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class TelaBluetooth extends StatefulWidget {
  const TelaBluetooth({super.key});

  @override
  State<TelaBluetooth> createState() => _TelaBluetoothState();
}

class _TelaBluetoothState extends State<TelaBluetooth> {
  //Variaveis
  BluetoothDevice? dispositivoConectado;
  bool conectando = false;

  Future<bool> pedirPermissoes() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();

    if (await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      return true;
    }

    return false;
  }

  List<ScanResult> dispositivos = [];

  @override
  void initState() {
    super.initState();

    iniciarBluetooth();
  }

  Future<void> iniciarBluetooth() async {
    bool permitido = await pedirPermissoes();

    if (!permitido) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Permissão negada")));

      return;
    }

    BluetoothAdapterState estado = await FlutterBluePlus.adapterState.first;

    if (estado != BluetoothAdapterState.on) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ligue o Bluetooth")));

      return;
    }

    procurarDispositivos();
  }

  void procurarDispositivos() async {
    setState(() {
      dispositivos.clear();
    });

    await FlutterBluePlus.stopScan();

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        dispositivos = results;
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conectar ESP32"),

        bottom: dispositivoConectado != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(25),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Conectado: ${dispositivoConectado!.platformName}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            : null,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (dispositivoConectado != null) {
                await dispositivoConectado!.disconnect();
              }

              setState(() {
                dispositivoConectado = null;
              });

              procurarDispositivos();
            },
          ),
        ],
      ),

      body: conectando
          ? const Center(child: CircularProgressIndicator())
          : dispositivos.isEmpty
          ? const Center(child: Text("Nenhum dispositivo encontrado"))
          : ListView.builder(
              itemCount: dispositivos.length,
              itemBuilder: (context, index) {
                final dispositivo = dispositivos[index].device;

                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(
                    dispositivo.platformName.isEmpty
                        ? "Dispositivo sem nome"
                        : dispositivo.platformName,
                  ),
                  subtitle: Text(dispositivo.remoteId.toString()),
                  onTap: () async {
                    setState(() {
                      conectando = true;
                    });

                    print("Você clicou em ${dispositivo.platformName}");

                    try {
                      print("Tentando conectar...");

                      await dispositivo.connect(
                        timeout: const Duration(seconds: 10),
                      );

                      List<BluetoothService> services = await dispositivo
                          .discoverServices();

                      print("Serviços encontrados:");

                      for (BluetoothService service in services) {
                        print(service.uuid);
                      }

                      setState(() {
                        dispositivoConectado = dispositivo;
                        conectando = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Conectado!")),
                      );
                    } catch (e) {
                      setState(() {
                        conectando = false;
                      });

                      print(e);

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                );
              },
            ),
    );
  }
}
