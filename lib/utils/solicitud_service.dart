import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SolicitudService {
  static const String _baseUrl = "http://servidorcorman.dyndns.org:7019/api";

  static Future<Map<String, dynamic>> responderSolicitud({
    required int solicitudChoferId,
    required int estado, // 0 = declinar, 1 = aceptar
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final idUser = prefs.getInt("user_id");

    if (token == null || idUser == null) {
      throw Exception("Faltan datos de sesión (token o user_id)");
    }

    final url = Uri.parse(
      "$_baseUrl/reservas/chofer/asignacion/$solicitudChoferId",
    );

    final body = jsonEncode({
      "id_user": idUser,
      "solicitud_chofer_id": solicitudChoferId,
      "estado": estado,
    });

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "success") {
        return data["data"];
      } else {
        throw Exception("Error lógico: ${data["status"]}");
      }
    } else if (response.statusCode == 404) {
      throw Exception("Usuario no encontrado (404)");
    } else if (response.statusCode == 500) {
      throw Exception("Error del servidor (500)");
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }

  static Future<List<dynamic>> listarSolicitudes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final idUser = prefs.getInt("user_id"); // Recuperamos el ID del usuario

    if (token == null || idUser == null) {
      throw Exception("Faltan datos de sesión (token o user_id)");
    }

    final url = Uri.parse("$_baseUrl/chofer/reservas_solicitudes");

    // CAMBIO IMPORTANTE: Ahora es POST y enviamos el body
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "id_user": idUser, // Enviamos el ID como pide tu API
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);

      // CAMBIO DE ESTRUCTURA:
      // Tu API devuelve: { "success": true, "reservas_solicitudes": { "data": [...] } }
      if (responseBody['success'] == true &&
          responseBody['reservas_solicitudes'] != null) {
        // Entramos a 'reservas_solicitudes' y luego a 'data'
        return responseBody['reservas_solicitudes']['data'] ?? [];
      } else {
        return []; // Si no hay éxito o datos, retornamos lista vacía
      }
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }
}
