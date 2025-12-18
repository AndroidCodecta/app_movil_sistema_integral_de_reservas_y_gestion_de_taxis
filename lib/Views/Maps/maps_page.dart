import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/header.dart';
import '/utils/viajes_service.dart';

enum TripStatus {
  EN_CAMINO,
  EN_PUNTO_ENCUENTRO,
  EN_VIAJE,
  DESTINO_LLEGADO,
  PAGO_COMPLETADO,
}

class TripEvent {
  final TripStatus status;
  final String description;
  DateTime? timestamp;
  TripEvent(this.status, this.description, {this.timestamp});
}

class MapsScreen extends StatefulWidget {
  final bool viajeIniciado;
  final int? reservaId;
  final String? montoViaje;
  final String? tipoPago;
  final String? direccionOrigen;
  final String? direccionDestino;
  final String? fechaHoraProgramadaStr;
  final List<TripEvent>? initialTripTimeline;
  final int initialWaitMilliseconds;
  final int initialTravelMilliseconds;

  const MapsScreen({
    super.key,
    this.viajeIniciado = false,
    this.reservaId,
    this.montoViaje,
    this.tipoPago,
    this.direccionOrigen,
    this.direccionDestino,
    this.fechaHoraProgramadaStr,
    this.initialTripTimeline,
    this.initialWaitMilliseconds = 0,
    this.initialTravelMilliseconds = 0,
  });

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late String _montoViaje;
  late String _tipoPago;
  late int? _reservaId;
  late String _direccionOrigen;
  late String _direccionDestino;
  late DateTime _scheduledTime;
  TripStatus _currentStatus = TripStatus.EN_CAMINO;
  late List<TripEvent> _tripTimeline;

  Timer? _timer;
  Duration _waitDuration = Duration.zero;
  Duration _travelDuration = Duration.zero;
  bool _isWaitingForScheduledTime = false;

  bool _tripActive = false;
  bool _hasOngoingTrip = false;
  Map<String, dynamic>? _ongoingData;

  String _selectedPaymentMethod = "Efectivo";
  final TextEditingController _observacionController = TextEditingController();
  final List<String> _paymentMethods = ["Efectivo", "Yape", "PLIN"];

  @override
  void initState() {
    super.initState();
    _tripActive = widget.viajeIniciado;

    _montoViaje = "S/. ${widget.montoViaje ?? '0.00'}";
    _tipoPago = widget.tipoPago ?? "Efectivo";
    _reservaId = widget.reservaId;
    _direccionOrigen = widget.direccionOrigen ?? "---";
    _direccionDestino = widget.direccionDestino ?? "---";
    _scheduledTime = widget.fechaHoraProgramadaStr != null
        ? DateTime.parse(widget.fechaHoraProgramadaStr!.trim())
        : DateTime.now();

    _initializeTripState();

    if (_tripActive) {
      _startTicker();
    } else {
      _checkOngoingTrip();
    }
  }

