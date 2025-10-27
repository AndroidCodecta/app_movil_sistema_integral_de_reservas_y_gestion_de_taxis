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

    final url = Uri.parse("$_baseUrl/reservas/chofer/asignacion/$solicitudChoferId");

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

}
