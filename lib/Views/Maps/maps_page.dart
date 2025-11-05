import 'dart:async';
import 'package:flutter/material.dart';
// Dependencias de widgets externos, según la estructura de tu proyecto:
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

// ==========================================================
// PÁGINA PRINCIPAL DE MAPAS
// ==========================================================

// Enum para manejar el estado del viaje
enum TripStatus {
  WAITING_INITIAL, // Esperando en la ubicación inicial del conductor
  ARRIVED_PICKUP, // Conductor ha llegado al punto de encuentro
  IN_TRANSIT, // Viaje hacia el destino final iniciado
  TRIP_FINISHED, // Viaje completado
}

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  TripStatus _currentStatus = TripStatus.WAITING_INITIAL;

  // Contadores de tiempo para rastrear el tiempo muerto y el tiempo de viaje
  final Stopwatch _totalStopwatch = Stopwatch();
  Duration _waitDuration = Duration.zero;
  Duration _travelDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startStopwatch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _totalStopwatch.stop();
    super.dispose();
  }

  // Inicia el cronómetro y el temporizador para actualizar la UI cada segundo
  void _startStopwatch() {
    _totalStopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_totalStopwatch.isRunning && mounted) {
        setState(() {
          _updateDurations();
        });
      }
    });
  }

  // Actualiza la duración según el estado actual del viaje
  void _updateDurations() {
    if (_currentStatus == TripStatus.WAITING_INITIAL) {
      _waitDuration = _totalStopwatch.elapsed;
    } else if (_currentStatus == TripStatus.IN_TRANSIT) {
      // El tiempo de viaje es el tiempo total transcurrido menos el tiempo de espera
      _travelDuration = _totalStopwatch.elapsed - _waitDuration;
    }
  }

  // Formatea una duración a HH:MM:SS
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // Maneja la transición de estados al presionar los botones
  void _handleButtonPress(TripStatus nextStatus) {
    setState(() {
      _currentStatus = nextStatus;

      if (nextStatus == TripStatus.ARRIVED_PICKUP) {
        // Al llegar al punto de encuentro, se fija el tiempo de espera
        _totalStopwatch.stop();
        _waitDuration = _totalStopwatch.elapsed;
        // Reinicia el cronómetro para empezar a medir el tiempo de viaje
        _totalStopwatch.reset();
        _totalStopwatch.start();
        _travelDuration = Duration.zero;
      } else if (nextStatus == TripStatus.IN_TRANSIT) {
        if (!_totalStopwatch.isRunning) {
          _totalStopwatch.start();
        }
      } else if (nextStatus == TripStatus.TRIP_FINISHED) {
        // Al finalizar, se detiene el cronómetro y el temporizador
        _totalStopwatch.stop();
        _travelDuration = _totalStopwatch.elapsed;
        _timer?.cancel();
      }

      _updateDurations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Usa el componente del encabezado, ahora importado
          const LogoHeader(titulo: 'Viaje', estiloLogin: false),

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
                  _buildActionButtons(),
                  // Aquí es donde estaba el mapa de rastreo
                ],
              ),
            ),
          ),
        ],
      ),
      // Usa el componente de la barra de navegación inferior, ahora importado
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  // Construye la tarjeta que muestra el estado actual del viaje
  Widget _buildStatusCard() {
    String statusText = '';
    Color statusColor = Colors.grey;

    switch (_currentStatus) {
      case TripStatus.WAITING_INITIAL:
        statusText =
            'En Espera de Llegada al Punto de Encuentro (Tiempo Muerto)';
        statusColor = Colors.orange.shade800;
        break;
      case TripStatus.ARRIVED_PICKUP:
        statusText = 'Llegada Confirmada. Esperando a Iniciar el Viaje.';
        statusColor = Colors.blue.shade800;
        break;
      case TripStatus.IN_TRANSIT:
        statusText = 'VIAJE INICIADO - En Recorrido a Destino';
        statusColor = Colors.green.shade800;
        break;
      case TripStatus.TRIP_FINISHED:
        statusText = 'VIAJE FINALIZADO con éxito.';
        statusColor = Colors.purple.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
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
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Construye los indicadores de tiempo (Espera y Viaje)
  Widget _buildTimeTrackers() {
    return Column(
      children: [
        _timeDisplay(
          'Tiempo de Espera ',
          _formatDuration(_waitDuration),
          Colors.orange.shade100,
          Colors.orange.shade800,
        ),
        const SizedBox(height: 10),
        _timeDisplay(
          'Tiempo de Recorrido ',
          _formatDuration(_travelDuration),
          Colors.green.shade100,
          Colors.green.shade800,
        ),
      ],
    );
  }

  // Widget auxiliar para mostrar el tiempo
  Widget _timeDisplay(String title, String time, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: fgColor),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: fgColor,
              // Utiliza una fuente monoespaciada para mejor visualización del tiempo
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }

  // Construye los botones de acción para cambiar de estado
  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _currentStatus == TripStatus.WAITING_INITIAL
              ? () => _handleButtonPress(TripStatus.ARRIVED_PICKUP)
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '1. Llegado a Punto de Encuentro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: _currentStatus == TripStatus.ARRIVED_PICKUP
              ? () => _handleButtonPress(TripStatus.IN_TRANSIT)
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '2. Iniciar Viaje a Destino',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: _currentStatus == TripStatus.IN_TRANSIT
              ? () => _handleButtonPress(TripStatus.TRIP_FINISHED)
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '3. Destino Llegado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
