import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class ReservasService {
  static const String BASE_URL = 'http://servidorcorman.dyndns.org:7019/api';

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

  static Future<Map<String, dynamic>?> fetchReservaDetalle(
      int reservaId,
      ) async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      return null;
    }

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

  static Future<List<Map<String, dynamic>>> fetchReservasHistorial() async {
    final jsonData = await _performPost('chofer/reservas_historial');

    if (jsonData != null &&
        jsonData['success'] == true &&
        jsonData['reservas_historial'] != null &&
        jsonData['reservas_historial']['data'] is List) {

      return List<Map<String, dynamic>>.from(
        jsonData['reservas_historial']['data'],
      );

    } else {
      return [];
    }
  }
}