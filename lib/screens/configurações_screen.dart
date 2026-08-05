import 'package:flutter/material.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {

  bool modoEscuro = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF5F5F5),

      appBar: AppBar(
        title: const Text(
          "Configurações",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),


      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [


            const Text(
              "Aparência",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 15),



            Card(

              elevation: 2,

              child: SwitchListTile(

                title: const Text(
                  "Modo escuro",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),


                subtitle: const Text(
                  "Alterar tema do aplicativo",
                ),


                secondary: const Icon(
                  Icons.dark_mode,
                ),


                value: modoEscuro,


                onChanged: (valor){

                  setState(() {

                    modoEscuro = valor;

                  });

                },

              ),

            ),



          ],
        ),
      ),
    );
  }
}