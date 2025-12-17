import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert'; // utf8.encode
import '../utils/data_entry.dart';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'detail_user/detailUser.dart';
import 'detail_device/detailDevice.dart';


class NewDeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final Usuario usuario;

  const NewDeviceScreen({super.key, required this.device, required this.usuario});

  @override
  State<NewDeviceScreen> createState() => _NewDeviceScreenState();
}

class _NewDeviceScreenState extends State<NewDeviceScreen> {
  Usuario user1 = Usuario(id: 0, name: "null", password: "null", type: TipoUsuario.admin, privileges: Usuario.privilegiosPorTipo(TipoUsuario.user2));
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rssiController = TextEditingController();
  final bool last_seen=false;
  String seleccionLastSeen='No';
  List<String> lastSeenValues = ["Yes", "No"];
  final TextEditingController _last_seenController = TextEditingController();
  final TextEditingController _favoriteController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  String seleccionDeviceType = 'sensor';
  List<String> listaTiposDispositivos = TipoDispositivo.values.map((e) => e.name).toList();
  final TextEditingController _deviceTypeController = TextEditingController();
  String seleccionFunctionType = 'funcion1';
  List<String> listaTiposFuncion = TipoFuncion.values.map((e) => e.name).toList();
  final TextEditingController _functionTypeController = TextEditingController();
  String seleccionPrivilegeType = 'privilegio1';
  List<String> listaTiposPrivilegios = TipoPrivilegio.values.map((e) => e.name).toList();
  final TextEditingController _privilegeTypeController = TextEditingController();




  Future _addDevice() async{
    Usuario user = widget.usuario;
    BluetoothDevice dev = widget.device;
    Dispositivo dispositivo = Dispositivo(id: 0, address: "", name: "", rssi: 0, last_seen: last_seen, favorite: 0,
                    notes: "notes", serial: "serial", functionType: "functionType", deviceType: "deviceType", privilegeType: TipoPrivilegio.deviceType1);

    for(int i=0; i<listaTiposDispositivos.length; i++){
      print(listaTiposDispositivos[i] + ", ");
    }
    
    dispositivo.address = _addressController.text;
    dispositivo.name = _nameController.text;
    dispositivo.rssi = int.parse(_rssiController.text);
    dispositivo.last_seen = _last_seenController as bool;
    dispositivo.favorite = int.parse(_favoriteController.text);
    dispositivo.notes = _notesController.text;
    dispositivo.serial = _serialController.text;
    dispositivo.functionType = _functionTypeController.text;
    dispositivo.deviceType = _deviceTypeController.text;
    dispositivo.privilegeType = TipoPrivilegio.deviceType1;
    
    
    //user.type = TipoUsuario.values[dr]
    //if()user.privileges = 
    
    
    //user.type = Usuario.TipoUsuario;
    //user.password = _passwordController.text;

    // Aquí puedes hacer validaciones o enviar a backend
    //print("Email: $email");
    //print("Password: $password");

    final dbHelper = DatabaseHelper();


    int validId = await dbHelper.insertDevice(dispositivo.address, dispositivo.name, dispositivo.rssi, dispositivo.last_seen, dispositivo.favorite, dispositivo.notes,
                                                        dispositivo.serial, dispositivo.functionType, dispositivo.deviceType, dispositivo.privilegeType as String);

    if (validId >= 0 && idValidation(user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispositivo agregado')),
      );
      print("ID: " + validId.toString());
      // Aquí podrías navegar a otra pantalla
      Navigator.pop(context);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error al agregar el dispositivo')),
      );
    }

    

    // Ejemplo de feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Intentando agregar dispositivo...')),
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
          'Agrega un dispositivo ',
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

                // Address
                TextField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Address',
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

                // Name
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Name',
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

                // Rssi
                TextField(
                  controller: _rssiController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rssi',
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

                // Last seen
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last seen device:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: seleccionLastSeen,
                      focusColor: Colors.cyan,
                      isExpanded: true, // ocupa todo el ancho del contenedor padre
                      dropdownColor: Colors.grey[900], // Fondo del menú desplegable
                      iconEnabledColor: Colors.white,  // Color de la flechita
                      style: const TextStyle(color: Colors.white), // Color del texto
                      items: lastSeenValues.map((String valor) {
                        return DropdownMenuItem<String>(
                          value: valor,
                          child: Text(valor),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          seleccionLastSeen = nuevoValor!;
                        });
                      },
                    ),
                  ],
                ),

                // Favorite
                TextField(
                  controller: _favoriteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Favorite',
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

                // Notes
                TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Notes',
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

                // Serial
                TextField(
                  controller: _serialController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Serial',
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

                // Function type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Function type:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: seleccionFunctionType,
                      focusColor: Colors.cyan,
                      isExpanded: true, // ocupa todo el ancho del contenedor padre
                      dropdownColor: Colors.grey[900], // Fondo del menú desplegable
                      iconEnabledColor: Colors.white,  // Color de la flechita
                      style: const TextStyle(color: Colors.white), // Color del texto
                      items: listaTiposFuncion.map((String valor) {
                        return DropdownMenuItem<String>(
                          value: valor,
                          child: Text(valor),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          seleccionFunctionType = nuevoValor!;
                        });
                      },
                    ),
                  ],
                ),

                // Device type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device type:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: seleccionDeviceType,
                      focusColor: Colors.cyan,
                      isExpanded: true, // ocupa todo el ancho del contenedor padre
                      dropdownColor: Colors.grey[900], // Fondo del menú desplegable
                      iconEnabledColor: Colors.white,  // Color de la flechita
                      style: const TextStyle(color: Colors.white), // Color del texto
                      items: listaTiposDispositivos.map((String valor) {
                        return DropdownMenuItem<String>(
                          value: valor,
                          child: Text(valor),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          seleccionDeviceType = nuevoValor!;
                        });
                      },
                    ),
                  ],
                ),

                // Privilege type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privilege type:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: seleccionPrivilegeType,
                      focusColor: Colors.cyan,
                      isExpanded: true, // ocupa todo el ancho del contenedor padre
                      dropdownColor: Colors.grey[900], // Fondo del menú desplegable
                      iconEnabledColor: Colors.white,  // Color de la flechita
                      style: const TextStyle(color: Colors.white), // Color del texto
                      items: listaTiposDispositivos.map((String valor) {
                        return DropdownMenuItem<String>(
                          value: valor,
                          child: Text(valor),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          seleccionPrivilegeType = nuevoValor!;
                        });
                      },
                    ),
                  ],
                ),

                // Botón
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Agregar dispositivo',
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
    _addressController.dispose();
    super.dispose();
  }

}