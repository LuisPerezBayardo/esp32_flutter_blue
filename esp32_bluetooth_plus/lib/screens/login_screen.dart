import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'detail_user/detailUser.dart';
import 'package:esp32_bluetooth_plus/screens/sign_up_screen.dart';
import '../screens/scan_screen.dart';
import '../utils/snackbar.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Usuario user=Usuario(id: 0, name: "nulll", password: "password", type: TipoUsuario.user2, privileges: Usuario.privilegiosPorTipo(TipoUsuario.user2));
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _privilegesController = TextEditingController();


  Future _login() async{
    print('Intentando iniciar sesión...');
    user.id = int.parse(_idController.text.trim());
    user.password = _passwordController.text;

    final dbHelper = DatabaseHelper();

    bool isValid = await dbHelper.validateUser(user.id, user.password);

    if (isValid) {
      print('isValid...');
      /*
      try{ user = (await dbHelper.getUserById(user.id))!;
        } catch(e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User dbHelper returning error...')),);}
          */
      int id=user.id;
      final user2 = await dbHelper.getUserById(id);  //// AQUIIIIIII
      if (user2 != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicio de sesión exitoso')),);
        String username=user2.name;             // para el print
        String userType=user2.type.toString();  // para el print
        print('Nombre: $username \nTipo: $userType');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ScanScreen(usuario: user2),),
        );
      } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User dbHelper returning error...')),);
    }

  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // ID
                TextField(
                  controller: _idController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Id',
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

                // Botón
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Iniciar sesión',
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
                TextButton(
                  onPressed: () {
                    Navigator.push(
                    context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                    // Acción para crear cuenta
                  },
                  child: const Text(
                    '¿No tienes cuenta? Crear cuenta',
                    style: TextStyle(color: Colors.tealAccent),
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
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

}

