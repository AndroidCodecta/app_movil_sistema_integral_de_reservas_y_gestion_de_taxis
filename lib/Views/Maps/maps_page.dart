import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/header.dart';
// Asegúrate de que la ruta sea correcta según tu proyecto
import '/utils/viajes_service.dart';

enum TripStatus {
  EN_CAMINO,           // 1. Chofer va en camino
  EN_PUNTO_ENCUENTRO,  // 2. Llegó (Esperando al pasajero)
  EN_VIAJE,            // 3. Inició viaje (Llevando al pasajero)
  DESTINO_LLEGADO,     // 4. Llegó al destino (Esperando cobro manual)
  PAGO_COMPLETADO      // 5. Fin (Ya se cobró o era convenio)
}

class TripEvent {
  final TripStatus status;
  final String description;
  DateTime? timestamp;
  DateTime? expectedTime;

  TripEvent(this.status, this.description, {this.timestamp, this.expectedTime});
}

class MapsScreen extends StatefulWidget {
  final bool viajeIniciado;
  final int? reservaId;
  final DateTime? horaEsperadaRecogidaReal;
  final String? montoViaje;
  final String? tipoPago; // Ej: "Efectivo", "Crédito Corporativo", "Vale"

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

  final Stopwatch _waitStopwatch = Stopwatch();
  final Stopwatch _travelStopwatch = Stopwatch();
  Timer? _timer;

  Duration _waitDuration = Duration.zero;
  Duration _travelDuration = Duration.zero;

  // Variables para el Pago
  String _selectedPaymentMethod = "Efectivo";
  final TextEditingController _observacionController = TextEditingController();
  final List<String> _paymentMethods = ["Efectivo", "Yape", "PLIN"];

  @override
  void initState() {
    super.initState();
    _montoViaje = "S/. ${widget.montoViaje ?? '0.00'}";
    _tipoPago = widget.tipoPago ?? "Efectivo";

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

  // --- LÓGICA DE TIEMPO ---
  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_waitStopwatch.isRunning) _waitDuration = _waitStopwatch.elapsed;
          if (_travelStopwatch.isRunning) _travelDuration = _travelStopwatch.elapsed;
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

