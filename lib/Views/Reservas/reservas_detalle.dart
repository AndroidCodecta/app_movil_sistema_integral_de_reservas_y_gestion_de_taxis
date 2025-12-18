import 'package:flutter/material.dart';
import '/utils/reservas_service.dart';
import '../widgets/header.dart';
import '/utils/viajes_service.dart';
import '../widgets/bottom_navigation.dart';

class ReservasDetalleTipoPago {
  final String tipoPago;
  final String monto;
  final String metodoPago;

  ReservasDetalleTipoPago({
    required this.tipoPago,
    required this.monto,
    required this.metodoPago,
  });

  factory ReservasDetalleTipoPago.fromJson(Map<String, dynamic> data) {
    final pagoAdicional = (data["pago_adicional"] is Map)
        ? data["pago_adicional"] as Map<String, dynamic>
        : <String, dynamic>{};

    return ReservasDetalleTipoPago(
      tipoPago: pagoAdicional["descripcion"]?.toString() ?? "N/A",
      monto: pagoAdicional["monto"]?.toString() ?? "0.00",
      metodoPago: pagoAdicional["metodo"]?.toString() ?? "N/A",
    );
  }
}

class ReservaDetalleModel {
  final int id;
  final String cliente;
  final String fechaReserva;
  final String horaRecogida;
  final String tiempoEspera;
  final String direccionEncuentro;
  final String direccionDestino;
  final String placa;
  final String marca;
  final String anioModelo;
  final ReservasDetalleTipoPago? detallePago;

  ReservaDetalleModel({
    required this.id,
    required this.cliente,
    required this.fechaReserva,
    required this.horaRecogida,
    required this.tiempoEspera,
    required this.direccionEncuentro,
    required this.direccionDestino,
    required this.placa,
    required this.marca,
    required this.anioModelo,
    this.detallePago,
  });

  factory ReservaDetalleModel.fromJson(Map<String, dynamic> data) {
    final cliente = (data["cliente"] is Map)
        ? data["cliente"] as Map<String, dynamic>
        : <String, dynamic>{};
    final vehiculo = (data["vehiculo"] is Map)
        ? data["vehiculo"] as Map<String, dynamic>
        : <String, dynamic>{};

    ReservasDetalleTipoPago? pagoDetalle;
    if (data.containsKey("pago_adicional") && data["pago_adicional"] != null) {
      try {
        pagoDetalle = ReservasDetalleTipoPago.fromJson(data);
      } catch (e) {
        debugPrint("Error al parsear el detalle de pago: $e");
      }
    }

    final fechaHora = data["fecha_hora"]?.toString() ?? "";
    return ReservaDetalleModel(
      id: data["id"] ?? 0,
      cliente: "${cliente["nombres"] ?? ""} ${cliente["apellidos"] ?? ""}"
          .trim(),
      fechaReserva: fechaHora.isNotEmpty ? fechaHora.split(" ")[0] : "---",
      horaRecogida: fechaHora.split(" ").length > 1
          ? fechaHora.split(" ")[1].substring(0, 5)
          : "---",
      tiempoEspera: data["tiempo_espera"]?.toString() ?? "N/A",
      direccionEncuentro: data["d_encuentro"]?.toString() ?? "N/A",
      direccionDestino: data["d_destino"]?.toString() ?? "N/A",
      placa: vehiculo["placa"]?.toString() ?? "N/A",
      marca: vehiculo["marca"]?.toString() ?? "N/A",
      anioModelo: vehiculo["año_modelo"]?.toString() ?? "N/A",
      detallePago: pagoDetalle,
    );
  }
}

class ReservaDetalleCompletoScreen extends StatefulWidget {
  final int reservaId;

  const ReservaDetalleCompletoScreen({super.key, required this.reservaId});

  @override
  State<ReservaDetalleCompletoScreen> createState() =>
      _ReservaDetalleCompletoScreenState();
}

