import 'package:flutter/material.dart';

class TelaSuasPalavras extends StatelessWidget {
  TelaSuasPalavras({super.key});

  final List<String> palavras = [
    "Pão",
    "Aprender Braille para todos, Dedolê",
    "Morango",
    "Casa",
    "Azul",
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
                  color: Color(0xff0094FF),
                  width: 3,
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
                      color: Color(0xff0A2C73),
                      size: 34,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      "Suas palavras",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  Container(
                    width: 58,
                    height: 42,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black45),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit_note, size: 30),
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
            padding: EdgeInsets.fromLTRB(18, 22, 18, 10),
            child: Text(
              "Palavras salvas no banco",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              itemCount: palavras.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xffE5E5E5)),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18),

                  title: Text(
                    palavras[index],
                    style: const TextStyle(fontSize: 22),
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 28,
                        ),
                      ),

                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.play_circle_outline,
                          size: 34,
                        ),
                      ),

                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {},
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: "editar",
                            child: Text("Editar"),
                          ),
                          PopupMenuItem(
                            value: "fila",
                            child: Text("Adicionar à fila"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        color: Colors.grey.shade300,
        padding: const EdgeInsets.all(14),
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(6),
          child: ListTile(
            dense: true,
            title: const Text("Foi adicionado à fila!"),
            trailing: TextButton(
              onPressed: () {},
              child: const Text("Abrir"),
            ),
          ),
        ),
      ),
    );
  }
}