  // --- LÓGICA PRINCIPAL (API y CAMBIO DE ESTADO) ---
  Future<void> _handleButtonAction() async {
    if (widget.reservaId == null) return;

    // 1. Mostrar Carga
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
        // Aquí termina el viaje en el servidor (3er seguimiento)
          success = await ViajesService.finalizarViaje(id);
          break;
        default:
          success = true;
          break;
      }
    } catch (e) {
      debugPrint("Error API: $e");
    }

    if (mounted) Navigator.pop(context); // Cerrar carga

    if (success) {
      _advanceLocalState();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al conectar con el servidor."), backgroundColor: Colors.red));
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

        // Marcar check en el timeline
        for (var event in _tripTimeline) {
          if (event.status == nextStatus) {
            event.timestamp = DateTime.now();
            break;
          }
        }

        // Manejo de Cronómetros y LÓGICA DE PAGO
        switch (nextStatus) {
          case TripStatus.EN_PUNTO_ENCUENTRO:
            _startTicker();
            _waitStopwatch.start();
            break;

          case TripStatus.EN_VIAJE:
            _waitStopwatch.stop();
            _travelStopwatch.start();
            break;

          case TripStatus.DESTINO_LLEGADO:
            _travelStopwatch.stop();
            _timer?.cancel();

            // --- AQUÍ ESTÁ LA LÓGICA CLAVE ---
            // Si es CONVENIO, saltamos el paso de cobro manual y vamos directo al FIN.
            bool esConvenio = _tipoPago.toLowerCase().contains("crédito") ||
                _tipoPago.toLowerCase().contains("corporativo") ||
                _tipoPago.toLowerCase().contains("vale");

            if (esConvenio) {
              // Saltamos directo al estado final
              _currentStatus = TripStatus.PAGO_COMPLETADO;
            }
            // Si NO es convenio (es efectivo/yape), se queda en DESTINO_LLEGADO
            // lo cual mostrará el formulario de pago en _buildPaymentSection
            break;

          case TripStatus.PAGO_COMPLETADO:
            break;
          case TripStatus.EN_CAMINO:
            break;
        }
      }
    });
  }

  // --- LÓGICA DE COBRO MANUAL (POST-PAGO) ---
  Future<void> _handlePaymentSubmit() async {
    if (widget.reservaId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFD60A))),
    );

    // Consumir API pago_adicional
    bool success = await ViajesService.registrarPagoAdicional(
      reservaId: widget.reservaId!,
      metodo: _selectedPaymentMethod,
      observacion: _observacionController.text,
      statusPago: 1,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      setState(() {
        _currentStatus = TripStatus.PAGO_COMPLETADO;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobro registrado correctamente'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar cobro'), backgroundColor: Colors.red));
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
        content = "¿El pasajero subió al vehículo?";
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
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
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
    // Si ya llegamos al final (PAGO_COMPLETADO) o estamos cobrando (DESTINO_LLEGADO)
    bool showingPaymentUI = _currentStatus == TripStatus.DESTINO_LLEGADO ||
        _currentStatus == TripStatus.PAGO_COMPLETADO;

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          const LogoHeader(titulo: 'Viaje en Curso', estiloLogin: false),

          if (widget.viajeIniciado)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ocultamos el timer si ya terminamos
                    if (_currentStatus != TripStatus.PAGO_COMPLETADO)
                      _buildDynamicTimer(),

                    const SizedBox(height: 30),

                    // Botón principal de acciones (Llegué, Iniciar, Terminar)
                    if (!showingPaymentUI)
                      _buildSingleActionButton(),

                    const SizedBox(height: 30),
                    _buildTimeline(),

                    // Sección de Pago / Finalización
                    if (showingPaymentUI)
                      _buildPaymentSection(),

                    const SizedBox(height: 20),
                  ],
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

  Widget _buildDynamicTimer() {
    String label = "Estado";
    String timeValue = "--:--:--";
    Color bgColor = Colors.grey.shade200;
    Color fgColor = Colors.grey.shade700;

    switch (_currentStatus) {
      case TripStatus.EN_CAMINO:
        label = "EN CAMINO";
        bgColor = Colors.blue.shade50;
        fgColor = Colors.blue.shade800;
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        label = "ESPERANDO PASAJERO";
        timeValue = _formatDuration(_waitDuration);
        bgColor = Colors.orange.shade100;
        fgColor = Colors.orange.shade900;
        break;
      case TripStatus.EN_VIAJE:
        label = "EN RUTA AL DESTINO";
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: fgColor, letterSpacing: 1.1)),
          if (timeValue != "--:--:--") ...[
            const SizedBox(height: 5),
            Text(timeValue, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: fgColor)),
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
        buttonText = 'Llegué al Punto de Encuentro';
        buttonColor = Colors.blue.shade700;
        icon = Icons.location_on;
        break;
      case TripStatus.EN_PUNTO_ENCUENTRO:
        buttonText = 'COMENZAR VIAJE';
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
      icon: Icon(icon, size: 28),
      label: Text(buttonText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          const Text('HISTORIAL DEL VIAJE:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          ..._tripTimeline.asMap().entries.map((entry) {
            bool isCompleted = entry.value.timestamp != null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCompleted ? Colors.green : Colors.grey[300], size: 20),
                  const SizedBox(width: 10),
                  Text(entry.value.description,
                      style: TextStyle(color: isCompleted ? Colors.black87 : Colors.grey,
                          fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    // Si el estado es PAGO_COMPLETADO, mostramos la pantalla de "Volver al Inicio"
    // Esto ocurre automáticamente para Convenio, o después de pagar para Efectivo.
    if (_currentStatus == TripStatus.PAGO_COMPLETADO) {
      bool esConvenio = _tipoPago.toLowerCase().contains("crédito") ||
          _tipoPago.toLowerCase().contains("corporativo");

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            Text(
              esConvenio ? "Viaje Finalizado" : "Pago Registrado",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
            const SizedBox(height: 5),
            Text(
              esConvenio ? "El servicio por convenio ha concluido." : "El cobro en $_selectedPaymentMethod fue exitoso.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD60A),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("VOLVER AL INICIO", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // Si no está completado, significa que estamos en DESTINO_LLEGADO y NO es convenio.
    // Mostramos el formulario de cobro.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("REGISTRAR COBRO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Chip(label: Text(_tipoPago), backgroundColor: Colors.blue.shade50),
            ],
          ),
          const Divider(),
          Center(
            child: Text(_montoViaje, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blue.shade900)),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: InputDecoration(
              labelText: "Método de Pago",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _observacionController,
            decoration: InputDecoration(
              labelText: "Observación (Opcional)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handlePaymentSubmit,
              icon: const Icon(Icons.attach_money),
              label: const Text("CONFIRMAR COBRO", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}