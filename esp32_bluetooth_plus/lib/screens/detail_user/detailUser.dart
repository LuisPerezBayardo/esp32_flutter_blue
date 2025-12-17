import 'package:flutter/material.dart';


// \n

enum TipoUsuario {
  admin,
  user1,
  user2,
}

class Usuario {
  int id;
  String name;
  String password;
  TipoUsuario type;
  List<String> privileges; // Puedes usar Strings, Enums o constantes

  Usuario({
    required this.id,
    required this.name,
    required this.password,
    required this.type,
    required this.privileges,
  });


  factory Usuario.fromMap(Map<String, dynamic> map) {
    //  AQUIIIIII
    //En el map que paso del llamado en el getUserById (llamado a su vez en login), tengo un "type" tipo String, ya que, en la DB, es tipo text...
    //convertir primero ese type a otra variable tipo TipoUsuario, acorde al tipo de dato de "type" en Usuario...
    print(map['type'] + ', ' + map['privileges']);
    return Usuario(
      id: map['id'],
      name: map['name'] as String,
      password: map['password'] as String,
      type: TipoUsuario.values.byName(map['type'].split('.').last), // Validating, found that here is where it is added the "TipoUsuario." before the type value 77...
                                                                    // Because, printing in signup and at the begining of this factory function, it is written correctly...
      privileges: map['privileges'].split(","),
    );
  }


  // Ejemplo: Comprobar si tiene acceso a un botón
  bool tieneAcceso(String boton) {
    return privileges.contains(boton);
  }

  // Para obtener los privilegios según el tipo de usuario
  static List<String> privilegiosPorTipo(TipoUsuario tipo) {
    switch (tipo) {
      case TipoUsuario.admin:
        return [
          'botonBuscar',
          'botonAgendar',
          'botonPanelAdmin',
          'botonEliminarUsuario',
        ];
      case TipoUsuario.user1:
        return [
          'botonBuscar',
          'botonAgendar',
          'botonPanelProfesional',
        ];
      case TipoUsuario.user2:
        return [
          'botonBuscar',
          'botonAgendar',
        ];
      default:
        return [];
    }
  }
}

// Ejemplo de lista de usuarios:
List<Usuario> usuarios = [
  Usuario(
    id: 1,
    name: 'Abel',
    password: 'Abel123',
    type: TipoUsuario.admin,
    privileges: Usuario.privilegiosPorTipo(TipoUsuario.admin),
  ),
  Usuario(
    id: 2,
    name: 'Bryan',
    password: 'Bryan123',
    type: TipoUsuario.user1,
    privileges: Usuario.privilegiosPorTipo(TipoUsuario.user1),
  ),
  Usuario(
    id: 3,
    name: 'Luis',
    password: 'Luis123',
    type: TipoUsuario.user2,
    privileges: Usuario.privilegiosPorTipo(TipoUsuario.user2),
  ),
];