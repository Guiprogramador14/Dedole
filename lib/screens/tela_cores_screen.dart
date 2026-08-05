import 'package:flutter/material.dart';

class TelaCores extends StatelessWidget {
  TelaCores({super.key});

  final List<Map<String, dynamic>> cores = [
    {"nome": "Todas as cores", "cor": Colors.black},
    {"nome": "VERMELHO", "cor": Colors.red},
    {"nome": "AZUL", "cor": Colors.blue},
    {"nome": "VERDE", "cor": Colors.green},
    {"nome": "AMARELO", "cor": Colors.yellow},
    {"nome": "LARANJA", "cor": Colors.orange},
    {"nome": "ROXO", "cor": Colors.purple},
    {"nome": "ROSA", "cor": Colors.pink},
    {"nome": "MARROM", "cor": Colors.brown},
    {"nome": "PRETO", "cor": Colors.black},
    {"nome": "BRANCO", "cor": Colors.white},
    {"nome": "CINZA", "cor": Colors.grey},
  ];

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
                      "Cores",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.bluetooth,
                      color: Color(0xFF0A2C73),
                      size: 30,
                    ),
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
              "Selecione uma cor para transcrever",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              itemCount: cores.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE5E5E5)),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14),

                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cores[index]["cor"],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black26,
                      ),
                    ),
                  ),

                  title: Text(
                    cores[index]["nome"],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  trailing: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      // ação do botão
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 1.3,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 22,
                      ),
                    ),
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