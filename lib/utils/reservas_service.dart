import 'dart:convert';
import 'package:http/http.dart' as http;
// Importa SessionManager para obtener Token/ID
import 'session_manager.dart';

class ReservasService {
  // Constante de la URL base
  static const String BASE_URL = 'http://servidorcorman.dyndns.org:7019/api';

  // --- 1. OBTENER LA LISTA DE RESERVAS ---
  // Retorna una lista de Map<String, dynamic>
  static Future<List<Map<String, dynamic>>> fetchReservasList() async {
    final token = await SessionManager.getToken();
    final idUser = await SessionManager.getUserId();

    if (token == null || idUser == null) {
      print("Error Service: Token o User ID no disponible.");
      // Devolvemos una lista vacía en lugar de lanzar una excepción para que la app no crashee.
      return [];
    }

    final url = Uri.parse('$BASE_URL/chofer/reservas');
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
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success' &&
            jsonData['reservas'] != null &&
            jsonData['reservas']['data'] is List) {
          // EXTRACCIÓN CORRECTA: Retorna el array 'data'
          return List<Map<String, dynamic>>.from(jsonData['reservas']['data']);
        } else {
          print('API Error: Formato de datos inesperado o sin éxito.');
          return [];
        }
      } else {
        print('Error del servidor (${response.statusCode}) al cargar lista.');
        return [];
      }
    } catch (e) {
      print("Excepción al cargar la lista de reservas: $e");
      return [];
    }
  }

  // --- 2. OBTENER EL DETALLE COMPLETO DE LA RESERVA ---
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
    final url = Uri.parse('$BASE_URL/reservas_detalle/$reservaId');

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
}
