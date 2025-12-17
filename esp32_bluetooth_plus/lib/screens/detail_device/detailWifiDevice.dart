// models/wifi_device.dart


class WifiDevice {
  final String id; // uuid del equipo
  final String name; // nombre amigable
  final String ip; // ip local o hostname
  final String mac; // mac reportada por el esp32
  final int? battery; // % opcional
  final DateTime lastSeen;


  WifiDevice({
  required this.id,
  required this.name,
  required this.ip,
  required this.mac,
  required this.lastSeen,
  this.battery,
  });


  factory WifiDevice.fromJson(Map<String, dynamic> j) => WifiDevice(
  id: j['id'],
  name: j['name'] ?? 'ESP32',
  ip: j['ip'],
  mac: j['mac'],
  battery: j['battery'],
  lastSeen: DateTime.parse(j['last_seen']),
  );
}