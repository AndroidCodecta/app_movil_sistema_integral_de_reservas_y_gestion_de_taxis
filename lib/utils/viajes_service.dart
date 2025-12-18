import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class ViajesService {
  static const String _baseUrl = "http://servidorcorman.dyndns.org:7019/api";

  // Método genérico para seguimiento (confirmar llegada, iniciar, finalizar)
  static Future<bool> _realizarPeticion({
    required int reservaId,
    Map<String, dynamic>? dataAdicional,
  }) async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      print("Error: Token o Usuario no encontrados en sesión.");
      return false;
    }

    final url = Uri.parse("$_baseUrl/chofer/reserva/seguimiento/$reservaId");

    final Map<String, dynamic> body = {"id_user": idUser};
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

      print(
        "Respuesta API para seguimiento/$reservaId: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse["status"] == "success" ||
            jsonResponse["success"] == true;
      }

      print("Error Servidor: ${response.statusCode} - ${response.body}");
      return false;
    } catch (e) {
      print("Excepción en ViajesService: $e");
      return false;
    }
  }

  static Future<bool> confirmarLlegada(int reservaId) async {
    return _realizarPeticion(reservaId: reservaId);
  }

  static Future<bool> iniciarViaje(int reservaId, String tiempoEspera) async {
    return _realizarPeticion(
      reservaId: reservaId,
      dataAdicional: {"tiempo_espera": tiempoEspera},
    );
  }

  static Future<bool> finalizarViaje(int reservaId, String tiempoViaje) async {
    return _realizarPeticion(
      reservaId: reservaId,
      dataAdicional: {"tiempo_viaje": tiempoViaje},
    );
  }

  // Registro de pago adicional
  static Future<bool> registrarPagoAdicional({
    required int reservaId,
    required int statusPago,
    required String metodo,
    String observacion = "Sin observaciones",
  }) async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      print("Error: Token o Usuario no encontrados.");
      return false;
    }

    final url = Uri.parse("$_baseUrl/chofer/reserva/pago_adicional/$reservaId");
    String fechaActual = DateTime.now().toString().substring(0, 19);

    final Map<String, dynamic> body = {
      "id_user": idUser,
      "status_pago": statusPago,
      "fecha_pago": fechaActual,
      "metodo": metodo,
      "observacion": observacion,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      print(
        "Respuesta API para pago_adicional/$reservaId: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      if (response.body.isNotEmpty) {
        try {
          final jsonResponse = jsonDecode(response.body);
          if ((jsonResponse['message'] ?? '').toString().contains(
            "registrado con éxito",
          )) {
            return true;
          }
        } catch (e) {}
      }
      print("Error pago: ${response.statusCode} - ${response.body}");
      return false;
    } catch (e) {
      print("Excepción Pago: $e");
      return false;
    }
  }

  // Obtener reserva en curso
  static Future<Map<String, dynamic>?> getReservaEnCurso() async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      print("Error: Token o Usuario no encontrados.");
      return null;
    }

    final url = Uri.parse("$_baseUrl/chofer/reserva_en_curso");

    final body = jsonEncode({"id_user": idUser});

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: body,
      );

      print(
        "Respuesta API para reserva_en_curso: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse["success"] == true &&
            jsonResponse.containsKey("seguimiento")) {
          return jsonResponse;
        }
        // Si dice "Sin viaje iniciado" o no hay seguimiento
        return null;
      }
      print(
        "Error reserva_en_curso: ${response.statusCode} - ${response.body}",
      );
      return null;
    } catch (e) {
      print("Excepción getReservaEnCurso: $e");
      return null;
    }
  }
}
