import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/src/typed_buffer.dart';
import 'package:uuid/uuid.dart';

/// Configuración general (ajusta a tu entorno interno)
class Env {
  static const mqttHost = 'wss://api.local'; // O tu dominio interno
  static const mqttPort = 8084;              // Puerto WSS
  static const mqttUser = 'admin';           // Si tienes auth en EMQX
  static const mqttPass = 'admin123';
}

/// Singleton para manejar conexión MQTT
class MqttService {
  MqttService._();
  static final MqttService I = MqttService._();

  late final MqttServerClient _client = MqttServerClient.withPort(
    Env.mqttHost,
    'flutter-${const Uuid().v4()}',
    Env.mqttPort,
  )
    ..useWebSocket = true
    ..secure = true
    ..keepAlivePeriod = 30
    ..logging(on: false);

  bool get connected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  /// Conecta al broker
  Future<void> connect({String? username, String? password}) async {
    final msg = MqttConnectMessage()
        .withClientIdentifier('flutter-${const Uuid().v4()}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client.connectionMessage = msg;
    final res = await _client.connect(
      username ?? Env.mqttUser,
      password ?? Env.mqttPass,
    );
    if (res?.state != MqttConnectionState.connected) {
      throw Exception('Error al conectar MQTT: ${res?.state}');
    }
    print('✅ MQTT conectado');
  }

  /// Suscribirse a telemetría de un dispositivo
  Stream<Map<String, dynamic>> subscribeTelemetry(String deviceId) {
    final topic = 'plant/+/+/+/$deviceId/telemetry';
    _client.subscribe(topic, MqttQos.atLeastOnce);
    return _client.updates!.map((event) {
      final msg = event.first.payload as MqttPublishMessage;
      final payload =
          utf8.decode(msg.payload.message); // decodifica a texto JSON
      try {
        return json.decode(payload) as Map<String, dynamic>;
      } catch (_) {
        return {'raw': payload};
      }
    });
  }

  /// Publicar un comando hacia un dispositivo
  Future<void> publishCommand(String deviceId, Map<String, dynamic> payload) async {
    final topic = 'plant/commands/$deviceId';
    final data = json.encode(payload);
    _client.publishMessage(topic, MqttQos.atLeastOnce, utf8.encode(data) as Uint8Buffer);
  }

  /// Desconectar limpiamente
  Future<void> disconnect() async {
    if (connected) {
      await _client.disconnect();
      print('MQTT desconectado');
    }
  }
}
