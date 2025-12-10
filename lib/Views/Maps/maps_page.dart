import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/header.dart';

enum TripStatus {
  EN_CAMINO,           // 1. Chofer va en camino
  EN_PUNTO_ENCUENTRO,  // 2. Llegó
  EN_VIAJE,            // 3. Inició viaje
  DESTINO_LLEGADO,     // 4. Llegó al destino
  PAGO_COMPLETADO      // 5. Fin
}

class TripEvent {
  final TripStatus status;
  final String description;
  DateTime? timestamp; // Aquí se guardará la hora del reloj
  DateTime? expectedTime;

  TripEvent(this.status, this.description, {this.timestamp, this.expectedTime});
}

class MapsScreen extends StatefulWidget {
  final bool viajeIniciado;
  final int? reservaId;
  final DateTime? horaEsperadaRecogidaReal;
  final String? montoViaje;
  final String? tipoPago;

  const MapsScreen({
    super.key,
    this.viajeIniciado = false,
    this.reservaId,
    this.horaEsperadaRecogidaReal,
    this.montoViaje,
    this.tipoPago,
  });

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late String _montoViaje;
  late String _tipoPago;
  TripStatus _currentStatus = TripStatus.EN_CAMINO;
  late List<TripEvent> _tripTimeline;

  // Cronómetros
  final Stopwatch _waitStopwatch = Stopwatch();
  final Stopwatch _travelStopwatch = Stopwatch();
  Timer? _timer;

  Duration _waitDuration = Duration.zero;
  Duration _travelDuration = Duration.zero;

  // Simulación para lógica de semáforo (puedes quitarlo si usas datos reales)
  late DateTime _simulatedExpectedTimeForTesting;

