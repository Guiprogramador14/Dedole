import 'package:flutter/material.dart';
import '../utils/bluetooth_service.dart';

class TelaAlfabeto extends StatefulWidget {
  const TelaAlfabeto({super.key});

  @override
  State<TelaAlfabeto> createState() => _TelaAlfabetoState();
}

class _TelaAlfabetoState extends State<TelaAlfabeto> {
  bool enviando = false;
  String? letraAtiva;

  Future<void> enviarLetra(String letra) async {
    if (enviando) return;

    setState(() {
      enviando = true;
    });

    try {
      await BluetoothService.instance.enviarComando(letra);

      if (!mounted) return;

      setState(() {
        letraAtiva = letra;
        enviando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Letra $letra enviada para o Dedolê.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        enviando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao enviar a letra $letra: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget criarLetra(String letra) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14),

          title: Text(
            "LETRA $letra",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),

          subtitle: letraAtiva == letra
              ? Text(
                  "Letra $letra apresentada no Dedolê",
                  style: const TextStyle(
                    color: Colors.green,
                  ),
                )
              : null,

          trailing: InkWell(
            borderRadius: BorderRadius.circular(30),

            onTap: enviando
                ? null
                : () => enviarLetra(letra),

            child: Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                border: Border.all(
                  color: letraAtiva == letra
                      ? Colors.green
                      : Colors.black,

                  width: 1.5,
                ),
              ),

              child: Icon(
                letraAtiva == letra
                    ? Icons.check
                    : Icons.play_arrow,

                size: 26,

                color: letraAtiva == letra
                    ? Colors.green
                    : Colors.black,
              ),
            ),
          ),
        ),

        const Divider(
          height: 1,
          color: Color(0xFFE5E5E5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),

        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),

              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),

                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF0A2C73),
                      size: 34,
                    ),
                  ),

                  const SizedBox(width: 5),

                  const Expanded(
                    child: Text(
                      "Alfabeto",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.bluetooth_connected,
                    color: Color(0xFF0A2C73),
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 18, 14, 10),

            child: Text(
              "Selecione uma letra para transcrever",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              children: [
                criarLetra("A"),
                criarLetra("B"),
                criarLetra("C"),
                criarLetra("D"),
                criarLetra("E"),
                criarLetra("F"),
                criarLetra("G"),
                criarLetra("H"),
                criarLetra("I"),
                criarLetra("J"),
                criarLetra("K"),
                criarLetra("L"),
                criarLetra("M"),
                criarLetra("N"),
                criarLetra("O"),
                criarLetra("P"),
                criarLetra("Q"),
                criarLetra("R"),
                criarLetra("S"),
                criarLetra("T"),
                criarLetra("U"),
                criarLetra("V"),
                criarLetra("W"),
                criarLetra("X"),
                criarLetra("Y"),
                criarLetra("Z"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
