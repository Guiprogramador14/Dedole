import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class TelaBluetooth extends StatefulWidget {
  const TelaBluetooth({super.key});

  @override
  State<TelaBluetooth> createState() => _TelaBluetoothState();
}

class _TelaBluetoothState extends State<TelaBluetooth> {

  List<ScanResult> dispositivos = [];

  @override
  void initState() {
    super.initState();
    procurarDispositivos();
  }

  void procurarDispositivos() async {

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        dispositivos = results;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Conectar ESP32"),
      ),
      body: ListView.builder(
        itemCount: dispositivos.length,
        itemBuilder: (context, index) {

          final dispositivo = dispositivos[index].device;

          return ListTile(
            title: Text(
              dispositivo.platformName.isEmpty
                  ? "Dispositivo sem nome"
                  : dispositivo.platformName,
            ),
            subtitle: Text(dispositivo.remoteId.toString()),
            onTap: () async {

              await dispositivo.connect();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Conectado!"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}