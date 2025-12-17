import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:esp32_bluetooth_plus/screens/detail_device/detailWifiDevice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert'; // utf8.encode
import '../utils/data_entry.dart';
import '../core/mqtt_service.dart';
import '../services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:collection/collection.dart';

import '../widgets/service_tile.dart';
import '../widgets/characteristic_tile.dart';
import '../widgets/descriptor_tile.dart';
import '../utils/snackbar.dart';
import '../utils/extra.dart';
import 'detail_user/detailUser.dart';
import 'detail_device/detailDevice.dart';
import 'new_device_screen.dart';




class DeviceScreen extends StatefulWidget {
  final BluetoothDevice bluetoothDevice;
  final Dispositivo dispositivo;
  final WifiDevice wifiDevice;
  final Usuario usuario;

  const DeviceScreen({super.key, required this.dispositivo, required this.wifiDevice, required this.bluetoothDevice, required this.usuario});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  // --- (Opcional) UUIDs del Nordic UART Service (ajusta a tus UUID reales) ---
  final Guid kServiceUuidNus    = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid kWriteCharUuidNus  = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid serviceUuid = Guid("0000AAAA-0000-1000-8000-00805F9B34FB");
  final Guid charUuid    = Guid("0000BBBB-0000-1000-8000-00805F9B34FB");

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;
  late StreamSubscription<int> _write;

  BluetoothCharacteristic? _char_notif;
  StreamSubscription<List<int>>? _notifySub;      // READING ESP32 PARAMETER SENSING VALUES!!
  bool _listening = false;
  String _variable="";
  String variableName="";
  double min=0, max=10;
  String variableUnits = "";
  bool _variableOutOfLimits=false;
  bool _communicationSleep=false;
  int sleepCounter=0; // Hasta 500



  // === API: Estado de red ===
  String? deviceId; // ID del backend (Postgres)
  StreamSubscription<Map<String, dynamic>>? _telemetrySub;
  bool _mqttReady = false;

  final bool _listeningWifi = false;




