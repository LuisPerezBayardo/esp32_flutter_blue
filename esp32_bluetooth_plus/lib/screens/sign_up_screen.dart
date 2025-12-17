import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'detail_user/detailUser.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  Usuario user = Usuario(id: 0, name: "null", password: "null", type: TipoUsuario.admin, privileges: Usuario.privilegiosPorTipo(TipoUsuario.user2));
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String seleccionTipoUsuario = 'user2';
  List<String> listaTiposUsuario = TipoUsuario.values.map((e) => e.name).toList();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _privilegesController = TextEditingController();


  Future _signup() async{
    for(int i=0; i<listaTiposUsuario.length; i++){
      print(listaTiposUsuario[i] + ", ");
    }
    //user.id = int.parse(_idController.text.trim());
    user.name = _nameController.text;
    user.password = _passwordController.text;
    //user.type = TipoUsuario.values[dr]
    //if()user.privileges = 
    
    
    //user.type = Usuario.TipoUsuario;
    //user.password = _passwordController.text;

    // Aquí puedes hacer validaciones o enviar a backend
    //print("Email: $email");
    //print("Password: $password");

    final dbHelper = DatabaseHelper();


    int validId = await dbHelper.insertUser(user.name, user.password, seleccionTipoUsuario);

    if (validId >= 0 && idValidation(user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado')),
      );
      print("ID: " + validId.toString());
      // Aquí podrías navegar a otra pantalla
      Navigator.pop(context);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error al crear el usuario')),
      );
    }

    

    // Ejemplo de feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Intentando iniciar sesión...')),
    );
  }


  bool idValidation(int id){
    //
    return true;
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Crear una cuenta',
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                const SizedBox(height: 32),

                // Email
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nombre',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 72),

                // Tipo de usuario
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona el tipo de usuario:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: seleccionTipoUsuario,
                      focusColor: Colors.cyan,
                      isExpanded: true, // ocupa todo el ancho del contenedor padre
                      dropdownColor: Colors.grey[900], // Fondo del menú desplegable
                      iconEnabledColor: Colors.white,  // Color de la flechita
                      style: const TextStyle(color: Colors.white), // Color del texto
                      items: listaTiposUsuario.map((String valor) {
                        return DropdownMenuItem<String>(
                          value: valor,
                          child: Text(valor),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          seleccionTipoUsuario = nuevoValor!;
                        });
                      },
                    ),
                  ],
                ),

                // Botón
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Crear usuario',
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
    _idController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

}