class _ReservaDetalleCompletoScreenState
    extends State<ReservaDetalleCompletoScreen> {
  ReservaDetalleModel? _reservaDetalle;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isTripInProgress = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await ReservasService.fetchReservaDetalle(widget.reservaId);

    if (data != null && mounted) {
      try {
        final ReservaDetalleModel reservaCompleta =
            ReservaDetalleModel.fromJson(data);
        setState(() {
          _reservaDetalle = reservaCompleta;
        });
      } catch (e) {
        debugPrint("Error al parsear datos de detalle: $e");
        setState(() {
          _errorMessage = "Error al procesar los datos de la reserva.";
        });
      }
    } else if (mounted) {
      setState(() {
        _errorMessage =
            "No se pudo cargar el detalle de la reserva ID: ${widget.reservaId}.";
      });
    }

    // Chequear si hay viaje en curso para esta reserva
    final ongoingData = await ViajesService.getReservaEnCurso();
    if (ongoingData != null && ongoingData.containsKey("seguimiento")) {
      final ongoingReservaId = ongoingData["seguimiento"]["reserva_id"];
      if (ongoingReservaId == widget.reservaId) {
        setState(() {
          _isTripInProgress = true;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color(0xFF1C1C1C),
        ),
      ),
    );
  }

  Widget _buildDetailContainer(ReservaDetalleModel reserva) {
    final tipoPago = reserva.detallePago;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Reserva N° ${reserva.id.toString().padLeft(4, '0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Información de la Reserva'),
                _buildInfoRow('Fecha:', reserva.fechaReserva),
                _buildInfoRow('Hora:', reserva.horaRecogida),
                _buildInfoRow('Tiempo de Espera:', reserva.tiempoEspera),
                const Divider(height: 30),
                _buildSectionTitle('Cliente y Ubicaciones'),
                _buildInfoRow('Cliente:', reserva.cliente),
                _buildInfoRow(
                  'Dirección de Encuentro:',
                  reserva.direccionEncuentro,
                ),
                _buildInfoRow(
                  'Dirección de Destino:',
                  reserva.direccionDestino,
                ),
                const Divider(height: 30),
                _buildSectionTitle('Método de Pago'),
                if (tipoPago != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Tipo de Pago:', tipoPago.tipoPago),
                      _buildInfoRow('Monto:', 'S/ ${tipoPago.monto}'),
                    ],
                  )
                else
                  _buildInfoRow('Información de Pago:', 'No especificado'),
                const Divider(height: 30),
                _buildSectionTitle('Detalles del Vehículo'),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: Color.fromARGB(255, 0, 0, 0),
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Placa: ${reserva.placa}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Marca: ${reserva.marca}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        Text(
                          'Modelo/Año: ${reserva.anioModelo}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Función auxiliar para mostrar un SnackBar de error
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (_isTripInProgress) {
      // Botón para ver viaje en curso
      return ElevatedButton.icon(
        onPressed: () {
          // Navegar directamente al mapa, donde cargará el ongoing trip
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainLayoutScreen(initialIndex: 3),
            ),
            (route) => false,
          );
        },
        icon: const Icon(Icons.map, size: 28),
        label: const Text(
          'Ver Viaje en Curso',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
      );
    } else {
      // Botón para iniciar viaje (lógica original)
      return ElevatedButton.icon(
        onPressed: () async {
          if (_reservaDetalle == null) return;
          final reserva = _reservaDetalle!;

          // Construir fecha/hora programada correctamente
          final String fechaHoraStr =
              "${reserva.fechaReserva} ${reserva.horaRecogida}:00";
          DateTime fechaHoraProgramada;
          try {
            fechaHoraProgramada = DateTime.parse(fechaHoraStr);
          } catch (e) {
            debugPrint('Error parseando fecha/hora: $e');
            _showErrorSnackbar('Error en formato de fecha/hora.');
            return;
          }

          final DateTime now = DateTime.now();
          final DateTime today = DateTime(now.year, now.month, now.day);
          final DateTime reservaDate = DateTime(
            fechaHoraProgramada.year,
            fechaHoraProgramada.month,
            fechaHoraProgramada.day,
          );

          // Validaciones
          if (reservaDate != today) {
            _showErrorSnackbar('Solo puedes iniciar reservas de hoy.');
            return;
          }

          final DateTime limiteAnticipacion = fechaHoraProgramada.subtract(
            const Duration(hours: 3),
          );
          if (now.isBefore(limiteAnticipacion)) {
            _showErrorSnackbar('Solo puedes iniciar hasta 3 horas antes.');
            return;
          }

          if (now.isAfter(fechaHoraProgramada)) {
            _showErrorSnackbar('La reserva ya venció.');
            return;
          }

          // Mostrar loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD60A)),
            ),
          );

          // NO llamar confirmarLlegada aquí - el chofer lo hará manualmente en el mapa

          if (mounted) Navigator.pop(context); // cerrar loading

          // === Navegar al mapa con viaje iniciado en EN_CAMINO ===
          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainLayoutScreen(
                initialIndex: 3, // Mapa
                viajeIniciado: true,
                reservaId: reserva.id,
                montoViaje: reserva.detallePago?.monto,
                tipoPago: reserva.detallePago?.tipoPago,
                direccionOrigen: reserva.direccionEncuentro,
                direccionDestino: reserva.direccionDestino,
                fechaHoraProgramadaStr: fechaHoraStr,
              ),
            ),
            (route) => false,
          );
        },
        icon: const Icon(Icons.navigation_sharp, size: 28),
        label: const Text(
          'Iniciar Viaje',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Detalle Reserva', estiloLogin: false),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD60A)),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDetail,
                          child: const Text('Reintentar Carga'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchDetail,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_reservaDetalle != null)
                            _buildDetailContainer(_reservaDetalle!),
                          const SizedBox(height: 20),
                          _buildActionButton(context),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
