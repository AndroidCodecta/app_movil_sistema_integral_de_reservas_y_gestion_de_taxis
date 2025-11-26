// Archivo: maps_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:workmanager/workmanager.dart'; // Ya no se necesita Workmanager si el cálculo se hace en SessionManager
import '../../Utils/session_manager.dart'; // Importa el TripStatus y SessionManager
import '../widgets/header.dart'; // Asumo que tienes esta ruta
import '../widgets/bottom_navigation.dart'; // Asumo que tienes esta ruta

// ==========================================================
// PANTALLA PRINCIPAL
// ==========================================================

class TripEvent {
  final TripStatus status;
  final String description;
  DateTime? timestamp;
  TripEvent(this.status, this.description, {this.timestamp});
}

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> with WidgetsBindingObserver {
  late TripStatus _currentStatus;

  // Los 4 eventos principales después de ASSIGNED_TO_DRIVER (0)
  final List<TripEvent> _tripTimeline = [
    TripEvent(
      TripStatus.APPROACHING_PICKUP,
      '1. Viajando a Dirección de Recojo (Iniciado)',
    ), // Índice 0
    TripEvent(
      TripStatus.ARRIVED_PICKUP,
      '2. Chofer llega al Punto de Encuentro',
    ), // Índice 1
    TripEvent(
      TripStatus.IN_TRANSIT,
      '3. Inicio de Viaje (con Cliente)',
    ), // Índice 2
    TripEvent(TripStatus.TRIP_FINISHED, '4. Viaje Finalizado'), // Índice 3
  ];

  Duration _waitDuration = Duration.zero;
  Duration _travelDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentStatus = TripStatus.ASSIGNED_TO_DRIVER;
    _initializeTrip();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Si la app vuelve a primer plano, forzamos la lectura de los tiempos
      _updateTimes();
    }
  }

  Future<void> _initializeTrip() async {
    final isActive = await SessionManager.isTripActive();

    if (!isActive) {
      // Inicia un nuevo viaje en el estado base ASSIGNED_TO_DRIVER (0)
      await SessionManager.startTrip();
      _currentStatus = TripStatus.ASSIGNED_TO_DRIVER;
    } else {
      _currentStatus = await SessionManager.getCurrentTripPhase();

      // Recuperar los timestamps para la línea de tiempo.
      final approached = await SessionManager.getTripTime(
        'trip_approach_start_time',
      ); // Nuevo timestamp
      final arrived = await SessionManager.getTripTime('trip_arrived_time');
      final started = await SessionManager.getTripTime(
        'trip_started_transit_time',
      );
      final finished = await SessionManager.getTripTime('trip_finished_time');

      if (approached != null) _tripTimeline[0].timestamp = approached;
      if (arrived != null) _tripTimeline[1].timestamp = arrived;
      if (started != null) _tripTimeline[2].timestamp = started;
      if (finished != null) _tripTimeline[3].timestamp = finished;

      // Recuperar contadores al inicio
      _waitDuration = await SessionManager.getWaitPickupDuration();
      _travelDuration = await SessionManager.getTravelDuration();
    }

    // Timer de 1 segundo para refrescar el UI de los tiempos más fluidamente
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimes());
    if (mounted) setState(() {});
  }

  // Corregido: Actualiza los contadores de tiempo en la UI leyendo el cálculo en vivo
  void _updateTimes() async {
    if (_currentStatus == TripStatus.TRIP_FINISHED) {
      _timer?.cancel();
      return;
    }

    // Leemos los contadores que SessionManager calcula en vivo usando DateTime.now()
    final wait = await SessionManager.getWaitPickupDuration();
    final travel = await SessionManager.getTravelDuration();

    if (mounted) {
      setState(() {
        _waitDuration = wait;
        _travelDuration = travel;
      });
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _advanceTripStatus() async {
    if (_currentStatus == TripStatus.TRIP_FINISHED) return;

    final nextIndex = _currentStatus.index + 1;
    if (nextIndex >= TripStatus.values.length) return;

    final nextStatus = TripStatus.values[nextIndex];
    await SessionManager.updateTripPhase(nextStatus);

    // Si el estado es APPROACHING_PICKUP o ARRIVED_PICKUP o IN_TRANSIT,
    // el timestamp correspondiente en la línea de tiempo se actualiza.
    if (nextStatus.index > TripStatus.ASSIGNED_TO_DRIVER.index) {
      // El índice de _tripTimeline es siempre el índice del enum - 1
      _tripTimeline[nextStatus.index - 1].timestamp =
          await SessionManager.getTripTime(
            nextStatus == TripStatus.APPROACHING_PICKUP
                ? 'trip_approach_start_time'
                : nextStatus == TripStatus.ARRIVED_PICKUP
                ? 'trip_arrived_time'
                : nextStatus == TripStatus.IN_TRANSIT
                ? 'trip_started_transit_time'
                : 'trip_finished_time',
          );
    }

    setState(() {
      _currentStatus = nextStatus;
      // Forzar la actualización inmediata de los contadores con el nuevo tiempo fijo/cero
      _updateTimes();
    });

    if (nextStatus == TripStatus.TRIP_FINISHED) {
      // Finaliza el viaje
      await SessionManager.endTrip();
      _timer?.cancel();
    }
  }

  Future<void> _showConfirmationDialog() async {
    if (_currentStatus == TripStatus.TRIP_FINISHED) return;

    // Define la descripción del PRÓXIMO estado
    String nextDesc = '';
    if (_currentStatus == TripStatus.ASSIGNED_TO_DRIVER) {
      nextDesc = '1. Iniciar Viaje (a Recojo)';
    } else if (_currentStatus == TripStatus.APPROACHING_PICKUP) {
      nextDesc = '2. Chofer llega al Punto de Encuentro';
    } else if (_currentStatus == TripStatus.ARRIVED_PICKUP) {
      nextDesc = '3. Iniciar Viaje con Pasajero (a Destino)';
    } else if (_currentStatus == TripStatus.IN_TRANSIT) {
      nextDesc = '4. Finalizar Viaje';
    } else {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Avance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de avanzar al siguiente paso?'),
            const SizedBox(height: 12),
            Text(
              'Próximo estado: "$nextDesc"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Esta acción no se puede deshacer.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: const Text('Avanzar'),
          ),
        ],
      ),
    );

    if (confirm == true) _advanceTripStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const LogoHeader(
            titulo: 'Viaje',
            estiloLogin: false,
          ), // Asumo este widget
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildTimeTrackers(),
                  const SizedBox(height: 30),
                  _buildSingleActionButton(),
                  const SizedBox(height: 30),
                  _buildTimeline(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(), // Asumo este widget
    );
  }

  Widget _buildStatusCard() {
    String text = '';
    Color color = Colors.grey.shade600;

    if (_currentStatus == TripStatus.ASSIGNED_TO_DRIVER) {
      text = 'ASIGNADO - Pendiente de Iniciar Viaje';
      color = Colors.grey.shade600;
    } else if (_currentStatus == TripStatus.APPROACHING_PICKUP) {
      text = 'EN RUTA - Viajando a la dirección de recojo';
      color = Colors.blue.shade800;
    } else if (_currentStatus == TripStatus.ARRIVED_PICKUP) {
      text = 'ESPERA - Esperando al pasajero en el punto de encuentro';
      color = Colors.orange.shade800;
    } else if (_currentStatus == TripStatus.IN_TRANSIT) {
      text = 'EN VIAJE - Llevando al pasajero al destino';
      color = Colors.green.shade800;
    } else if (_currentStatus == TripStatus.TRIP_FINISHED) {
      text = 'VIAJE FINALIZADO CON ÉXITO';
      color = Colors.purple.shade800;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADO ACTUAL:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTrackers() => Column(
    children: [
      // Contador de Espera (Amarillo)
      _timeDisplay(
        'Tiempo de Espera (al pasajero)',
        _formatDuration(_waitDuration),
        Colors.orange.shade100,
        Colors.orange.shade800,
      ),
      const SizedBox(height: 10),
      // Contador de Viaje (Verde)
      _timeDisplay(
        'Tiempo de Recorrido',
        _formatDuration(_travelDuration),
        Colors.green.shade100,
        Colors.green.shade800,
      ),
    ],
  );

  Widget _timeDisplay(String title, String time, Color bg, Color fg) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, color: fg),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: fg,
                fontFamily: 'RobotoMono',
              ),
            ),
          ],
        ),
      );

  Widget _buildSingleActionButton() {
    final texts = {
      TripStatus.ASSIGNED_TO_DRIVER: '1. Iniciar Viaje (a Recojo)',
      TripStatus.APPROACHING_PICKUP: '2. Chofer llega al Punto de Encuentro',
      TripStatus.ARRIVED_PICKUP: '3. Iniciar Viaje con Pasajero (a Destino)',
      TripStatus.IN_TRANSIT: '4. Finalizar Viaje',
      TripStatus.TRIP_FINISHED: 'VIAJE FINALIZADO',
    };

    final colors = {
      TripStatus.ASSIGNED_TO_DRIVER: Colors.blue.shade700,
      TripStatus.APPROACHING_PICKUP: Colors.orange.shade700,
      TripStatus.ARRIVED_PICKUP: Colors.green.shade700,
      TripStatus.IN_TRANSIT: Colors.purple.shade700,
      TripStatus.TRIP_FINISHED: Colors.grey,
    };

    return ElevatedButton(
      onPressed: _currentStatus == TripStatus.TRIP_FINISHED
          ? null
          : _showConfirmationDialog,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: colors[_currentStatus],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        texts[_currentStatus]!,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HISTORIAL DE VIAJE:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ..._tripTimeline.map((event) {
            final completed = event.timestamp != null;
            final isActive = _currentStatus == event.status;

            Color iconColor;
            IconData iconData;

            if (completed) {
              iconColor = Colors.green.shade700;
              iconData = Icons.check_circle;
            } else if (isActive) {
              iconColor = Colors.orange.shade500;
              iconData = Icons.adjust;
            } else {
              iconColor = Colors.grey.shade400;
              iconData = Icons.radio_button_off;
            }

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.description,
                            style: TextStyle(
                              fontWeight: completed || isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: completed || isActive
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            completed
                                ? 'Hora: ${event.timestamp!.toString().substring(11, 19)}'
                                : isActive
                                ? 'EN CURSO (Estado Actual)'
                                : 'Pendiente',
                            style: TextStyle(
                              fontSize: 12,
                              color: completed ? Colors.grey : iconColor,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (event != _tripTimeline.last)
                  _buildTimelineConnector(completed),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(bool completed) => Row(
    children: [
      Container(
        width: 30,
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          height: 25,
          width: 2,
          color: completed ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      const SizedBox(width: 8),
      const Expanded(child: SizedBox.shrink()),
    ],
  );
}
