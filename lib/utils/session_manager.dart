import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ====================== ENUM PARA FASES DEL VIAJE (CORREGIDO) ======================
// ESTOS CUATRO VALORES DEBEN ESTAR PRESENTES
enum TripStatus {
  ASSIGNED_TO_DRIVER, // 0 - El viaje está asignado, pendiente de 'Iniciar Viaje'.
  APPROACHING_PICKUP, // 1 - Chofer en ruta a la dirección de recojo. (Empieza al pulsar Iniciar Viaje)
  ARRIVED_PICKUP, // 2 - Llegó al punto de encuentro. (Inicia contador de Espera - Amarillo)
  IN_TRANSIT, // 3 - Cliente arriba, yendo al destino. (Inicia contador de Viaje - Verde)
  TRIP_FINISHED, // 4 - Viaje terminado.
}

class SessionManager {
  // ====================== CÓDIGO INICIAL (MANTENIDO) ======================

  // ===== GUARDAR SESIÓN (LOGIN) =====
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

  // ===== GETTERS BÁSICOS =====
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

  // ===== RESERVAS Y SOLICITUDES =====
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

  // ===== ESTADO DEL CHOFER =====
  static Future<void> setEstadoChofer(bool activo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("chofer_activo", activo);
  }

  static Future<bool?> getEstadoChofer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("chofer_activo");
  }

  // ===== LIMPIAR SESIÓN =====
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ====================== GESTIÓN DEL VIAJE ACTIVO (AJUSTADO) ======================
  static Future<bool> isTripActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('trip_active') == true;
  }

  static Future<TripStatus> getCurrentTripPhase() async {
    final prefs = await SharedPreferences.getInstance();
    // Nuevo valor por defecto: ASSIGNED_TO_DRIVER (0)
    final index =
        prefs.getInt('trip_current_phase') ??
        TripStatus.ASSIGNED_TO_DRIVER.index;
    return TripStatus.values[index.clamp(0, TripStatus.values.length - 1)];
  }

  static Future<void> startTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool('trip_active', true);
    // Estado inicial: ASSIGNED_TO_DRIVER
    await prefs.setInt(
      'trip_current_phase',
      TripStatus.ASSIGNED_TO_DRIVER.index,
    );
    // Se usa 'trip_assigned_time' para el momento en que se tomó el viaje (desde el inicio)
    await prefs.setString('trip_assigned_time', now.toIso8601String());
    // 'trip_phase_start_time' se usa para medir la duración de la FASE ACTUAL (WAITING_INITIAL, ARRIVED_PICKUP, IN_TRANSIT)
    await prefs.setString('trip_phase_start_time', now.toIso8601String());

    // Limpiar tiempos de eventos específicos
    await prefs.remove('trip_arrived_time');
    await prefs.remove('trip_started_transit_time');
    await prefs.remove('trip_finished_time');
  }

  static Future<void> updateTripPhase(TripStatus newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final currentIndex =
        prefs.getInt('trip_current_phase') ??
        TripStatus.ASSIGNED_TO_DRIVER.index;

    // Prevenir retroceder en la fase. Permitir repetir si es el mismo estado.
    if (newStatus.index < currentIndex) return;

    final now = DateTime.now();

    // Registra el tiempo de evento específico:
    // APPROACHING_PICKUP es el momento donde pulsa "Iniciar Viaje" (empieza el contador de ACERCAMIENTO)
    if (newStatus == TripStatus.APPROACHING_PICKUP) {
      await prefs.setString('trip_approach_start_time', now.toIso8601String());
    }
    // ARRIVED_PICKUP es el momento donde pulsa "Llegué" (empieza el contador de ESPERA)
    else if (newStatus == TripStatus.ARRIVED_PICKUP) {
      await prefs.setString('trip_arrived_time', now.toIso8601String());
    }
    // IN_TRANSIT es el momento donde pulsa "Iniciar Viaje con Cliente" (empieza el contador de VIAJE)
    else if (newStatus == TripStatus.IN_TRANSIT) {
      await prefs.setString('trip_started_transit_time', now.toIso8601String());
    }
    // TRIP_FINISHED es el momento donde pulsa "Finalizar"
    else if (newStatus == TripStatus.TRIP_FINISHED) {
      await prefs.setString('trip_finished_time', now.toIso8601String());
    }

    // Siempre actualiza el tiempo de inicio de la FASE ACTUAL
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
      prefs.remove('trip_approach_start_time'), // Nuevo
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

  // Duración de la FASE ACTUAL (útil para mostrar un contador que se resetea en cada avance)
  static Future<Duration> getCurrentPhaseDuration() async {
    final start = await getTripTime('trip_phase_start_time');
    return start == null ? Duration.zero : DateTime.now().difference(start);
  }

  // Duración total del ACERCAMIENTO (APPROACHING_PICKUP)
  static Future<Duration> getApproachDuration() async {
    final approachStart = await getTripTime('trip_approach_start_time');
    final arrived = await getTripTime('trip_arrived_time');
    // Si no ha iniciado el acercamiento (ASSIGNED), o ya se ha llegado, retorna 0 o el tiempo fijo.
    if (approachStart == null) return Duration.zero;

    // Si llegó (arrived != null), el tiempo de acercamiento es fijo.
    // Si no ha llegado (arrived == null), sigue corriendo.
    return (arrived ?? DateTime.now()).difference(approachStart);
  }

  // Duración total de ESPERA (ARRIVED_PICKUP)
  static Future<Duration> getWaitPickupDuration() async {
    final arrived = await getTripTime('trip_arrived_time');
    final started = await getTripTime('trip_started_transit_time');
    // El contador de espera (amarillo) solo empieza a correr después de ARRIVED_PICKUP
    if (arrived == null) return Duration.zero;

    // Si ya inició el tránsito (started != null), el tiempo de espera es fijo.
    // Si no ha iniciado el tránsito (started == null), sigue corriendo.
    return (started ?? DateTime.now()).difference(arrived);
  }

  // Duración total de VIAJE (IN_TRANSIT)
  static Future<Duration> getTravelDuration() async {
    final started = await getTripTime('trip_started_transit_time');
    final finished = await getTripTime('trip_finished_time');

    // El contador de viaje (verde) solo empieza a correr después de IN_TRANSIT
    if (started == null) return Duration.zero;

    // Si el viaje terminó (finished != null), el tiempo de viaje es fijo.
    // Si no ha terminado (finished == null), sigue corriendo.
    return (finished ?? DateTime.now()).difference(started);
  }
}
