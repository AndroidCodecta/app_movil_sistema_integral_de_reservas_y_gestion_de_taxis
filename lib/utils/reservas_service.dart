// Archivo: 'utils/reservas_service.dart'

import 'dart:convert';
import 'package:http/http.dart' as http;
// Asegúrate de que la ruta a SessionManager es correcta
import 'session_manager.dart';

class ReservasService {
  // Constante de la URL base
  static const String BASE_URL = 'http://servidorcorman.dyndns.org:7019/api';

  // Función interna para realizar la petición POST con autenticación
  static Future<Map<String, dynamic>?> _performPost(
    String endpoint, {
    int? reservaId,
  }) async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      print("Error Service: Token o User ID no disponible.");
      return null;
    }

    final url = Uri.parse('$BASE_URL/$endpoint');
    final body = {"id_user": idUser};

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error del servidor (${response.statusCode}) en $endpoint.');
        return null;
      }
    } catch (e) {
      print("Excepción al cargar $endpoint: $e");
      return null;
    }
  }

  // ============================================================
  // 1. OBTENER LA LISTA COMPLETA (Endpoint: /chofer/reservas)
  // ============================================================
  static Future<List<Map<String, dynamic>>> fetchReservasList() async {
    final jsonData = await _performPost('chofer/reservas');

    if (jsonData != null &&
        jsonData['status'] == 'success' &&
        jsonData['reservas'] != null &&
        jsonData['reservas']['data'] is List) {
      return List<Map<String, dynamic>>.from(jsonData['reservas']['data']);
    } else {
      return [];
    }
  }

  // ============================================================
  // 2. OBTENER RESERVAS DEL DÍA (Endpoint: /chofer/reservas_dia)
  // ============================================================
  static Future<List<Map<String, dynamic>>> fetchReservasDia() async {
    final jsonData = await _performPost('chofer/reservas_dia');

    if (jsonData != null &&
        jsonData['success'] == true &&
        jsonData['reservas_dia'] != null &&
        jsonData['reservas_dia']['data'] is List) {
      return List<Map<String, dynamic>>.from(jsonData['reservas_dia']['data']);
    } else {
      return [];
    }
  }

  // --- 3. OBTENER EL DETALLE COMPLETO DE LA RESERVA ---
  // Retorna un Map<String, dynamic> con todos los datos del detalle
  static Future<Map<String, dynamic>?> fetchReservaDetalle(
    int reservaId,
  ) async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      return null;
    }

    // URL: /api/reservas_detalle/{id}
    final url = Uri.parse('$BASE_URL/chofer/reservas_detalle/$reservaId');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"id_user": idUser}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          // Retorna el objeto 'data'
          return responseData['data'] as Map<String, dynamic>;
        } else {
          return null;
        }
      } else {
        print(
          "Error HTTP ${response.statusCode}: Fallo al cargar el detalle de la reserva $reservaId.",
        );
        return null;
      }
    } catch (e) {
      print(
        "Excepción al realizar la llamada HTTP para detalle de reserva: $e",
      );
      return null;
    }
  }

  // ============================================================
  // 4. OBTENER LA LISTA COMPLETA DE HISTORIAL
  // ============================================================
  static Future<List<Map<String, dynamic>>> fetchReservasHistorial() async {
    final jsonData = await _performPost('chofer/reservas_aceptadas');

    if (jsonData != null &&
        jsonData['status'] == 'success' &&
        jsonData['reservas_aceptadas'] != null &&
        jsonData['reservas_aceptadas']['data'] is List) {
      return List<Map<String, dynamic>>.from(
        jsonData['reservas_aceptadas']['data'],
      );
    } else {
      return [];
    }
  }
}
