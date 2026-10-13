import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  BluetoothService._();

  static final BluetoothService instance = BluetoothService._();

  static const String serviceUuid =
      '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String characteristicUuid =
      'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  BluetoothDevice? dispositivo;
  BluetoothCharacteristic? caracteristicaControle;
  StreamSubscription<BluetoothConnectionState>? _conexaoSubscription;
  final ValueNotifier<bool> estadoConexao = ValueNotifier(false);

  bool get conectado => estadoConexao.value &&
      dispositivo != null && caracteristicaControle != null;

  Future<void> configurar(BluetoothDevice device) async {
    if (conectado && dispositivo?.remoteId == device.remoteId) return;

    await desconectar();
    try {
      if (!device.isConnected) {
        await device.connect(timeout: const Duration(seconds: 12));
      }

      final services = await device.discoverServices();
      BluetoothCharacteristic? controle;

      for (final service in services) {
        if (service.uuid.toString().toLowerCase() != serviceUuid) continue;
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              characteristicUuid) {
            controle = characteristic;
            break;
          }
        }
      }

      if (controle == null) {
        throw StateError('Characteristic de controle do Dedolê não encontrada.');
      }
      if (!controle.properties.write && !controle.properties.writeWithoutResponse) {
        throw StateError('Characteristic do Dedolê não aceita escrita.');
      }

      dispositivo = device;
      caracteristicaControle = controle;
      estadoConexao.value = true;

      _conexaoSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            dispositivo?.remoteId == device.remoteId) {
          limpar();
        }
      });
    } catch (_) {
      limpar();
      try { await device.disconnect(); } catch (_) {}
      rethrow;
    }
  }

  Future<void> enviarComando(String comando) async {
    if (!conectado) throw StateError('O Dedolê não está conectado.');
    final characteristic = caracteristicaControle!;
    await characteristic.write(
      utf8.encode(comando),
      withoutResponse: !characteristic.properties.write &&
          characteristic.properties.writeWithoutResponse,
    );
    debugPrint('Comando enviado ao Dedolê: $comando');
  }

  Future<void> desconectar() async {
    final device = dispositivo;
    limpar();
    if (device != null) {
      try { await device.disconnect(); } catch (_) {}
    }
  }

  void limpar() {
    _conexaoSubscription?.cancel();
    _conexaoSubscription = null;
    dispositivo = null;
    caracteristicaControle = null;
    estadoConexao.value = false;
  }
}
