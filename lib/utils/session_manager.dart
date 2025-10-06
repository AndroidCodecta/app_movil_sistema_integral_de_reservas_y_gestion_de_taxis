import 'dart:convert';
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
    final decoded = jsonDecode(reservasJson);
    if (decoded is List) {
      return decoded
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getSolicitudes() async {
    final prefs = await SharedPreferences.getInstance();
    final solicitudesJson = prefs.getString("solicitudes");
    if (solicitudesJson == null) return [];
    final decoded = jsonDecode(solicitudesJson);
    if (decoded is List) {
      return decoded
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  // static Future<void> clearSession() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  // }
  
  //falta la clase para mantener sesion iniciada ( check para recordar sesion)
}
