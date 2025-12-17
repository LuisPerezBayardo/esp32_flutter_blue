import 'package:flutter/material.dart';


// \n

enum TipoFuncion {
  sensor,
  actuador,
  mixto,
}

enum TipoDispositivo{
    esp32_s3_wroom_1,
    esp32_32d
}

enum TipoPrivilegio{
    deviceType1,
    deviceType2,
    deviceType3
}

enum TipoVariable{
    temperatura,
    corriente,
    voltaje,
    nivel,
}

enum UnidadMedicion{
  C,  // Celsius
  A,  // Amperes
  v,  // Volts
  cm  // Centimeters
}



class Dispositivo {
  int id;
  String address;
  String name;
  int rssi;
  bool last_seen;
  int favorite;
  String notes;
  String serial;
  String functionType;
  String deviceType;
  TipoPrivilegio privilegeType;

  Dispositivo({
    required this.id,
    required this.address,
    required this.name,
    required this.rssi,
    required this.last_seen,
    required this.favorite,
    required this.notes,
    required this.serial,
    required this.functionType,
    required this.deviceType,
    required this.privilegeType,
  });


  factory Dispositivo.fromMap(Map<String, dynamic> map) {
    //  AQUIIIIII
    //En el map que paso del llamado en el getUserById (llamado a su vez en login), tengo un "type" tipo String, ya que, en la DB, es tipo text...
    //convertir primero ese type a otra variable tipo TipoUsuario, acorde al tipo de dato de "type" en Usuario...
    print(map['type']);
    return Dispositivo(
      id: map['id'],
      address: map['address'],
      name: map['name'] as String,
      rssi: map['rssi'],
      last_seen: map['last_seen'] as bool,
      favorite: map['favorite'],
      notes: map['notes'] as String,
      serial: map['serial'] as String,
      functionType: TipoFuncion.values.byName(map['functionType'].split('.').last) as String, // Here is where it is added the "TipoDispositivoFuncion." before the type value
      deviceType: TipoDispositivo.values.byName(map['deviceType'].split('.').last) as String,
      privilegeType: TipoPrivilegio.values.byName(map['privilegeType'].split('.').last),
    );
  }



  bool tieneAcceso(String privilege) {
    return privilege=="device1";
  }
  

  // Para obtener los privilegios según el tipo de dispositivo por privilegio
  static List<String> privilegiosPorTipo(TipoPrivilegio tipo) {
    switch (tipo) {
      case TipoPrivilegio.deviceType1:
        return [
          'botonBuscar',
          'botonAgendar',
          'botonPanelAdmin',
          'botonEliminarUsuario',
        ];
      case TipoPrivilegio.deviceType2:
        return [
          'botonBuscar',
          'botonAgendar',
          'botonPanelProfesional',
        ];
      case TipoPrivilegio.deviceType3:
        return [
          'botonBuscar',
          'botonAgendar',
        ];
      }
  }
}

// Ejemplo de lista de usuarios:
List<Dispositivo> dispositivos = [
  Dispositivo(
    id: 1,
    name: "long name works now!",
    serial: 'FLM99101QXC',
    functionType: TipoFuncion.mixto.toString(),
    deviceType: TipoDispositivo.esp32_32d.toString(),
    privilegeType: TipoPrivilegio.deviceType1,
    address: '',
    rssi: 0,
    last_seen: false,
    favorite: 0,
    notes: ''
  ),
  Dispositivo(
    id: 2,
    name: "long name works now 2!",
    serial: 'FLM99101QDE',
    functionType: TipoFuncion.actuador.toString(),
    deviceType: TipoDispositivo.esp32_32d.toString(),
    privilegeType: TipoPrivilegio.deviceType2,
    address: '',
    rssi: 1,
    last_seen: true,
    favorite: 1,
    notes: ''
  ),
  Dispositivo(
    id: 3,
    name: "Actuador",
    serial: 'FLM99102CHE',
    functionType: TipoFuncion.sensor.toString(),
    deviceType: TipoDispositivo.esp32_s3_wroom_1.toString(),
    privilegeType: TipoPrivilegio.deviceType3,
    address: '',
    rssi: 1,
    last_seen: true,
    favorite: 1,
    notes: ''
  ),
];