  @override
  void initState() {
    super.initState();
    Usuario user = widget.usuario;
    BluetoothDevice bluetoothDevice = widget.bluetoothDevice;
    Dispositivo dispositivo = widget.dispositivo;
    WifiDevice wifiDevice = widget.wifiDevice;

    _connectionStateSubscription = widget.bluetoothDevice.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.bluetoothDevice.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    _mtuSubscription = widget.bluetoothDevice.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isConnectingSubscription = widget.bluetoothDevice.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription = widget.bluetoothDevice.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
    // Mi modificacion: obtener los services desde el principio para usar con los botones...
    onDiscoverServicesPressed(); //
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    stopNotifications();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future onConnectPressed() async {
    try {
      await widget.bluetoothDevice.connectAndUpdateStream();
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e, backtrace) {
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
        print(e);
        print("backtrace: $backtrace");
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.bluetoothDevice.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
      print("$e");
      print("backtrace: $backtrace");
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.bluetoothDevice.disconnectAndUpdateStream();
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e), success: false);
      print("$e backtrace: $backtrace");
    }
  }

  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      _services = await widget.bluetoothDevice.discoverServices();
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await widget.bluetoothDevice.requestMtu(223, predelay: 0);
      Snackbar.show(ABC.c, "Request Mtu: Success", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Change Mtu Error:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
  }

  List<Widget> _buildServiceTiles(BuildContext context, BluetoothDevice d) {
    return _services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics.map((c) => _buildCharacteristicTile(c)).toList(),
          ),
        )
        .toList();
  }

  CharacteristicTile _buildCharacteristicTile(BluetoothCharacteristic c) {
    return CharacteristicTile(
      characteristic: c,
      descriptorTiles: c.descriptors.map((d) => DescriptorTile(descriptor: d)).toList(),
    );
  }

  Widget buildSpinner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${widget.bluetoothDevice.remoteId}'),
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected ? const Icon(Icons.bluetooth_connected) : const Icon(Icons.bluetooth_disabled),
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''), style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        TextButton(
          onPressed: onDiscoverServicesPressed,
          child: const Text("Get Services"),
        ),
        const IconButton(
          icon: SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
          ),
          onPressed: null,
        )
      ],
    );
  }

  Widget buildMtuTile(BuildContext context) {
    return ListTile(
        title: const Text('MTU Size'),
        subtitle: Text('$_mtuSize bytes'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onRequestMtuPressed,
        ));
  }

  Widget buildConnectButton(BuildContext context) {
    return Row(children: [
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      ElevatedButton(
          onPressed: _isConnecting ? onCancelPressed : (isConnected ? onDisconnectPressed : onConnectPressed),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(
            _isConnecting ? "CANCEL" : (isConnected ? "DISCONNECT" : "CONNECT"),
            style: Theme.of(context).primaryTextTheme.labelLarge?.copyWith(color: Colors.white),
          ))
    ]);
  }





  
  Future<void> prepareNetwork({required String macOrSerial}) async {
    try {
      // 1. Resolver deviceId vía REST (puedes cambiar esta función a lookup por MAC/serial)
      deviceId ??= await _resolveDeviceId(macOrSerial);
      if (deviceId == null) throw Exception('No se pudo resolver deviceId');
      // 2. Conectar MQTT
      await _ensureMqtt();

      // 3. Leer configuración inicial (min/max/unidades/variable)
      await _fetchInitialConfig();
      // 4. Suscribirse a telemetría en vivo (equivalente a empezar notificaciones BLE)
      _subscribeTelemetry();
      // 5. (Opcional) Disparar comando de "start stream" para que el firmware comience a publicar
      await _sendStartStream();
    } catch (e) {
      debugPrint('prepareNetwork error: $e');
      rethrow;
    }
  }




  // === 2) START NOTIFICATIONS: aquí es suscripción al topic MQTT + parse ===
  void _subscribeTelemetry() {
    if (deviceId == null) return;
    _telemetrySub?.cancel();
    _telemetrySub = MqttService.I.subscribeTelemetry(deviceId!).listen((msg) {
      try {
        // Esperado: { ts: ISO8601, metrics: {...}, fw: 'x', rssi: -58 }
        // Tú antes decodificabas bytes a: variableStatus, communicationSleep, variableValue
        // Aquí derivamos estado en base a métricas y umbrales (min/max)
        final metrics = (msg['metrics'] ?? {}) as Map<String, dynamic>;

        // Elige la primera métrica numérica para mostrar si no has fijado una clave
        final entry = metrics.entries.firstWhereOrNull((e) => e.value is num);
        if (entry != null) {
          final key = entry.key; final val = (entry.value as num).toDouble();
          final inRange = (val >= min && val <= max);

          setState(() {
            variableName = key; // p. ej. temp_c
            variableUnits = _unitsFor(key); // mapea nombre→unidades si quieres
            _variable = val.toStringAsFixed(2);
            _variableOutOfLimits = !inRange;
            _communicationSleep = false; // si tu backend marca sleep, léelo de msg
            _listening = true;
          });
        }

        // Simula tu lógica de sleepCounter si la conservas
        if (++sleepCounter >= 500) {
          sleepCounter = 0; _communicationSleep = true; stopNotificationsNetwork();
        }
      } catch (e) {
        debugPrint('parse telemetry error: $e');
      }
    });
  }


  // === 3) STOP NOTIFICATIONS: cancela stream MQTT ===
  Future<void> stopNotificationsNetwork() async {
    await _telemetrySub?.cancel();
    _telemetrySub = null;
    _listening = false;
  }




  // === Helpers internos ===
  Future<String?> _resolveDeviceId(String macOrSerial) async {
    // Si ya tienes un endpoint /devices:lookup?mac=xx o ?serial=xx, úsalo.
    // Aquí ejemplo sencillo: descargar lista y buscar.
    final all = await ApiClient.I.listDevices();
    final found = all.firstWhereOrNull((d) => d.mac == macOrSerial || d.serial == macOrSerial);
    return found?.id;
  }


  Future<void> _ensureMqtt() async {
    if (!MqttService.I.connected) {
      await MqttService.I.connect();
      _mqttReady = true;
    }
  }


  Future<void> _fetchInitialConfig() async {
    if (deviceId == null) return;
    // Puedes guardar min/max/unidades en el propio Device o en /devices/{id}/config
    try {
      final d = await ApiClient.I.getDevice(deviceId!);
      // Ejemplo: si guardas thresholds por tipo de dispositivo
      final cfg = await _getConfigForDevice(deviceId!); // opcional; cambia por tu endpoint real
      setState(() {
        min = (cfg['min'] ?? 0).toDouble();
        max = (cfg['max'] ?? 100).toDouble();
        variableUnits = (cfg['units'] ?? '');
      });
    } catch (_) {}
  }


  Future<Map<String, dynamic>> _getConfigForDevice(String id) async {
    // Si no tienes endpoint aún, regresa valores por defecto
    return { 'min': 0, 'max': 50, 'units': '°C' };
  }


  Future<void> _sendStartStream() async {
    if (deviceId == null) return;
    // Equivalente a escribir "3" en BLE para activar notificaciones
    await ApiClient.I.sendCommand(
      deviceId: deviceId!,
      command: 'start_stream',
      params: { 'interval_ms': 2000 },
      ttlMs: 5000,
    );
  }


  String _unitsFor(String key) {
    switch (key) {
      case 'temp_c': return '°C';
      case 'humidity_pct': return '%';
      default: return '';
    }
  }



  




























  Future<void> _prepare() async {
    // Asegúrate de estar conectado antes de esto
    /*print("before discoverServices (in prepare)"); // SÍ SALE
    final services = await widget.device.discoverServices();
    print("after discoverServices (in prepare)"); // SÍ SALE
    for (final s in services) {
      if (s.uuid == serviceUuid) {
        for (final c in s.characteristics) {
          if (c.uuid == charUuid) {
            _char_notif = c; //ESTABA COMENTADO... No se si deba descomentarlo. Estoy obteniendo esto como null, pero en debug console sí aparecen los servicios en JSON
            break;
          }
        }
      }
    }
    print("after first (anidated) for loop (in prepare)"); // SÍ SALE
    for (final s in _services) {
      if (s.uuid == serviceUuid) {
        for (final c in s.characteristics) {
          if (c.properties.notify) {
            _char_notif = c;
          }
        }
      }
    }
    print("after second (anidated) for loop (in prepare)"); // SÍ SALE XD*/   // biejo


    try {
      BluetoothCharacteristic? BC;
      // 1) Conectar si no está conectado
      final stateNow = await widget.bluetoothDevice.connectionState.first;
      if (stateNow != BluetoothConnectionState.connected) {
        await widget.bluetoothDevice.connect(autoConnect: false);
      }
      // 2b) Fallback: primera characteristic con permiso de escritura
      for (final s in _services) {
        for (final c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            BC = c;
          }
        }
      }
      _char_notif = BC;

    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }

    startNotifications();
  }



  Future<void> startNotifications() async {
    if (_char_notif == null || _listening){
      print("char notif is null x/; listening is: $_listening");
      return;
    }
    if (_char_notif == null) return;

    // 1) habilita notify y ESPERA a que termine
    await _char_notif!.setNotifyValue(true);

    // 2) evita doble suscripción
    //await _notifySub?.cancel();

    _notifySub = _char_notif!.onValueReceived.listen((List<int> data) async {
      try{
        print("inside onValueReceived");
        final value=data;
        print(value);
        final dataToBytes = Uint8List.fromList(data); 
        print("dataToBytes: $dataToBytes");
        //final value=data.toString();  // DEBUGGGGGG
        final dtb = ByteData.sublistView(dataToBytes);
        print("dtb: $dtb");
        final variableStatus = dataToBytes[0];  // 0: OK, 1: Under limits, 2: Above limits
        print("variableStatus: $variableStatus");
        final communicationSleep = dataToBytes[1];  // 0: No communication, 1: Active, 2: Sleep
        print("communicationSleep: $communicationSleep");
        _communicationSleep=communicationSleep!=1;
        final variableValue = dtb.getInt16(2, Endian.little).toString();
        print("muestra: $variableValue");
        setState(() {
          _variable = variableValue;
          //_listening = !_communicationSleep;
        });
        _listening = !_communicationSleep;
        print("muestra: $variableValue after setState");
        if(variableStatus > 0 || int.parse(_variable) < min || int.parse(_variable) > max){
          if(data[2]==1){   // variable in range:0; variable<min:1; variable>max:2
            _variableOutOfLimits=true;    // PONER EN SCAFFOLD PARA VER GRAFICAMENTE
            // accion actuador
          }
        }
        if(_communicationSleep){
          await stopNotifications();
        }
        if(++sleepCounter>=500 && false){ // Por ahora no usar
          sleepCounter=0;
          _communicationSleep=true;
          await stopNotifications();
        }
        print("out of limits: ${_variableOutOfLimits.toString()}, communication sleep: ${_communicationSleep.toString()}");
      } catch(e){Snackbar.show(ABC.b, prettyException('Parse error: ', e), success: false);}
    });
    await _char_notif!.write(utf8.encode("3"));   // hoy 11/9/2025 (activar notificaciones)
    print("after sending '3'");
    final raw = await _char_notif!.read();
    final b = Uint8List.fromList(raw);
    if (b.length >= 5) {
      final bd = ByteData.sublistView(b);
      final varId   = b[0];
      final minX100 = bd.getInt16(1, Endian.little);
      final maxX100 = bd.getInt16(3, Endian.little);
      setState(() {
        variableName = TipoVariable.values[varId].name;
        min = minX100 / 100.0;
        max = maxX100 / 100.0;
        variableUnits = UnidadMedicion.values[varId].name;
      });
    }
    print("after recieving initial config... min: $min, max: $max, var: $variableName");
    await _char_notif!.write(utf8.encode("4"));
    print("after sending '4'");
    //ANTES AQUI PONIA EL ON_VALUE_RECEIVED...
    print("after all onValueReceived");
  }



