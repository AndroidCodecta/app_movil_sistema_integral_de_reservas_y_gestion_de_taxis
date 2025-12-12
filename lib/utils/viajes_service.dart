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
      print("Error: Token o Usuario no encontrados en sesión.");
      return false;
    }

    // Construcción de la URL: .../api/chofer/reserva/seguimiento/{id_reserva}
    final url = Uri.parse("$_baseUrl/chofer/reserva/seguimiento/$reservaId");

    // Construcción del Body base: { "id_user": "..." }
    final Map<String, dynamic> body = {
      "id_user": idUser,
    };

    // Si hay datos extra (como tiempo de viaje), se agregan al body
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        // Validar respuesta exitosa según la estructura de tu backend
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
      dataAdicional: {
        "tiempo_espera": tiempoEspera,
      },
    );
  }

  // POST: Body con { "id_user": ..., "tiempo_viaje": ... }
  static Future<bool> finalizarViaje(int reservaId) async {
    return _realizarPeticion(
      reservaId: reservaId,
      // No enviamos dataAdicional.
    );
  }
  // --- NUEVO MÉTODO PARA PAGO ADICIONAL (Post-Pago) ---
  static Future<bool> registrarPagoAdicional({
    required int reservaId,
    required int statusPago, // 1 = Pagado, 0 = No pagado
    required String metodo,  // "Yape", "PLIN", "Efectivo"
    String observacion = "Sin observaciones",
  }) async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      print("Error: Token o Usuario no encontrados.");
      return false;
    }

    // URL: .../api/chofer/reserva/pago_adicional/{id_reserva}
    final url = Uri.parse("$_baseUrl/chofer/reserva/pago_adicional/$reservaId");

    // Generar Fecha Actual formato: "YYYY-MM-DD HH:mm:ss"
    // DateTime.now().toString() devuelve algo como "2025-11-11 00:00:00.123456"
    // Usamos substring(0, 19) para quedarnos con los segundos.
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        // Validar éxito según tu backend
        return jsonResponse["status"] == "success" ||
            jsonResponse["success"] == true;
      }

      print("Error Pago (${response.statusCode}): ${response.body}");
      return false;
    } catch (e) {
      print("Excepción Pago: $e");
      return false;
    }
  }
}