  @override
  void initState() {
    super.initState();
    _montoViaje = "S/. ${widget.montoViaje ?? '0.00'}";
    _tipoPago = widget.tipoPago ?? "Efectivo";
    _simulatedExpectedTimeForTesting =
        DateTime.now().add(const Duration(minutes: 15));

    _tripTimeline = [
      TripEvent(TripStatus.EN_CAMINO,
          'El chofer está de camino al punto de encuentro'),
      TripEvent(TripStatus.EN_PUNTO_ENCUENTRO,
          'El chofer llegó al punto de encuentro',
          expectedTime: _simulatedExpectedTimeForTesting),
      TripEvent(TripStatus.EN_VIAJE, 'El chofer comenzó el viaje'),
      TripEvent(TripStatus.DESTINO_LLEGADO, 'El chofer llegó al destino'),
    ];

    // 1. El primer estado toma la hora del reloj AHORA MISMO
    _tripTimeline[0].timestamp = DateTime.now();

    if (widget.viajeIniciado) {
      _startTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waitStopwatch.stop();
    _travelStopwatch.stop();
    super.dispose();
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_waitStopwatch.isRunning) _waitDuration = _waitStopwatch.elapsed;
          if (_travelStopwatch.isRunning)
            _travelDuration = _travelStopwatch.elapsed;
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> _advanceTripStatus() async {
    setState(() {
      final currentStatusIndex = _currentStatus.index;
      final nextStatusIndex = currentStatusIndex + 1;

      if (nextStatusIndex < TripStatus.values.length) {
        final nextStatus = TripStatus.values[nextStatusIndex];
        _currentStatus = nextStatus;

        // Capturamos la hora exacta
        for (var event in _tripTimeline) {
          if (event.status == nextStatus) {
            event.timestamp = DateTime.now();
            break;
          }
        }

        switch (nextStatus) {
          case TripStatus.EN_CAMINO:
            break;
          case TripStatus.EN_PUNTO_ENCUENTRO:
            _startTicker();
            _waitStopwatch.start();
            break;
          case TripStatus.EN_VIAJE:
            _waitStopwatch.stop();
            _travelStopwatch.start();
            break;

        // --- AQUÍ ESTÁ EL CAMBIO IMPORTANTE ---
          case TripStatus.DESTINO_LLEGADO:
            _travelStopwatch.stop();
            _timer?.cancel();

            bool esPostPago = widget.tipoPago!.toLowerCase().contains("post pago");

            if (!esPostPago) {
              // Si NO es postpago, terminamos automático
              _currentStatus = TripStatus.PAGO_COMPLETADO;
            }
            break;
        // -------------------------------------

          case TripStatus.PAGO_COMPLETADO:
            break;
        }
      }
    });
  }

  Future<void> _showConfirmationDialog() async {
    if (_currentStatus == TripStatus.DESTINO_LLEGADO ||
        _currentStatus == TripStatus.PAGO_COMPLETADO) return;

    String nextStepTitle = "";
    switch (_currentStatus) {
      case TripStatus.EN_CAMINO:
        nextStepTitle = "Llegué al punto de encuentro";
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        nextStepTitle = "Comenzar Viaje";
        break;
      case TripStatus.EN_VIAJE:
        nextStepTitle = "Terminar Viaje";
        break;
      default:
        break;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(nextStepTitle),
          content: const Text('¿Estás seguro de avanzar al siguiente estado?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirmar'),
              onPressed: () {
                Navigator.of(context).pop();
                _advanceTripStatus(); // Aquí se dispara la captura de hora
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Viaje en Curso', estiloLogin: false),

          if (widget.viajeIniciado)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentStatus != TripStatus.PAGO_COMPLETADO)
                      _buildDynamicTimer(),

                    const SizedBox(height: 30),

                    if (_currentStatus != TripStatus.DESTINO_LLEGADO &&
                        _currentStatus != TripStatus.PAGO_COMPLETADO)
                      _buildSingleActionButton(),

                    const SizedBox(height: 30),
                    _buildTimeline(),

                    if (_currentStatus == TripStatus.DESTINO_LLEGADO ||
                        _currentStatus == TripStatus.PAGO_COMPLETADO)
                      _buildPaymentSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('Aún no has iniciado un viaje',
                  style: TextStyle(fontSize: 18))),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildDynamicTimer() {
    String label = "Tiempo";
    String timeValue = "00:00:00";
    Color bgColor = Colors.grey.shade200;
    Color fgColor = Colors.grey.shade700;
    bool isMessageMode = false;

    switch (_currentStatus) {
      case TripStatus.EN_CAMINO:
        label = "En Camino";
        timeValue = "--:--:--";
        bgColor = Colors.blue.shade50;
        fgColor = Colors.blue.shade800;
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        label = "Tiempo de Espera";
        timeValue = _formatDuration(_waitDuration);
        bgColor = Colors.orange.shade100;
        fgColor = Colors.orange.shade900;
        break;
      case TripStatus.EN_VIAJE:
        label = "Tiempo de Viaje";
        timeValue = _formatDuration(_travelDuration);
        bgColor = Colors.green.shade100;
        fgColor = Colors.green.shade900;
        break;
      case TripStatus.DESTINO_LLEGADO:
        isMessageMode = true;
        label = "Tiempo enviado, revise el método de pago";
        bgColor = Colors.purple.shade50;
        fgColor = Colors.purple.shade800;
        break;
      default:
        break;
    }

    if (isMessageMode) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fgColor.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: fgColor),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: TextStyle(
              fontWeight: FontWeight.w600, color: fgColor, letterSpacing: 1.2)),
          const SizedBox(height: 5),
          Text(
            timeValue,
            style: TextStyle(fontSize: 32,
                fontWeight: FontWeight.bold,
                color: fgColor,
                fontFamily: 'RobotoMono'),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleActionButton() {
    String buttonText = '';
    Color buttonColor = Colors.blue;
    VoidCallback? onPressedAction = _showConfirmationDialog;

    switch (_currentStatus) {
      case TripStatus.EN_CAMINO:
        buttonText = 'Llegué al punto de encuentro';
        buttonColor = Colors.blue.shade700;
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        buttonText = 'Comenzar Viaje';
        buttonColor = Colors.green.shade700;
        break;
      case TripStatus.EN_VIAJE:
        buttonText = 'Terminar Viaje';
        buttonColor = Colors.red.shade700;
        break;
      default:
        buttonText = 'Procesando...';
        onPressedAction = null;
    }

    return ElevatedButton(
      onPressed: onPressedAction,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(buttonText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          const Text('HISTORIAL:', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 15),
          ..._tripTimeline
              .asMap()
              .entries
              .map((entry) {
            int index = entry.key;
            TripEvent event = entry.value;
            bool isCompleted = event.timestamp != null;
            bool isLast = index == _tripTimeline.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimelineItem(event, isCompleted, index),
                if (!isLast) _buildTimelineConnector(isCompleted),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TripEvent event, bool isCompleted, int index) {
    Color iconColor = isCompleted ? Colors.green.shade600 : Colors.grey
        .shade300;
    Color textColor = isCompleted ? Colors.black87 : Colors.grey.shade500;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: iconColor, size: 22),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.description,
                style: TextStyle(
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight
                        .normal, color: textColor, fontSize: 15),
              ),
              const SizedBox(height: 4),
              _buildColoredTimestamp(event, isCompleted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColoredTimestamp(TripEvent event, bool isCompleted) {
    if (!isCompleted) return const SizedBox.shrink();

    // FORMATEAR HORA PARA MOSTRAR LA DEL RELOJ
    String formattedTime = event.timestamp!.toLocal().toString().substring(
        11, 16);

    Color timeColor = Colors.grey.shade600;
    String statusSuffix = "";

    if (event.status == TripStatus.EN_PUNTO_ENCUENTRO &&
        event.expectedTime != null && event.timestamp != null) {
      final diff = event.timestamp!.difference(event.expectedTime!).inMinutes;
      if (diff < -5) {
        timeColor = Colors.green[700]!;
        statusSuffix = " (Temprano)";
      } else if (diff >= -5 && diff <= 5) {
        timeColor = Colors.amber[800]!;
        statusSuffix = " (A tiempo)";
      } else {
        timeColor = Colors.red[700]!;
        statusSuffix = " (Tarde)";
      }
    }

    return Text(
      'Hora: $formattedTime$statusSuffix',
      style: TextStyle(
          fontSize: 12, color: timeColor, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTimelineConnector(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(left: 10, bottom: 0),
      padding: const EdgeInsets.symmetric(vertical: 2),
      height: 20,
      width: 2,
      color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
    );
  }

  Widget _buildPaymentSection() {
    bool isPaid = _currentStatus == TripStatus.PAGO_COMPLETADO;
    // CORRECCIÓN: Usamos "post" en minúscula para que funcione con toLowerCase()
    bool esPostPago = widget.tipoPago!.toLowerCase().contains("post");

    // ---------------------------------------------------------
    // CASO 1: CUALQUIER VIAJE TERMINADO (Ya cobrado)
    // ---------------------------------------------------------
    if (isPaid) {
      // AQUÍ LA LÓGICA DEL TEXTO QUE PEDISTE:
      String textoFinal = esPostPago
          ? "Viaje Postpago terminado"
          : "Viaje por convenio terminado";
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Mensaje simple de finalización
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.blue.shade800),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      textoFinal, // <--- AQUÍ ESTABA EL ERROR (antes decía el texto fijo)
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900
                    ),
                  ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón Único de Salida
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainLayoutScreen(),
                    ),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Volver al inicio",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // ---------------------------------------------------------
    // CASO 2: PAGO MANUAL (Postpago) - Muestra detalles y cobro
    // ---------------------------------------------------------
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL A COBRAR:',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(children: [
                  const Icon(
                      Icons.payments_outlined, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _tipoPago,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    height: 25,
                    width: 1.5,
                    color: Colors.grey.shade300,
                  ),
                  Text(
                    _montoViaje,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue.shade900),
                  )
                ]),
              ),
              if (isPaid)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                      Icons.check_circle, color: Colors.green, size: 28),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (!isPaid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStatus = TripStatus.PAGO_COMPLETADO;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Pago confirmado. Fin del servicio.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Confirmar Cobro",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
            )
          else
            Column(
              children: [
                Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200)),
                    child: Center(
                        child: Text("Cobro Realizado Correctamente",
                            style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold)))),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainLayoutScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Volver al inicio",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold))),
                ),
              ],
            )
        ],
      ),
    );
  }
}