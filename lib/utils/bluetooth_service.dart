import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  BluetoothService._();

  static final BluetoothService instance = BluetoothService._();

  BluetoothDevice? dispositivo;

  BluetoothCharacteristic? caracteristicaControle;

  // ============================================================
  // UUID DO ESP32
  // ============================================================

  static const String serviceUuid =
      "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  static const String characteristicUuid =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // ============================================================
  // CONFIGURAR DISPOSITIVO
  // ============================================================

  Future<void> configurar(BluetoothDevice device) async {
    dispositivo = device;

    final services = await device.discoverServices();

    caracteristicaControle = null;

    for (final service in services) {
      if (service.uuid.toString().toLowerCase() !=
          serviceUuid.toLowerCase()) {
        continue;
      }

      for (final characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() ==
            characteristicUuid.toLowerCase()) {
          caracteristicaControle = characteristic;

          print("=================================");
          print("CHARACTERISTIC DO DEDOLE ENCONTRADA");
          print(characteristic.uuid);
          print("=================================");

          return;
        }
      }
    }

    throw Exception(
      "Characteristic de controle não encontrada.",
    );
  }

  // ============================================================
  // ENVIAR COMANDO
  // ============================================================

  Future<void> enviarComando(String comando) async {
    if (caracteristicaControle == null) {
      throw Exception(
        "O Dedolê não está conectado.",
      );
    }

    await caracteristicaControle!.write(
      comando.codeUnits,
      withoutResponse: false,
    );

    print("Comando enviado para o Dedolê: $comando");
  }

  // ============================================================
  // VERIFICAR CONEXÃO
  // ============================================================

  bool get conectado {
    return dispositivo != null &&
        caracteristicaControle != null;
  }

  // ============================================================
  // LIMPAR
  // ============================================================

  void limpar() {
    dispositivo = null;
    caracteristicaControle = null;
  }
}