import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'detail_user/detailUser.dart';
import 'package:esp32_bluetooth_plus/screens/sign_up_screen.dart';
import '../screens/scan_screen.dart';

enum Temas {
  claro,
  oscuro,
}


class SettingsScreen extends StatefulWidget {
  
  Usuario usuario;

  SettingsScreen({super.key, required this.usuario});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  String seleccionTema = "claro";
  List<String> listaTemas = Temas.values.map((e) => e.name).toList();


  @override
  void initState() {
    super.initState();
    Usuario user = widget.usuario;
    _nameController.text = user.name;
  }



  Future _applyChanges() async{
    // Cambios
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Configuraciones"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // 🔙 regresa
          color: Colors.grey,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ... resto de tu contenido (quita el Text grande "Configuraciones"
                // porque ya lo tienes en el AppBar)

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Temas:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: seleccionTema,
                      focusColor: Colors.cyan,
                      isExpanded: true, // ocupa todo el ancho del contenedor padre
                      dropdownColor: Colors.grey[900], // Fondo del menú desplegable
                      iconEnabledColor: Colors.white,  // Color de la flechita
                      style: const TextStyle(color: Colors.white), // Color del texto
                      items: listaTemas.map((String valor) {
                        return DropdownMenuItem<String>(
                          value: valor,
                          child: Text(valor),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          seleccionTema = nuevoValor!;
                        });
                      },
                    ),
                  ],
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

}