import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'detail_user/detailUser.dart';
import 'package:esp32_bluetooth_plus/screens/sign_up_screen.dart';
import '../screens/scan_screen.dart';


class ProfileScreen extends StatefulWidget {
  
  Usuario usuario;

  ProfileScreen({super.key, required this.usuario});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _privilegesController = TextEditingController();
  String seleccionTipoUsuario = 'user2';
  List<String> listaTiposUsuario = TipoUsuario.values.map((e) => e.name).toList();


  @override
  void initState() {
    super.initState();
    Usuario user = widget.usuario;
    _idController.text = user.id.toString();
    _nameController.text = user.name; // <- tu texto aquí
    _passwordController.text = user.password;
    _typeController.text = user.type.toString().split('.').last;
    //_privilegesController.text = user.privileges.toString();
  }



  Future _edit() async{
    Usuario user = widget.usuario;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intentando actualizar datos... ')),);

    user.id = int.parse(_idController.text.trim());
    user.name = _nameController.text;

    final dbHelper = DatabaseHelper();

    int isValid = await dbHelper.updateUser(user.id, user.name, user.password, seleccionTipoUsuario);

    if (isValid == 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos actualizados')),);
      Usuario newUser = await getNewUser(user.id);
      print(newUser.toString());
      if (newUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanScreen(usuario: newUser),
        ),
      );
    } else {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error actualizar los datos. Datos no actualizados')),
      );
    }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error actualizar los datos. Datos no actualizados')),
      );
    }

  }






  Future<Usuario> getNewUser(int id) async {
    final dbHelper = DatabaseHelper();
    final user2 = await dbHelper.getUserById(id);  //// AQUIIIIIII
    if (user2 != null) {
      print("newUser got");
      String username=user2.name;             // para el print
      String userType=user2.type.toString();  // para el print
      print('Nombre: $username \nTipo: $userType');
      return user2;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario o contraseña incorrectos')),);
      return Usuario(id: id, name: "nullName", password: "nullPassword", type: TipoUsuario.user2, privileges: [""]);
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Mi usuario',
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

                // Id
                TextField(
                  controller: _idController,
                  enabled: false, // Esto lo desactiva
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ID',
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

                // Nombre
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
                const SizedBox(height: 24),

                // Tipo usuario
                /*TextField(
                  controller: _typeController,
                  obscureText: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'User type',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),*/

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona el tipo de usuario:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.cyanAccent,
                        letterSpacing: 1.2,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(1, 1),),],
                      ),
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
                    onPressed: _edit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Editar datos',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Links
                TextButton(
                  onPressed: () {
                    // Acción de recuperación de contraseña
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
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
    _typeController.dispose();
    _privilegesController.dispose();
    super.dispose();
  }

}