Future<void> _readInitialConfig() async {
  sendData("3");
  final raw = await _char_notif!.read();   // obtiene CFG desde el valor READ
  final bytes = Uint8List.fromList(raw);

  /*if (!_isCFG(bytes)) {
    // si no vino CFG, podrías solicitarla:
    // await _char_notif!.write(utf8.encode("CONFIG?"));
    // final raw2 = await _char_notif!.read();
    // ...
    throw Exception("CFG inválida o ausente");
  }*/

  print("bytes: ........................................");
  print(bytes);
  //final varId  = bytes[3];
  final varId  = bytes[0] - 48;   //ascii to dec
  //final minX100 = _getInt16LE(bytes, 4);
  //final maxX100 = _getInt16LE(bytes, 6);

  setState(() {
    variableName = (varId == 0) ? TipoVariable.temperatura.toString() : TipoVariable.values[varId].toString();
    //min = minX100 / 100.0;
    //max = maxX100 / 100.0;
  });
}



  Future<void> stopNotifications() async {
    await _notifySub?.cancel();
    print("inside stopNotifications");
    //await _char_notif!.write(utf8.encode("5"));
    _notifySub = null;

    if (_char_notif != null) {
      try {
        await _char_notif!.write(utf8.encode("5"));
        //await _char_notif!.setNotifyValue(false);
      } catch (e) {Snackbar.show(ABC.b, prettyException('Parse error: ', e), success: false);}
    }
    //setState(() => _listening = false);
    _listening = false;
  }



  Future<void> stopNotificationsWifi() async{
    await stopNotificationsNetwork();
  }
















  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyC,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.bluetoothDevice.platformName),
          actions: [
            // 🔖 Botón: Recordar dispositivo
            IconButton(
              tooltip: 'Recordar dispositivo',
              icon: const Icon(Icons.bookmark_add_rounded),
              onPressed: () {
                if(widget.usuario.type == TipoUsuario.admin){
                  NewDeviceScreen(usuario: widget.usuario, device: widget.bluetoothDevice);
                }
                else{
                  Snackbar.show(ABC.c, "Sin permisos para realizar la acción", success: false);
                }
              },
            ),
            // Tu botón de conectar existente
            buildConnectButton(context),
            const SizedBox(width: 15),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.grey,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              buildRemoteId(context),
              ListTile(
                leading: buildRssiTile(context),
                title: Text('Device is ${_connectionState.toString().split('.')[1]}.'),
                trailing: buildGetServices(context),
              ),
              buildMtuTile(context),
              ..._buildServiceTiles(context, widget.bluetoothDevice),
              // /*
              ElevatedButton(
                child: Text("Send '1'"),
                onPressed: () => sendData('1'),
              ),
              ElevatedButton(
                child: Text("Send '2'"),
                onPressed: () => sendData('2'),
              ),
              ElevatedButton(
                child: Text("Listen console"),
                onPressed: () => listenConsole(),
              ),
              ElevatedButton(
                //child: Text("Read values"),
                onPressed: _listeningWifi ? stopNotificationsWifi : ReadValuesWifi,       // Peticion API
                //onPressed: _listening ? stopNotifications : readValues,
                child: Text(_listening ? "Stop reading (WiFi)" : "Read continuously (notify WiFi)"),
              ),
              ElevatedButton(
                //child: Text("Read values"),
                onPressed: _listening ? stopNotifications : readValues,
                child: Text(_listening ? "Stop reading (Bluetooth)" : "Read continuously (notify bluetooth)"),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.thermostat, color: Colors.cyan, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      //"Temperatura: $_temperature °C",
                      "$variableName: $_variable $variableUnits",
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
              // */
            ],
          ),
        ),
      ),
    );
  }







  Future sendData(String data) async {
    try {
      BluetoothCharacteristic? BC;
      // 1) Conectar si no está conectado
      final stateNow = await widget.bluetoothDevice.connectionState.first;
      if (stateNow != BluetoothConnectionState.connected) {
        await widget.bluetoothDevice.connect(autoConnect: false);
      }
      // 2b) Fallback: primera characteristic con permiso de escritura
      for (final s in _services) {
        for (final c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            BC = c;
          }
        }
      }
      // 3. Mandar el dato
      try {
        //List<int>? value2 = utf8.encode(string);
        List<int> value = utf8.encode(data);
        if (value != null) {
          await BC?.write(value, withoutResponse: BC.properties.writeWithoutResponse);
          String dataSent = value.toString();
          Snackbar.show(ABC.c, "Write: Success. Sent: $value", success: true);
          /*if (BC!.properties.read) {
            await BC.read();
          }*/
        }
      } catch (e) {
        Snackbar.show(ABC.c, "Error al enviar: $e", success: true);
      }

    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
  }





  Future listenConsole() async{
    //.....
  }

  Future readValues() async{
    Usuario user = widget.usuario;
    if(!(user.type == TipoUsuario.admin || user.type == TipoUsuario.user1 || user.type == TipoUsuario.user2)){
      Snackbar.show(ABC.c, "El usuario no cuenta con los privilegios para realizar la acción", success: true);
      return;
    }
    await _prepare();
    //.....
  }


  Future ReadValuesWifi() async{
    Device dev = Device(id: widget.device., serial: '', mac: '', type: '', station: '', status: '', fwVersion: ''); 
    widget.device.
    prepareNetwork(macOrSerial: widget.device.);
  }




  Future sendDataEraser(String data) async {
    try {
      BluetoothCharacteristic? BC;
      // 1) Conectar si no está conectado
      final stateNow = await widget.device.connectionState.first;
      if (stateNow != BluetoothConnectionState.connected) {
        await widget.device.connect(autoConnect: false);
      }
      // 2a) Intentar por UUID conocidos (NUS)
      /*for (final s in _services) {
        if (s.uuid == kServiceUuidNus) {
          for (final c in s.characteristics) {
            if (c.uuid == kWriteCharUuidNus) {
              BC = c;
              break;
            }
          }
        }
      }*/
      // 2b) Fallback: primera characteristic con permiso de escritura
      for (final s in _services) {
        for (final c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            BC = c;
          }
        }
      }
      // No se encontró characteristic escribible
      /*try {
        List<int>? value = await DataEntry.enterData(context);
        if (value != null) {
          await BC!.write(value, withoutResponse: BC.properties.writeWithoutResponse);
          Snackbar.show(ABC.c, "Write: Success", success: true);
          if (BC.properties.read) {
            await BC.read();
          }
        }
      } catch (e, backtrace) {
        Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
        print(e);
        print("backtrace: $backtrace");
      }
      if (BC == null) {
        setState(() {
          Snackbar.show(ABC.c, "No se encontró characteristic escribible", success: true);
        });
        throw Exception("No writable characteristic found");
      }*/
      // 3. Mandar el dato
      try {
        /*
        //final BC = await _ensureReady();
        final bytes = utf8.encode(data); // por ej. '1' o '2'
        final useWoResp = BC!.properties.writeWithoutResponse;
        await BC.write(
          bytes,
          withoutResponse: useWoResp,
        );
        */
        //final c = await _ensureReady();
        final bytes = utf8.encode(data); // por ej. '1' o '2'
        final useWoResp = BC!.properties.writeWithoutResponse;
        await BC.write(
          bytes,
          withoutResponse: useWoResp,
        );

        Snackbar.show(ABC.c, "No se encontró characteristic escribible", success: true);
      } catch (e) {
        Snackbar.show(ABC.c, "Error al enviar: $e", success: true);
      }

    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
  }
}
























bool _isCFG(Uint8List b) => b.length >= 8 && b[0]==0x43 && b[1]==0x46 && b[2]==0x47; // 'C''F''G'
bool _isDAT(Uint8List b) => b.length >= 6 && b[0]==0x44 && b[1]==0x41 && b[2]==0x54; // 'D''A''T'
int _getInt16LE(Uint8List b, int off) =>
ByteData.sublistView(b).getInt16(off, Endian.little);

class SensorConfig {
  final int varId;
  final int minX100;
  final int maxX100;
  SensorConfig(this.varId, this.minX100, this.maxX100);
}
