import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/header.dart';
// Asegúrate de que la ruta sea correcta según tu estructura de carpetas
import '/utils/viajes_service.dart';

enum TripStatus {
  EN_CAMINO,
  EN_PUNTO_ENCUENTRO,
  EN_VIAJE,
  DESTINO_LLEGADO,
  PAGO_COMPLETADO
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

  const MapsScreen({
    super.key,
    this.viajeIniciado = false,
    this.reservaId,
    this.montoViaje,
    this.tipoPago,
    this.direccionOrigen,
    this.direccionDestino,
    this.fechaHoraProgramadaStr,
  });

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late String _montoViaje;
  late String _tipoPago;
  TripStatus _currentStatus = TripStatus.EN_CAMINO;
  late List<TripEvent> _tripTimeline;

  final Stopwatch _waitStopwatch = Stopwatch();
  final Stopwatch _travelStopwatch = Stopwatch();
  Timer? _timer;

  Duration _waitDuration = Duration.zero;
  Duration _travelDuration = Duration.zero;
  DateTime? _scheduledTime;
  bool _isWaitingForScheduledTime = false;

  String _selectedPaymentMethod = "Efectivo";
  final TextEditingController _observacionController = TextEditingController();
  final List<String> _paymentMethods = ["Efectivo", "Yape", "PLIN"];

