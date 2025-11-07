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
  WAITING_INITIAL, // 0: Esperando en la ubicación inicial del conductor
  ARRIVED_PICKUP, // 1: Conductor ha llegado al punto de encuentro
  IN_TRANSIT, // 2: Viaje hacia el destino final iniciado
  TRIP_FINISHED, // 3: Viaje completado
}

// Clase para representar un evento en la línea de tiempo
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

class _MapsScreenState extends State<MapsScreen> {
  TripStatus _currentStatus = TripStatus.WAITING_INITIAL;

  // Lista de eventos para la línea de tiempo
  final List<TripEvent> _tripTimeline = [
    TripEvent(TripStatus.WAITING_INITIAL, 'Asignación de Viaje Confirmada'),
    TripEvent(TripStatus.ARRIVED_PICKUP, 'Llegada al Punto de Encuentro'),
    TripEvent(TripStatus.IN_TRANSIT, 'Inicio de Viaje a Destino'),
    TripEvent(TripStatus.TRIP_FINISHED, 'Destino Llegado - Viaje Finalizado'),
  ];

  // Contadores de tiempo y lógica de cronómetro (se mantiene)
  final Stopwatch _totalStopwatch = Stopwatch();
  Duration _waitDuration = Duration.zero;
  Duration _travelDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startStopwatch();
    // Marcar el primer evento como completado y registrar su tiempo de inicio
    _tripTimeline[0].timestamp = DateTime.now();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _totalStopwatch.stop();
    super.dispose();
  }

  // --- Lógica de Cronómetro y Formato (sin cambios) ---
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

  void _updateDurations() {
    if (_currentStatus == TripStatus.WAITING_INITIAL ||
        _currentStatus == TripStatus.ARRIVED_PICKUP) {
      // WAITING_INITIAL: el cronómetro mide el tiempo de espera
      _waitDuration = _totalStopwatch.elapsed;
    } else if (_currentStatus == TripStatus.IN_TRANSIT) {
      // IN_TRANSIT: el cronómetro mide el tiempo de viaje desde el reinicio en ARRIVED_PICKUP
      _travelDuration = _totalStopwatch.elapsed;
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

  // --- Lógica de Avance de Estado con Botón Único ---
  void _advanceTripStatus() {
    // Encuentra el índice del estado actual en el enum
    final currentStatusIndex = _currentStatus.index;

    // El siguiente estado es el índice actual + 1
    final nextStatusIndex = currentStatusIndex + 1;

    // Asegúrate de que no estamos más allá del estado final
    if (nextStatusIndex < TripStatus.values.length) {
      final nextStatus = TripStatus.values[nextStatusIndex];

      setState(() {
        // 1. Actualiza el estado actual
        _currentStatus = nextStatus;

        // 2. Registra el evento en la línea de tiempo
        _tripTimeline[nextStatusIndex].timestamp = DateTime.now();

        // 3. Manejo de la lógica de tiempo/cronómetro
        if (nextStatus == TripStatus.ARRIVED_PICKUP) {
          // El tiempo de espera está fijo. Reinicia y empieza a medir el tiempo de viaje.
          _totalStopwatch.stop();
          _waitDuration = _totalStopwatch.elapsed; // Fija el tiempo de espera
          _totalStopwatch.reset();
          _travelDuration = Duration.zero;
          _totalStopwatch.start(); // Comienza a medir el tiempo de viaje
        } else if (nextStatus == TripStatus.IN_TRANSIT) {
          // En tránsito (puede que no sea necesario, pero asegura que el cronómetro esté corriendo)
          if (!_totalStopwatch.isRunning) {
            _totalStopwatch.start();
          }
        } else if (nextStatus == TripStatus.TRIP_FINISHED) {
          // Finalizado: detiene todo y fija el tiempo de viaje
          _totalStopwatch.stop();
          _travelDuration = _totalStopwatch.elapsed; // Fija el tiempo de viaje
          _timer?.cancel();
        }

        _updateDurations();
      });
    }
  }

  // --- Métodos de Construcción de Widgets (actualizados) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
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
                  // Se reemplaza _buildActionButtons() por el botón único
                  _buildSingleActionButton(),
                  const SizedBox(height: 30),
                  // Nuevo widget para la línea de tiempo
                  _buildTimeline(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  // Construye la tarjeta que muestra el estado actual del viaje (sin cambios sustanciales)
  Widget _buildStatusCard() {
    // ... (El código de _buildStatusCard se mantiene igual)
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

  // Construye los indicadores de tiempo (Espera y Viaje) (sin cambios sustanciales)
  Widget _buildTimeTrackers() {
    // ... (El código de _buildTimeTrackers y _timeDisplay se mantiene igual)
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

  // Widget auxiliar para mostrar el tiempo (sin cambios sustanciales)
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

  // --- Nuevo Widget: Botón de Acción Único ---
  Widget _buildSingleActionButton() {
    String buttonText;
    Color buttonColor;
    bool isEnabled = true;

    switch (_currentStatus) {
      case TripStatus.WAITING_INITIAL:
        buttonText = '1. Confirmar Llegada a Punto de Encuentro';
        buttonColor = Colors.blue.shade700;
        break;
      case TripStatus.ARRIVED_PICKUP:
        buttonText = '2. Iniciar Viaje a Destino';
        buttonColor = Colors.green.shade700;
        break;
      case TripStatus.IN_TRANSIT:
        buttonText = '3. Confirmar Destino Llegado';
        buttonColor = Colors.purple.shade700;
        break;
      case TripStatus.TRIP_FINISHED:
        buttonText = 'VIAJE FINALIZADO';
        buttonColor = Colors.grey;
        isEnabled = false;
        break;
    }

    return ElevatedButton(
      onPressed: isEnabled ? _advanceTripStatus : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- Nuevo Widget: Línea de Tiempo de Eventos ---
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
          // Lista de eventos
          ..._tripTimeline.asMap().entries.map((entry) {
            int index = entry.key;
            TripEvent event = entry.value;
            bool isCompleted = event.timestamp != null;
            bool isCurrent = event.status == _currentStatus && isCompleted;
            bool isLast = index == _tripTimeline.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimelineItem(event, isCompleted, isCurrent),
                // Solo dibuja la línea si no es el último elemento
                if (!isLast) _buildTimelineConnector(isCompleted),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // Widget para un elemento de la línea de tiempo
  Widget _buildTimelineItem(TripEvent event, bool isCompleted, bool isCurrent) {
    String formattedTime = event.timestamp != null
        ? event.timestamp!.toLocal().toString().substring(11, 16) // HH:MM
        : 'Pendiente';

    Color iconColor = isCompleted
        ? Colors.green.shade700
        : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícono de estado
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_off,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        // Descripción y tiempo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.description,
                style: TextStyle(
                  fontWeight: isCurrent || isCompleted
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isCompleted ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
              Text(
                '${isCompleted ? 'Hora: $formattedTime' : 'Esperando...'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.black54 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget para la línea conectora
  Widget _buildTimelineConnector(bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            height: 25,
            width: 2,
            color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
          ),
        ),
        const SizedBox(width: 8),
        // Espacio vacío para la línea
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}
