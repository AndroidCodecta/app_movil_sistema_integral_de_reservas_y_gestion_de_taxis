import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
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

  // Faster save: persist token and userId first (awaited) so UI can proceed.
  // Then write larger payloads (user, reservas, solicitudes) in background
  // without blocking the caller.
  static Future<void> saveSessionFast({
    required String token,
    required int userId,
    Map<String, dynamic>? user,
    List<dynamic>? reservas,
    List<dynamic>? solicitudes,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Persist minimal auth info synchronously
    await prefs.setString("auth_token", token);
    await prefs.setInt("user_id", userId);

    // Schedule background writes for potentially large payloads.
    // Mark intentionally unawaited so the analyzer doesn't warn.
    // ignore: unawaited_futures
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
      } catch (_) {
        // ignore background write errors
      }
    });
  }

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

      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (decoded is Map) {
        if (decoded['data'] is List) {
          return (decoded['data'] as List)
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        for (final key in ['reservas', 'solicitudes', 'items', 'results']) {
          if (decoded[key] is List) {
            return (decoded[key] as List)
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        if (decoded['data'] is Map) {
          final inner = decoded['data'] as Map;
          for (final v in inner.values) {
            if (v is List) {
              return v
                  .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e),
                  )
                  .toList();
            }
          }
        }

        // No list found: wrap the map as a single item list
        return [Map<String, dynamic>.from(decoded)];
      }
    } catch (_) {
      // fall through and return empty list on decode errors
    }

    return [];
  }

  //Estado del chofer

  static Future<void> setEstadoChofer(bool activo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("chofer_activo", activo);
  }

  static Future<bool?> getEstadoChofer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("chofer_activo");
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  //falta la clase para mantener sesion iniciada ( check para recordar sesion)
}
