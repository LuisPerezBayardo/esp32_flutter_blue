import 'dart:async';

import 'package:esp32_bluetooth_plus/screens/profile_screen.dart';
import 'package:esp32_bluetooth_plus/screens/settings_screen.dart';
import 'package:esp32_bluetooth_plus/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../database_helper.dart';

import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../utils/extra.dart';
import 'detail_user/detailUser.dart';
import '../services/api_client.dart';
import 'detail_device/detailDevice.dart';
import 'detail_device/detailWifiDevice.dart';


class ScanScreen extends StatefulWidget {
  // aqui
  final Usuario usuario;
  List<WifiDevice> _wifiDevices = [];
  bool _isScanning = false;
  Timer? _refreshTimer;
  Dispositivo dispositivo =Dispositivo(id: 0, address: "", name: "name", rssi: 0, last_seen: false, favorite: 0, notes: "",
                                        serial: "", functionType: "", deviceType: "", privilegeType: TipoPrivilegio.deviceType1);

  ScanScreen({super.key, required this.usuario});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}


class _DisplayDevice {
    final BluetoothDevice device;
    final int? rssi;
    final bool fromSystem;
    _DisplayDevice({required this.device, this.rssi, required this.fromSystem});
}


class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    Usuario user = widget.usuario;
    if (user.type == TipoUsuario.admin) {
      // Aquí podrías habilitar features de admin
    } else if (user.type == TipoUsuario.user1) {
      // Permisos para user1
    } else if (user.type == TipoUsuario.user2) {
      // Permisos para user2
    }

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() => _scanResults = results);
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() => _isScanning = state);
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    //_refreshTimer?.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    //aqui
    Usuario user = widget.usuario;
    if (user.type == TipoUsuario.admin) {
      // Acciones especiales de admin al hacer scan (si aplica)
    } else if (user.type == TipoUsuario.user1) {
      // ...
    } else if (user.type == TipoUsuario.user2) {
      // ...
    }

    try {
      var withServices = [Guid("180f")]; // Battery Level Service
      _systemDevices = await FlutterBluePlus.systemDevices(withServices);
    } catch (e, backtrace) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
      debugPrint(e.toString());
      debugPrint("backtrace: $backtrace");
    }
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: const [],
        webOptionalServices: [
          Guid("180f"), // battery
          Guid("180a"), // device info
          Guid("1800"), // generic access
          Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e"), // Nordic UART
        ],
      );
    } catch (e, backtrace) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
      debugPrint(e.toString());
      debugPrint("backtrace: $backtrace");
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e, backtrace) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
      debugPrint(e.toString());
      debugPrint("backtrace: $backtrace");
    }
  }

  void onConnectPressed(BluetoothDevice bluetoothDevice, WifiDevice wifiDevice, int index, Dispositivo device, Usuario u) async{
    Dispositivo dev = device;
    bluetoothDevice.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
    });
    // Obtener datos del dispositivo seleccionado
    final dbHelper = DatabaseHelper();
    bool isValid = await dbHelper.validateDevice(device.id, device.address);
    if(isValid){
      int id=device.id;
      final dev = await dbHelper.getDeviceById(id);  //// AQUIIIIIII
    }
    // * Fin obtener datos del dispositivo*//
    // Validacion con datos de bluetooth
    a
    // *Fin validacion bluetooth* //
    // Validacion con datos de wifi
    a
    // *Fin validacion wifi* //

    MaterialPageRoute route = MaterialPageRoute(
      builder: (context) => DeviceScreen(dispositivo: dev, wifiDevice: wifiDevice, bluetoothDevice: bluetoothDevice, usuario: u),
      settings: const RouteSettings(name: '/DeviceScreen'),
    );
    Navigator.of(context).push(route);
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton() {
    return Row(children: [
      if (FlutterBluePlus.isScanningNow)
        buildSpinner()
      else
        ElevatedButton(
          onPressed: onScanPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text("SCAN"),
        ),
      const SizedBox(width: 8),
      if (FlutterBluePlus.isScanningNow)
        TextButton(
          onPressed: onStopPressed,
          child: const Text("DETENER"),
        ),
    ]);
  }

  Widget buildSpinner() {
    return const Padding(
      padding: EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  // ---- NUEVO: modelo para pintar tarjetas combinando system + scan ----
  

  List<_DisplayDevice> _mergeDevices() {
    final Map<String, _DisplayDevice> byId = {};

    // Primero resultados de escaneo (con RSSI)
    for (final sr in _scanResults) {
      final id = sr.device.remoteId.str;
      byId[id] = _DisplayDevice(device: sr.device, rssi: sr.rssi, fromSystem: false);
    }

    // Luego system devices (si no están ya)
    for (final d in _systemDevices) {
      final id = d.remoteId.str;
      byId.putIfAbsent(id, () => _DisplayDevice(device: d, rssi: null, fromSystem: true));
    }

    // Orden: si hay RSSI, ordenar por mayor RSSI; si no, por nombre
    final list = byId.values.toList();
    list.sort((a, b) {
      if (a.rssi != null && b.rssi != null) {
        return b.rssi!.compareTo(a.rssi!);
      } else if (a.rssi != null) {
        return -1;
      } else if (b.rssi != null) {
        return 1;
      } else {
        final an = a.device.platformName.isNotEmpty ? a.device.platformName : a.device.remoteId.str;
        final bn = b.device.platformName.isNotEmpty ? b.device.platformName : b.device.remoteId.str;
        return an.toLowerCase().compareTo(bn.toLowerCase());
      }
    });
    return list;
  }

  // Imagen sugerida según nombre (puedes cambiar por assets si prefieres)
  String _imageForDevice(String name) {
    final n = name.toLowerCase();
    if (n.contains('esp') || n.contains('uart')) {
      return 'https://images.unsplash.com/photo-1518779578993-ec3579fee39f?q=80&w=800&auto=format&fit=crop';
    } else if (n.contains('mi') || n.contains('xiaomi')) {
      return 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=800&auto=format&fit=crop';
    } else if (n.contains('ble') || n.contains('sensor')) {
      return 'https://images.unsplash.com/photo-1581093588401-16ec8a266cd6?q=80&w=800&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=800&auto=format&fit=crop';
  }

  Widget _buildHorizontalCards(List<_DisplayDevice> items) {
    if (items.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No hay dispositivos por ahora.\nPresiona SCAN para buscar.',
          textAlign: TextAlign.center,
        ),
      );
    }




  ///////////////////////////////////////////////// WIFI //////////////////////////////////////////////////
  



  // === onScanPressed (Wi‑Fi + backend) ===
  Future<void> onScanPressedWifi() async {
    final user = widget.usuario;
    // Reglas por rol
    if (user.type == TipoUsuario.admin) {
      // Admin puede ver todos
    } else if (user.type == TipoUsuario.user1) {
      // Si aplica, filtra por planta/área que el backend devuelva
    } else if (user.type == TipoUsuario.user2) {
      // restricciones adicionales si las tienes
    }
    setState(() => _isScanning = true);
    try {
      final list = await widget.backend.scanDevices(timeoutSec: 15);
      final mapped = list.map((j) => WifiDevice.fromJson(j)).toList();
      setState(() => widget._wifiDevices = mapped);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan Wi‑Fi error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
    ///////////////////////////////////******* */
    //aqui
    WifiDevice wifiDevice = widget._wifiDevices[];
    if (user.type == TipoUsuario.admin) {
      // Acciones especiales de admin al hacer scan (si aplica)
    } else if (user.type == TipoUsuario.user1) {
      // ...
    } else if (user.type == TipoUsuario.user2) {
      // ...
    }
    try {
      var withServices = [Guid("180f")]; // Battery Level Service
      _systemDevices = await FlutterBluePlus.systemDevices(withServices);
    } catch (e, backtrace) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
      debugPrint(e.toString());
      debugPrint("backtrace: $backtrace");
    }
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: const [],
        webOptionalServices: [
          Guid("180f"), // battery
          Guid("180a"), // device info
          Guid("1800"), // generic access
          Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e"), // Nordic UART
        ],
      );
    } catch (e, backtrace) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
      debugPrint(e.toString());
      debugPrint("backtrace: $backtrace");
    }
    if (mounted) {
      setState(() {});
    }
  }


  // === onStopPressed (cancelar petición/auto-refresh) ===
  Future<void> onStopPressedWifi() async {
    widget.backend.cancelScan();
    //_refreshTimer?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }


  // === onConnectPressed (ir a detalle y abrir WS opcional) ===
  void onConnectPressedWifi(BluetoothDevice bluetoothDevice, WifiDevice wifiDevice, int index, Dispositivo d, Usuario u) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/DeviceScreenWifi'),
        builder: (_) => DeviceScreen(dispositivo: d, wifiDevice: wifiDevice, bluetoothDevice: bluetoothDevice, usuario: u),
      ),
    );
  }


  // === onRefresh (pull‑to‑refresh) ===
  Future<void> onRefreshWifi() async {
    if (!_isScanning) {
      await onScanPressedWifi();
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }


  @override
  void dispose() {
    //_refreshTimer?.cancel();
    super.dispose();
  }




  /////////////////////////////////////////////////* WIFI *//////////////////////////////////////////////////
























    return SizedBox(
      height: 260,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final dd = items[index];
          final name = dd.device.platformName.isNotEmpty
              ? dd.device.platformName
              : 'Dispositivo ${dd.device.remoteId.str.substring(0, 6)}';
          final idShort = dd.device.remoteId.str;
          final rssiText = dd.rssi != null ? '${dd.rssi} dBm' : (dd.fromSystem ? 'Sistema' : '--');

          return _DeviceCard(
            title: name,
            subtitle: idShort,
            rssi: rssiText,
            imageUrl: _imageForDevice(name),
            onConnect: () => onConnectPressed(dd.device, widget._wifiDevices[index], index, widget.dispositivo, widget.usuario),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Usuario user = widget.usuario;
    final String username = user.name;

    final items = _mergeDevices();

    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find Devices'),
          actions: [
            buildScanButton(),
            const SizedBox(width: 15),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (String value) {
                if (value == 'perfil') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(usuario: user),
                    ),
                  );
                } else if (value == 'configuraciones') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(usuario: user),
                    ),
                  );
                } else if (value == 'logout') {
                  Navigator.pop(context);
                }
              },
              itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'perfil',
                  child: Icon(Icons.person),
                ),
                PopupMenuItem<String>(
                  value: 'configuraciones',
                  child: Icon(Icons.settings),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Icon(Icons.logout),
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '¡Bienvenido!, $username',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              // ---- NUEVA SECCIÓN DE TARJETITAS HORIZONTALES ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Dispositivos cercanos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              _buildHorizontalCards(items),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Widget de Tarjeta Individual ----
class _DeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String rssi;
  final String imageUrl;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.title,
    required this.subtitle,
    required this.rssi,
    required this.imageUrl,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onConnect,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen superior
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.bluetooth, size: 48),
                  ),
                ),
              ),
              // Contenido
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.network_cell, size: 16),
                        const SizedBox(width: 6),
                        Text(rssi),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onConnect,
                        icon: const Icon(Icons.link),
                        label: const Text('Conectar'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
