import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class ViajesService {
  static const String _baseUrl = "http://servidorcorman.dyndns.org:7019/api";

  static Future<bool> _realizarPeticion({
    required int reservaId,
    Map<String, dynamic>? dataAdicional,
  }) async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      return false;
    }

    final url = Uri.parse("$_baseUrl/chofer/reserva/seguimiento/$reservaId");

    final Map<String, dynamic> body = {
      "id_user": idUser,
    };

    if (dataAdicional != null) {
      body.addAll(dataAdicional);
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse["status"] == "success" ||
            jsonResponse["success"] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> confirmarLlegada(int reservaId) async {
    return _realizarPeticion(reservaId: reservaId);
  }

  static Future<bool> iniciarViaje(
      int reservaId, String tiempoEsperaFormatted) async {
    return _realizarPeticion(
      reservaId: reservaId,
      dataAdicional: {
        "tiempo_espera": tiempoEsperaFormatted,
      },
    );
  }

  static Future<bool> finalizarViaje(
      int reservaId, String tiempoViajeFormatted) async {
    return _realizarPeticion(
      reservaId: reservaId,
      dataAdicional: {
        "tiempo_viaje": tiempoViajeFormatted,
      },
    );
  }
}