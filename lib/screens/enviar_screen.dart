import 'package:flutter/material.dart';

class TelaEnviar extends StatefulWidget {
  const TelaEnviar({super.key});

  @override
  State<TelaEnviar> createState() => _TelaEnviarState();
}

class _TelaEnviarState extends State<TelaEnviar> {
  final List<String> filaPalavras = [
    "Morango",
    "A casa 213 é bonita",
    "12",
  ];

  String ultimaPalavra = "Cores";

  String get palavraAtual =>
      filaPalavras.isNotEmpty ? filaPalavras.first : "Nenhuma";

  void removerPalavra(int index) {
    setState(() {
      filaPalavras.removeAt(index);
    });
  }

  void enviarPalavra() {
    if (filaPalavras.isEmpty) return;

    setState(() {
      ultimaPalavra = filaPalavras.first;
      filaPalavras.removeAt(0);
    });

    // TODO:
    // Aqui você irá enviar a palavra para o ESP32 via Bluetooth.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xff0A2C73),
                    size: 34,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(width: 5),

                const Expanded(
                  child: Text(
                    "Enviar",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.bluetooth,
                    color: Color(0xff0A2C73),
                    size: 30,
                  ),
                  onPressed: () {
                    // abrir tela bluetooth
                  },
                ),

                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          "Palavra atual:",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Última palavra:",
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            ultimaPalavra,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  color: const Color(0xff3E4F9D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Text(
                    palavraAtual,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 42,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    right: 14,
                    top: 10,
                    bottom: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          // reproduzir palavra
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Play"),
                      ),

                      const SizedBox(width: 12),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0A2C73),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: enviarPalavra,
                        icon: const Icon(Icons.send),
                        label: const Text("Enviar"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Fila de palavras:",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ReorderableListView.builder(
              itemCount: filaPalavras.length,

              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex--;
                  }

                  final item = filaPalavras.removeAt(oldIndex);
                  filaPalavras.insert(newIndex, item);
                });
              },

              itemBuilder: (context, index) {
                return ListTile(
                  key: ValueKey(filaPalavras[index]),

                  title: Text(
                    filaPalavras[index],
                    style: const TextStyle(
                      fontSize: 22,
                    ),
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 28,
                        ),
                        onPressed: () {
                          removerPalavra(index);
                        },
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_outline,
                          size: 30,
                        ),
                        onPressed: () {
                          // reproduzir somente esta palavra
                        },
                      ),

                      const Icon(
                        Icons.drag_handle,
                        color: Color(0xff0A2C73),
                        size: 30,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}