  @override
  void initState() {
    super.initState();
    _montoViaje = "S/. ${widget.montoViaje ?? '0.00'}";
    _tipoPago = widget.tipoPago ?? "Efectivo";

    if (widget.fechaHoraProgramadaStr != null) {
      try {
        _scheduledTime = DateTime.parse(widget.fechaHoraProgramadaStr!.trim());
      } catch (e) {
        debugPrint("Error parseando fecha programada: $e");
        _scheduledTime = DateTime.now();
      }
    }

    _tripTimeline = [
      TripEvent(TripStatus.EN_CAMINO, 'En camino al punto de encuentro'),
      TripEvent(TripStatus.EN_PUNTO_ENCUENTRO, 'Llegada al punto de encuentro'),
      TripEvent(TripStatus.EN_VIAJE, 'Viaje iniciado'),
      TripEvent(TripStatus.DESTINO_LLEGADO, 'Llegada al destino'),
    ];

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
    _observacionController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        final now = DateTime.now();

        if (_currentStatus == TripStatus.EN_PUNTO_ENCUENTRO) {
          if (_scheduledTime != null && now.isBefore(_scheduledTime!)) {
            _isWaitingForScheduledTime = true;
          } else {
            _isWaitingForScheduledTime = false;
            if (!_waitStopwatch.isRunning) {
              _waitStopwatch.start();
            }
          }
          if (_waitStopwatch.isRunning) {
            _waitDuration = _waitStopwatch.elapsed;
          }
        }

        if (_currentStatus == TripStatus.EN_VIAJE) {
          if (!_travelStopwatch.isRunning) {
            _travelStopwatch.start();
          }
          _travelDuration = _travelStopwatch.elapsed;
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
    if (widget.reservaId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFD60A))),
    );

    bool success = false;
    final int id = widget.reservaId!;

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
          success = await ViajesService.finalizarViaje(id);
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
            const SnackBar(content: Text("Error de conexión."), backgroundColor: Colors.red));
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
            _waitStopwatch.stop();
            _travelStopwatch.start();
            break;
          case TripStatus.DESTINO_LLEGADO:
            _travelStopwatch.stop();
            _timer?.cancel();
            bool esConvenio = _tipoPago.toLowerCase().contains("crédito") ||
                _tipoPago.toLowerCase().contains("corporativo") ||
                _tipoPago.toLowerCase().contains("vale") ||
                _tipoPago.toLowerCase().contains("convenio");
            if (esConvenio) {
              _currentStatus = TripStatus.PAGO_COMPLETADO;
            }
            break;
          case TripStatus.PAGO_COMPLETADO:
            break;
          case TripStatus.EN_CAMINO:
            break;
        }
      }
    });
  }

  Future<void> _handlePaymentSubmit() async {
    if (widget.reservaId == null) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    bool success = await ViajesService.registrarPagoAdicional(
      reservaId: widget.reservaId!,
      metodo: _selectedPaymentMethod,
      observacion: _observacionController.text,
      statusPago: 1,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      setState(() => _currentStatus = TripStatus.PAGO_COMPLETADO);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al registrar cobro'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showConfirmationDialog() async {
    String title = "";
    String content = "";

    switch (_currentStatus) {
      case TripStatus.EN_CAMINO:
        title = "Confirmar Llegada";
        content = "¿Estás en el punto de encuentro?";
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        title = "Comenzar Viaje";
        if (_isWaitingForScheduledTime) {
          content = "Aún falta para la hora programada. ¿Deseas iniciar el viaje de todos modos?";
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

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
              child: const Text('Confirmar'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleButtonAction();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showingPaymentUI = _currentStatus == TripStatus.DESTINO_LLEGADO ||
        _currentStatus == TripStatus.PAGO_COMPLETADO;

    // --- CORRECCIÓN CLAVE: Usamos Scaffold en lugar de Container ---
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo gris claro
      body: Column(
        children: [
          const LogoHeader(titulo: 'Viaje en Curso', estiloLogin: false),

          if (widget.viajeIniciado)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAddressCard(),
                    const SizedBox(height: 15),

                    if (_currentStatus != TripStatus.PAGO_COMPLETADO)
                      _buildDynamicTimer(),

                    const SizedBox(height: 20),

                    if (!showingPaymentUI)
                      _buildSingleActionButton(),

                    const SizedBox(height: 20),

                    _buildTimeline(),

                    if (showingPaymentUI) ...[
                      const SizedBox(height: 20),
                      _buildPaymentSection(),
                    ]
                  ],
                ),
              ),
            )
          else
            const Expanded(child: Center(child: Text('No tienes un viaje en curso'))),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildAddressRow(Icons.my_location, Colors.green, "Origen", widget.direccionOrigen ?? "---"),
          const Padding(
            padding: EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(height: 16, child: VerticalDivider(color: Colors.grey, thickness: 1)),
            ),
          ),
          _buildAddressRow(Icons.location_on, Colors.red, "Destino", widget.direccionDestino ?? "---"),
        ],
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, Color color, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        )
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
        if (_scheduledTime != null) {
          String hora = "${_scheduledTime!.hour.toString().padLeft(2,'0')}:${_scheduledTime!.minute.toString().padLeft(2,'0')}";
          subLabel = "Hora prog: $hora";
        }
        bgColor = Colors.blue.shade50;
        fgColor = Colors.blue.shade800;
        break;

      case TripStatus.EN_PUNTO_ENCUENTRO:
        if (_isWaitingForScheduledTime) {
          label = "ANTICIPADO";
          timeValue = "ESPERANDO";
          if (_scheduledTime != null) {
            final diff = _scheduledTime!.difference(DateTime.now());
            subLabel = "Faltan ${diff.inMinutes} min";
          }
          bgColor = Colors.amber.shade100;
          fgColor = Colors.amber.shade900;
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
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: fgColor, fontSize: 13, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(timeValue, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: fgColor)),
          if (subLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subLabel, style: TextStyle(fontSize: 13, color: fgColor.withOpacity(0.9))),
          ]
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
      label: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HISTORIAL:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          ..._tripTimeline.asMap().entries.map((entry) {
            bool isCompleted = entry.value.timestamp != null;
            String timeStr = isCompleted
                ? "${entry.value.timestamp!.hour.toString().padLeft(2,'0')}:${entry.value.timestamp!.minute.toString().padLeft(2,'0')}"
                : "";

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? Colors.green : Colors.grey[300], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.value.description, style: TextStyle(fontSize: 13, color: isCompleted ? Colors.black87 : Colors.grey, fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal)),
                  ),
                  if (timeStr.isNotEmpty)
                    Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    bool esConvenio = _tipoPago.toLowerCase().contains("crédito") || _tipoPago.toLowerCase().contains("corporativo") || _tipoPago.toLowerCase().contains("vale") || _tipoPago.toLowerCase().contains("convenio");

    if (_currentStatus == TripStatus.PAGO_COMPLETADO) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 10),
            Text(esConvenio ? "Viaje Finalizado" : "Pago Registrado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
            const SizedBox(height: 4),
            Text(esConvenio ? "El servicio por convenio ha concluido." : "Cobro exitoso.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayoutScreen()), (route) => false),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD60A), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 45)),
              child: const Text("VOLVER AL INICIO", style: TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("REGISTRAR COBRO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), Chip(label: Text(_tipoPago, style: const TextStyle(fontSize: 11)), backgroundColor: Colors.blue.shade50, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)]),
          const Divider(),
          Center(child: Text(_montoViaje, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.blue.shade900))),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(value: _selectedPaymentMethod, isDense: true, decoration: InputDecoration(labelText: "Método de Pago", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)), items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14)))).toList(), onChanged: (v) => setState(() => _selectedPaymentMethod = v!)),
          const SizedBox(height: 12),
          TextField(controller: _observacionController, decoration: InputDecoration(labelText: "Observación (Opcional)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)), maxLines: 2, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 15),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _handlePaymentSubmit, icon: const Icon(Icons.attach_money, size: 20), label: const Text("CONFIRMAR COBRO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
        ],
      ),
    );
  }
}