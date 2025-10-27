import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SessionManager {
  // ===== GUARDAR SESIÓN =====
  static Future<void> saveSession({
    required String token,
    required int userId,
    Map<String, dynamic>? user,
    List<dynamic>? reservas,
    List<dynamic>? solicitudes,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("auth_token", token);
    await prefs.setInt("user_id", userId);

    if (user != null) {
      await prefs.setString("user", jsonEncode(user));
    }
    if (reservas != null) {
      await prefs.setString("reservas_dia", jsonEncode(reservas));
    }
    if (solicitudes != null) {
      await prefs.setString("solicitudes", jsonEncode(solicitudes));
    }
  }

  // ===== GUARDADO RÁPIDO (no bloqueante) =====
  static Future<void> saveSessionFast({
    required String token,
    required int userId,
    Map<String, dynamic>? user,
    List<dynamic>? reservas,
    List<dynamic>? solicitudes,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("auth_token", token);
    await prefs.setInt("user_id", userId);

    Future(() async {
      try {
        if (user != null) {
          await prefs.setString("user", jsonEncode(user));
        }
        if (reservas != null) {
          await prefs.setString("reservas_dia", jsonEncode(reservas));
        }
        if (solicitudes != null) {
          await prefs.setString("solicitudes", jsonEncode(solicitudes));
        }
      } catch (_) {}
    });
  }

  // ===== GETTERS BÁSICOS =====
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id");
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("user");
    if (userJson == null) return null;
    return jsonDecode(userJson);
  }

  static Future<String?> getUserDni() async {
    final user = await getUser();
    return user?['dni']?.toString();
  }

  // ===== LECTURA DE DATOS GUARDADOS =====
  static Future<List<Map<String, dynamic>>> getReservas() async {
    final prefs = await SharedPreferences.getInstance();
    final reservasJson = prefs.getString("reservas_dia");
    if (reservasJson == null) return [];
    return _decodeJsonToList(reservasJson);
  }

  static Future<List<Map<String, dynamic>>> getSolicitudes() async {
    final prefs = await SharedPreferences.getInstance();
    final solicitudesJson = prefs.getString("solicitudes");
    if (solicitudesJson == null) return [];
    return _decodeJsonToList(solicitudesJson);
  }

  static List<Map<String, dynamic>> _decodeJsonToList(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);

      Map<String, dynamic> _normalizeMap(Map input) {
        return Map<String, dynamic>.from(
          input.map((k, v) => MapEntry(k.toString(), v)),
        );
      }

      if (decoded is List) {
        return decoded.map<Map<String, dynamic>>((e) => _normalizeMap(e)).toList();
      }

      if (decoded is Map) {
        if (decoded['data'] is List) {
          return (decoded['data'] as List)
              .map<Map<String, dynamic>>((e) => _normalizeMap(e))
              .toList();
        }

        for (final key in ['reservas', 'solicitudes', 'items', 'results']) {
          if (decoded[key] is List) {
            return (decoded[key] as List)
                .map<Map<String, dynamic>>((e) => _normalizeMap(e))
                .toList();
          }
        }

        if (decoded['data'] is Map) {
          final inner = decoded['data'] as Map;
          for (final v in inner.values) {
            if (v is List) {
              return v.map<Map<String, dynamic>>((e) => _normalizeMap(e)).toList();
            }
          }
        }

        return [_normalizeMap(decoded)];
      }
    } catch (e) {
      print('Error al decodificar JSON: $e');
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchReservasFromApi() async {
    final token = await getToken();
    final idUser = await getUserId();

    if (token == null || idUser == null) {
      throw Exception('Faltan datos del chofer (token o id)');
    }

    final url = Uri.parse('http://servidorcorman.dyndns.org:7019/api/chofer/reservas');
    final body = {"id_user": idUser};

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'success' &&
          jsonData['reservas'] != null &&
          jsonData['reservas']['data'] is List) {
        final reservas = List<Map<String, dynamic>>.from(jsonData['reservas']['data']);
        await _saveReservas(reservas);
        return reservas;
      } else {
        throw Exception('Formato de datos inesperado o sin éxito');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    } else {
      throw Exception('Error del servidor (${response.statusCode})');
    }
  }

  static Future<void> _saveReservas(List<Map<String, dynamic>> reservas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("reservas_dia", jsonEncode(reservas));
  }

  // ===== ESTADO DEL CHOFER =====
  static Future<void> setEstadoChofer(bool activo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("chofer_activo", activo);
  }

  static Future<bool?> getEstadoChofer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("chofer_activo");
  }

  // ===== LIMPIAR SESIÓN =====
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