  void _initializeTripState() {
    if (widget.initialTripTimeline != null &&
        widget.initialTripTimeline!.isNotEmpty) {
      _tripTimeline = widget.initialTripTimeline!;
      _currentStatus = _tripTimeline.last.status;
    } else {
      _tripTimeline = [
        TripEvent(
          TripStatus.EN_CAMINO,
          'En camino al punto de encuentro',
          timestamp: DateTime.now(),
        ),
        TripEvent(
          TripStatus.EN_PUNTO_ENCUENTRO,
          'Llegada al punto de encuentro',
        ),
        TripEvent(TripStatus.EN_VIAJE, 'Viaje iniciado'),
        TripEvent(TripStatus.DESTINO_LLEGADO, 'Llegada al destino'),
      ];
      _currentStatus = TripStatus.EN_CAMINO;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _checkOngoingTrip() async {
    final data = await ViajesService.getReservaEnCurso();
    if (mounted) {
      setState(() {
        if (data != null &&
            data["success"] == true &&
            data.containsKey("seguimiento")) {
          _hasOngoingTrip = true;
          _ongoingData = data;

          // Actualizar variables con datos de la API
          final seguimiento = data["seguimiento"];
          final reserva = seguimiento["reserva"];
          _reservaId = reserva["id"];
          _direccionOrigen = reserva["d_encuentro"] ?? "---";
          _direccionDestino = reserva["d_destino"] ?? "---";
          _scheduledTime = DateTime.parse(reserva["fecha_hora"]);
          _montoViaje = reserva["precio"] ?? "S/. 0.00";
          _tipoPago = reserva["tipo"] == 1 ? "Efectivo" : "Otro";
        } else {
          _hasOngoingTrip = false;
        }
      });
    }
  }

  void _resumeTrip() {
    final seguimiento = _ongoingData!["seguimiento"];

    final String? horaLlegadaStr = seguimiento["hora_llegada"];
    final String? inicioServicioStr = seguimiento["inicio_servicio"];
    final String? finServicioStr = seguimiento["fin_servicio"];

    DateTime? horaLlegada = horaLlegadaStr != null
        ? DateTime.parse(horaLlegadaStr)
        : null;
    DateTime? inicioServicio = inicioServicioStr != null
        ? DateTime.parse(inicioServicioStr)
        : null;
    DateTime? finServicio = finServicioStr != null
        ? DateTime.parse(finServicioStr)
        : null;

    _tripTimeline[0].timestamp =
        horaLlegada ?? DateTime.now().subtract(const Duration(minutes: 5));
    _tripTimeline[1].timestamp = horaLlegada;
    _tripTimeline[2].timestamp = inicioServicio;
    _tripTimeline[3].timestamp = finServicio;

    if (finServicio != null) {
      _currentStatus = TripStatus.DESTINO_LLEGADO;
    } else if (inicioServicio != null) {
      _currentStatus = TripStatus.EN_VIAJE;
    } else if (horaLlegada != null) {
      _currentStatus = TripStatus.EN_PUNTO_ENCUENTRO;
    } else {
      _currentStatus = TripStatus.EN_CAMINO;
    }

    setState(() {
      _hasOngoingTrip = false;
      _tripActive = true;
    });

    if (_currentStatus != TripStatus.DESTINO_LLEGADO &&
        _currentStatus != TripStatus.PAGO_COMPLETADO) {
      _startTicker();
    }
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final now = DateTime.now();
        if (_currentStatus == TripStatus.EN_PUNTO_ENCUENTRO) {
          final arrival = _tripTimeline[1].timestamp ?? now;
          final startCount = _scheduledTime.isAfter(arrival)
              ? _scheduledTime
              : arrival;
          if (now.isBefore(startCount)) {
            _isWaitingForScheduledTime = true;
            _waitDuration = Duration.zero;
          } else {
            _isWaitingForScheduledTime = false;
            _waitDuration = now.difference(startCount);
          }
        }
        if (_currentStatus == TripStatus.EN_VIAJE) {
          final startTravel = _tripTimeline[2].timestamp ?? now;
          _travelDuration = now.difference(startTravel);
        }
      });
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> _handleButtonAction() async {
    if (_reservaId == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD60A)),
      ),
    );

    bool success = false;
    final int id = _reservaId!;
    try {
      switch (_currentStatus) {
        case TripStatus.EN_CAMINO:
          success = await ViajesService.confirmarLlegada(id);
          break;
        case TripStatus.EN_PUNTO_ENCUENTRO:
          String tiempoEspera = _formatDuration(_waitDuration);
          success = await ViajesService.iniciarViaje(id, tiempoEspera);
          break;
        case TripStatus.EN_VIAJE:
          String tiempoViaje = _formatDuration(_travelDuration);
          success = await ViajesService.finalizarViaje(id, tiempoViaje);
          break;
        default:
          success = true;
          break;
      }
    } catch (e) {
      debugPrint("Error API: $e");
    }

    if (mounted) Navigator.pop(context);

    if (success) {
      _advanceLocalState();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error de conexión."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _advanceLocalState() {
    setState(() {
      final currentStatusIndex = _currentStatus.index;
      final nextStatusIndex = currentStatusIndex + 1;
      if (nextStatusIndex < TripStatus.values.length) {
        final nextStatus = TripStatus.values[nextStatusIndex];
        _currentStatus = nextStatus;
        for (var event in _tripTimeline) {
          if (event.status == nextStatus) {
            event.timestamp = DateTime.now();
            break;
          }
        }
        switch (nextStatus) {
          case TripStatus.EN_PUNTO_ENCUENTRO:
            _startTicker();
            break;
          case TripStatus.EN_VIAJE:
            break;
          case TripStatus.DESTINO_LLEGADO:
            _timer?.cancel();
            bool esConvenio =
                _tipoPago.toLowerCase().contains("crédito") ||
                _tipoPago.toLowerCase().contains("corporativo") ||
                _tipoPago.toLowerCase().contains("vale") ||
                _tipoPago.toLowerCase().contains("convenio");
            if (esConvenio) {
              _currentStatus = TripStatus.PAGO_COMPLETADO;
            }
            break;
          default:
            break;
        }
      }
    });
  }

  Future<void> _handlePaymentSubmit() async {
    if (_reservaId == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool success = await ViajesService.registrarPagoAdicional(
      reservaId: _reservaId!,
      metodo: _selectedPaymentMethod,
      observacion: _observacionController.text,
      statusPago: 1,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      setState(() => _currentStatus = TripStatus.PAGO_COMPLETADO);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar cobro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showConfirmationDialog() async {
    String title = "";
    String content = "";
    bool blockAction = false;
    final now = DateTime.now();
    switch (_currentStatus) {
      case TripStatus.EN_CAMINO:
        title = "Confirmar Llegada";
        content = "¿Estás en el punto de encuentro?";
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        title = "Comenzar Viaje";
        if (now.isBefore(_scheduledTime)) {
          final diff = _scheduledTime.difference(now);
          if (diff.inMinutes > 5) {
            content =
                "No puedes iniciar el viaje. La hora programada es en ${diff.inMinutes} minutos. El límite de anticipación es de 5 minutos.";
            blockAction = true;
          } else {
            content =
                "Aún falta para la hora programada (Faltan ${diff.inMinutes} min). ¿Deseas iniciar el viaje de todos modos?";
          }
        } else {
          content = "¿El pasajero subió al vehículo?";
        }
        break;
      case TripStatus.EN_VIAJE:
        title = "Terminar Viaje";
        content = "¿Has llegado al destino final?";
        break;
      default:
        return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: blockAction
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _handleButtonAction();
                    },
              child: Text(blockAction ? 'Entendido' : 'Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showingPaymentUI =
        _currentStatus == TripStatus.DESTINO_LLEGADO ||
        _currentStatus == TripStatus.PAGO_COMPLETADO;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Viaje en Curso', estiloLogin: false),
          if (_tripActive)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAddressCard(),
                    const SizedBox(height: 15),
                    if (_currentStatus != TripStatus.PAGO_COMPLETADO)
                      _buildDynamicTimer(),
                    const SizedBox(height: 20),
                    if (!showingPaymentUI) _buildSingleActionButton(),
                    const SizedBox(height: 20),
                    _buildTimeline(),
                    if (showingPaymentUI) ...[
                      const SizedBox(height: 20),
                      _buildPaymentSection(),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            )
          else if (_hasOngoingTrip)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_car_filled,
                          size: 80,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Tienes un viaje en curso',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Continúa con el viaje que estaba activo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Resumen del viaje en curso
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              _buildMiniAddressRow(
                                Icons.my_location,
                                Colors.green,
                                "Origen",
                                _direccionOrigen,
                              ),
                              const SizedBox(height: 12),
                              _buildMiniAddressRow(
                                Icons.location_on,
                                Colors.red,
                                "Destino",
                                _direccionDestino,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow, size: 28),
                            label: const Text(
                              'CONTINUAR VIAJE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _resumeTrip,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('No tienes un viaje en curso')),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAddressRow(
            Icons.my_location,
            Colors.green,
            "Origen",
            _direccionOrigen,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 16,
                child: VerticalDivider(color: Colors.grey, thickness: 1),
              ),
            ),
          ),
          _buildAddressRow(
            Icons.location_on,
            Colors.red,
            "Destino",
            _direccionDestino,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(
    IconData icon,
    Color color,
    String label,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAddressRow(
    IconData icon,
    Color color,
    String label,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicTimer() {
    String label = "Estado";
    String timeValue = "--:--:--";
    String subLabel = "";
    Color bgColor = Colors.grey.shade200;
    Color fgColor = Colors.grey.shade700;
    switch (_currentStatus) {
      case TripStatus.EN_CAMINO:
        label = "EN CAMINO";
        String hora =
            "${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}";
        subLabel = "Hora prog: $hora";
        bgColor = Colors.blue.shade50;
        fgColor = Colors.blue.shade800;
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        if (_isWaitingForScheduledTime) {
          final diff = _scheduledTime.difference(DateTime.now());
          if (diff.inMinutes > 5) {
            label = "ANTICIPACIÓN EXCESIVA";
            timeValue = "BLOQUEADO";
            subLabel = "Faltan ${diff.inMinutes} min (Máx 5 min)";
            bgColor = Colors.red.shade100;
            fgColor = Colors.red.shade900;
          } else {
            label = "ANTICIPADO";
            timeValue = "ESPERANDO";
            subLabel = "Faltan ${diff.inMinutes} min";
            bgColor = Colors.amber.shade100;
            fgColor = Colors.amber.shade900;
          }
        } else {
          label = "TIEMPO DE ESPERA";
          timeValue = _formatDuration(_waitDuration);
          bgColor = Colors.orange.shade100;
          fgColor = Colors.orange.shade900;
        }
        break;
      case TripStatus.EN_VIAJE:
        label = "EN VIAJE";
        timeValue = _formatDuration(_travelDuration);
        bgColor = Colors.green.shade100;
        fgColor = Colors.green.shade900;
        break;
      case TripStatus.DESTINO_LLEGADO:
        label = "DESTINO ALCANZADO";
        bgColor = Colors.purple.shade50;
        fgColor = Colors.purple.shade800;
        break;
      default:
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: fgColor,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeValue,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
          if (subLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: TextStyle(fontSize: 13, color: fgColor.withOpacity(0.9)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleActionButton() {
    String buttonText = '';
    Color buttonColor = Colors.blue;
    IconData icon = Icons.check;
    switch (_currentStatus) {
      case TripStatus.EN_CAMINO:
        buttonText = 'Llegué al Punto';
        buttonColor = Colors.blue.shade700;
        icon = Icons.location_on;
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        buttonText = 'INICIAR VIAJE';
        buttonColor = Colors.green.shade700;
        icon = Icons.play_arrow;
        break;
      case TripStatus.EN_VIAJE:
        buttonText = 'TERMINAR VIAJE';
        buttonColor = Colors.red.shade700;
        icon = Icons.stop_circle;
        break;
      default:
        return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: _showConfirmationDialog,
      icon: Icon(icon, size: 22),
      label: Text(
        buttonText,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HISTORIAL:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ..._tripTimeline.asMap().entries.map((entry) {
            bool isCompleted = entry.value.timestamp != null;
            String timeStr = isCompleted
                ? "${entry.value.timestamp!.hour.toString().padLeft(2, '0')}:${entry.value.timestamp!.minute.toString().padLeft(2, '0')}"
                : "";
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted ? Colors.black87 : Colors.grey,
                        fontWeight: isCompleted
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    bool esConvenio =
        _tipoPago.toLowerCase().contains("crédito") ||
        _tipoPago.toLowerCase().contains("corporativo") ||
        _tipoPago.toLowerCase().contains("vale") ||
        _tipoPago.toLowerCase().contains("convenio");

    if (_currentStatus == TripStatus.PAGO_COMPLETADO) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 10),
            Text(
              esConvenio ? "Viaje Finalizado" : "Pago Registrado",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              esConvenio
                  ? "El servicio por convenio ha concluido."
                  : "Cobro exitoso.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainLayoutScreen(),
                  ),
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD60A),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text(
                  "VOLVER AL INICIO",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "REGISTRAR COBRO",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text(_tipoPago, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue.shade50,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Divider(),
          Center(
            child: Text(
              _montoViaje,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            isDense: true,
            decoration: InputDecoration(
              labelText: "Método de Pago",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: _paymentMethods
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observacionController,
            decoration: InputDecoration(
              labelText: "Observación (Opcional)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handlePaymentSubmit,
              icon: const Icon(Icons.attach_money, size: 20),
              label: const Text(
                "CONFIRMAR COBRO",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
