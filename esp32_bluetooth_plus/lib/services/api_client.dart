import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';



/// Ajusta tu base URL aquí o lee de un .env/const
class Env {
  static const apiBase = 'https://api.local';
}



/// Modelo: Dispositivo
class Device {
  final String id;
  final String serial;
  final String mac;
  final String type;
  final String station;
  final String status;
  final String fwVersion;


  Device({
  required this.id,
  required this.serial,
  required this.mac,
  required this.type,
  required this.station,
  required this.status,
  required this.fwVersion,
  });


  factory Device.fromJson(Map<String, dynamic> j) => Device(
  id: j['id'] as String,
  serial: j['serial'] as String,
  mac: j['mac'] as String,
  type: j['type'] as String,
  station: j['station'] as String,
  status: j['status'] as String,
  fwVersion: (j['fw_version'] ?? j['fwVersion'] ?? '') as String,
  );
}




/// Respuesta de comando
class CommandResponse {
  final String id;
  final String status; // pending|ack|done|error
  CommandResponse({required this.id, required this.status});
  factory CommandResponse.fromJson(Map<String, dynamic> j) => CommandResponse(
  id: j['id'] as String,
  status: (j['status'] ?? 'pending') as String,
  );
}


/// Excepción amigable
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}




/// Cliente API (singleton)
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBase,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );


    // Permitir logs útiles en debug
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }


    final adapter = _dio.httpClientAdapter as IOHttpClientAdapter;
    adapter.createHttpClient = () {
      final client = HttpClient();
      // ⚠️ Solo en entornos internos o de prueba
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host == Uri.parse(Env.apiBase).host; // aceptar solo tu host interno
      };
      return client;
    };
  }


  static final ApiClient I = ApiClient._internal();
  late final Dio _dio;
  String? _accessToken;


  /// Setter opcional por si cambias baseUrl en runtime
  void setBaseUrl(String url) => _dio.options.baseUrl = url;


  /// Guarda token (lo usa el interceptor)
  void _setToken(String? token) {
    _accessToken = token;
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }



  /// Login → obtiene y guarda JWT
  Future<String> login({required String username, required String password}) async {
    try {
      final r = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
    });
    final token = (r.data is Map) ? r.data['access'] as String : null;
    if (token == null) throw ApiException('Token inválido en respuesta');
    _setToken(token);
    return token;
    } on DioError catch (e) {
      throw _toApiException(e, fallback: 'Error al iniciar sesión');
    }
  }

  /// Lista de dispositivos
  Future<List<Device>> listDevices() async {
    try {
      final r = await _dio.get('/devices');
      final data = r.data as List<dynamic>;
      return data.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
    } on DioError catch (e) {
      throw _toApiException(e, fallback: 'No se pudo obtener dispositivos');
    }
  }

  /// Detalle de un dispositivo
  Future<Device> getDevice(String deviceId) async {
    try {
      final r = await _dio.get('/devices/$deviceId');
      return Device.fromJson(r.data as Map<String, dynamic>);
    } on DioError catch (e) {
      throw _toApiException(e, fallback: 'No se pudo obtener el dispositivo');
    }
  }


  /// Enviar comando a un dispositivo
  /// command: ej. 'set_output' | 'set_threshold' | 'ota'
  /// params: cualquier mapa con parámetros de tu comando
  Future<CommandResponse> sendCommand({
    required String deviceId,
    required String command,
    Map<String, dynamic> params = const {},
    int? ttlMs,
  }) async {
    try {
      final body = {
        'command': command,
        'params_json': params,
        if (ttlMs != null) 'ttl_ms': ttlMs,
      };
      final r = await _dio.post('/devices/$deviceId/command', data: body);
      return CommandResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioError catch (e) {
      throw _toApiException(e, fallback: 'No se pudo enviar el comando');
    }
  }

  /// (Opcional) Helper para cambiar token, por ejemplo, después de re‑login
  void setTokenManually(String token) => _setToken(token);



  /// Mapea errores de Dio a ApiException legibles
  ApiException _toApiException(DioError e, {String? fallback}) {
    final sc = e.response?.statusCode;
    String msg;
    if (e.type == DioErrorType.connectionTimeout || e.type == DioErrorType.receiveTimeout) {
      msg = 'Tiempo de espera agotado';
    } else if (e.type == DioErrorType.connectionError) {
      msg = 'Sin conexión con el servidor';
    } else if (sc == 401) {
      msg = 'No autorizado (401)';
    } else if (sc == 403) {
      msg = 'Acceso prohibido (403)';
    } else if (sc == 404) {
      msg = 'Recurso no encontrado (404)';
    } else {
      msg = fallback ?? 'Error en la petición';
    }
    return ApiException(msg, statusCode: sc);
  }


}












































class BackendClient {
  final String baseUrl; // ej. http://10.10.10.50:8000
  final String? bearerToken; // JWT si aplican roles
  http.Client? _client;
  bool _cancelScan = false; // bandera de cancelación


  BackendClient(this.baseUrl, {this.bearerToken});


  http.Client _ensure() => _client ??= http.Client();


  Map<String, String> get _headers => {
  'Content-Type': 'application/json',
  if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
  };


  /// Simula un "scan": consulta al backend por dispositivos vivos en los últimos N segundos
  Future<List<Map<String, dynamic>>> scanDevices({int timeoutSec = 15}) async {
  _cancelScan = false;
  final uri = Uri.parse('$baseUrl/devices/scan?alive_seconds=$timeoutSec');
  final resp = await _ensure().get(uri, headers: _headers).timeout(
  Duration(seconds: timeoutSec),
  onTimeout: () => http.Response('[]', 200),
  );
  if (_cancelScan) return [];
  if (resp.statusCode != 200) {
  throw Exception('Scan HTTP ${resp.statusCode}: ${resp.body}');
  }
  final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
  return list;
  }


  void cancelScan() { _cancelScan = true; }


  Future<void> sendCommand(String deviceId, Map<String, dynamic> cmd) async {
  final uri = Uri.parse('$baseUrl/devices/$deviceId/command');
  final resp = await _ensure().post(uri, headers: _headers, body: jsonEncode(cmd));
  if (resp.statusCode != 200) {
  throw Exception('Command HTTP ${resp.statusCode}: ${resp.body}');
  }
  }


  Stream<String> deviceTelemetryStream(String deviceId) {
  // WebSocket en ws://host:port/ws/devices/{id}
  final scheme = baseUrl.startsWith('https') ? 'wss' : 'ws';
  final wsUrl = baseUrl.replaceFirst(RegExp(r'^https?'), scheme) + '/ws/devices/$deviceId';
  // Uso de web_socket_channel directamente en la pantalla de detalle (ver DeviceScreenWifi)
  throw UnimplementedError('Crear canal en la UI para controlar ciclo de vida.');
  }


  void dispose() {
  _client?.close();
  _client = null;
  }
}