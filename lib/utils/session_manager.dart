import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

enum TripStatus {
  ASSIGNED_TO_DRIVER,
  APPROACHING_PICKUP,
  ARRIVED_PICKUP,
  IN_TRANSIT,
  TRIP_FINISHED,
}

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

  static Future<void> saveSessionFast({
    required String token,
    required int userId,
    Map<String, dynamic>? user,
    List<dynamic>? reservas,
    List<dynamic>? solicitudes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
    await prefs.setInt("user_id", userId);
    Future(() async {
      try {
        if (user != null) await prefs.setString("user", jsonEncode(user));
        if (reservas != null)
          await prefs.setString("reservas_dia", jsonEncode(reservas));
        if (solicitudes != null)
          await prefs.setString("solicitudes", jsonEncode(solicitudes));
      } catch (_) {}
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
    return userJson == null ? null : jsonDecode(userJson);
  }

  static Future<String?> getUserDni() async {
    final user = await getUser();
    return user?['dni']?.toString();
  }

  static Future<List<Map<String, dynamic>>> getReservas() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("reservas_dia");
    return jsonStr == null ? [] : _decodeJsonToList(jsonStr);
  }

  static Future<List<Map<String, dynamic>>> getSolicitudes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("solicitudes");
    return jsonStr == null ? [] : _decodeJsonToList(jsonStr);
  }

  static List<Map<String, dynamic>> _decodeJsonToList(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      Map<String, dynamic> normalize(Map input) => Map<String, dynamic>.from(
        input.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (decoded is List)
        return decoded
            .map((e) => normalize(e as Map))
            .cast<Map<String, dynamic>>()
            .toList();
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((e) => normalize(e as Map))
            .cast<Map<String, dynamic>>()
            .toList();
      }
      for (final key in ['reservas', 'solicitudes', 'items', 'results']) {
        if (decoded[key] is List) {
          return (decoded[key] as List)
              .map((e) => normalize(e as Map))
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error decodificando JSON: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchReservasFromApi() async {
    final token = await getToken();
    final idUser = await getUserId();
    if (token == null || idUser == null)
      throw Exception('Faltan datos del chofer');

    final response = await http.post(
      Uri.parse('http://servidorcorman.dyndns.org:7019/api/chofer/reservas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"id_user": idUser}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['reservas']?['data'] is List) {
        final reservas = List<Map<String, dynamic>>.from(
          data['reservas']['data'],
        );
        await _saveReservas(reservas);
        return reservas;
      }
    }
    throw Exception('Error al cargar reservas');
  }

  static Future<void> _saveReservas(List<Map<String, dynamic>> reservas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("reservas_dia", jsonEncode(reservas));
  }

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

  static Future<bool> isTripActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('trip_active') == true;
  }

  static Future<TripStatus> getCurrentTripPhase() async {
    final prefs = await SharedPreferences.getInstance();
    final index =
        prefs.getInt('trip_current_phase') ??
            TripStatus.ASSIGNED_TO_DRIVER.index;
    return TripStatus.values[index.clamp(0, TripStatus.values.length - 1)];
  }

  static Future<void> startTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool('trip_active', true);
    await prefs.setInt(
      'trip_current_phase',
      TripStatus.ASSIGNED_TO_DRIVER.index,
    );
    await prefs.setString('trip_assigned_time', now.toIso8601String());
    await prefs.setString('trip_phase_start_time', now.toIso8601String());

    await prefs.remove('trip_arrived_time');
    await prefs.remove('trip_started_transit_time');
    await prefs.remove('trip_finished_time');
  }

  static Future<void> updateTripPhase(TripStatus newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final currentIndex =
        prefs.getInt('trip_current_phase') ??
            TripStatus.ASSIGNED_TO_DRIVER.index;

    if (newStatus.index < currentIndex) return;

    final now = DateTime.now();

    if (newStatus == TripStatus.APPROACHING_PICKUP) {
      await prefs.setString('trip_approach_start_time', now.toIso8601String());
    } else if (newStatus == TripStatus.ARRIVED_PICKUP) {
      await prefs.setString('trip_arrived_time', now.toIso8601String());
    } else if (newStatus == TripStatus.IN_TRANSIT) {
      await prefs.setString('trip_started_transit_time', now.toIso8601String());
    } else if (newStatus == TripStatus.TRIP_FINISHED) {
      await prefs.setString('trip_finished_time', now.toIso8601String());
    }

    await prefs.setString('trip_phase_start_time', now.toIso8601String());
    await prefs.setInt('trip_current_phase', newStatus.index);
  }

  static Future<void> endTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('trip_active'),
      prefs.remove('trip_current_phase'),
      prefs.remove('trip_phase_start_time'),
      prefs.remove('trip_assigned_time'),
      prefs.remove('trip_approach_start_time'),
      prefs.remove('trip_arrived_time'),
      prefs.remove('trip_started_transit_time'),
      prefs.remove('trip_finished_time'),
    ]);
  }

  static Future<DateTime?> getTripTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(key);
    return str == null ? null : DateTime.parse(str);
  }

  static Future<Duration> getCurrentPhaseDuration() async {
    final start = await getTripTime('trip_phase_start_time');
    return start == null ? Duration.zero : DateTime.now().difference(start);
  }

  static Future<Duration> getApproachDuration() async {
    final approachStart = await getTripTime('trip_approach_start_time');
    final arrived = await getTripTime('trip_arrived_time');
    if (approachStart == null) return Duration.zero;

    return (arrived ?? DateTime.now()).difference(approachStart);
  }

  static Future<Duration> getWaitPickupDuration() async {
    final arrived = await getTripTime('trip_arrived_time');
    final started = await getTripTime('trip_started_transit_time');
    if (arrived == null) return Duration.zero;

    return (started ?? DateTime.now()).difference(arrived);
  }

  static Future<Duration> getTravelDuration() async {
    final started = await getTripTime('trip_started_transit_time');
    final finished = await getTripTime('trip_finished_time');

    if (started == null) return Duration.zero;

    return (finished ?? DateTime.now()).difference(started);
  }
}