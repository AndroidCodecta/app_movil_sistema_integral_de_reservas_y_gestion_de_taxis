import 'reservas_detalle.dart';
import 'package:flutter/material.dart';
import '../../Utils/session_manager.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

class ReservaDetalle {
  final String cliente;
  final String fechaReserva;
  final String horaRecogida;
  final String direccionEncuentro;

  ReservaDetalle({
    required this.cliente,
    required this.fechaReserva,
    required this.horaRecogida,
    required this.direccionEncuentro,
  });
}

// Widget principal de la pantalla Reservas
class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  Future<void> _loadReservas() async {
    final reservasData = await SessionManager.getReservas();
    setState(() {
      reservas = reservasData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Reservas', estiloLogin: false),

          // Lista de reservas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : reservas.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "No tienes reservas 🚗",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: reservas
                          .where((r) => r != null && r is Map && r.isNotEmpty)
                          .map(
                            (reservaData) => ReservaDetalleCard(
                              reservaData: reservaData as Map<String, dynamic>,
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

// 🔥 WIDGET ARREGLADO - Muestra datos de la API correctamente
class ReservaDetalleCard extends StatelessWidget {
  final Map<String, dynamic> reservaData;

  const ReservaDetalleCard({super.key, required this.reservaData});

  @override
  Widget build(BuildContext context) {
    // Extraer datos de la API
    final cliente = reservaData["cliente"] ?? {};
    final nombreCliente =
        "${cliente["nombres"] ?? ""} ${cliente["apellidos"] ?? ""}".trim();

    final fechaHora = reservaData["fecha_hora"]?.toString() ?? "";
    final fecha = fechaHora.isNotEmpty ? fechaHora.split(" ")[0] : "---";
    final hora = fechaHora.split(" ").length > 1
        ? fechaHora.split(" ")[1]
        : "---";

    final direccion = reservaData["d_encuentro"] ?? "Sin dirección";

    return GestureDetector(
      onTap: () {
        // Convertir datos para la pantalla de detalle completo
        final reservaDetalle = ReservaDetalle(
          cliente: nombreCliente,
          fechaReserva: fecha,
          horaRecogida: hora,
          direccionEncuentro: direccion,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReservaDetalleCompletoScreen(reserva: reservaDetalle),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
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
          children: [
            // Header amarillo con "Reserva"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD60A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Reserva',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Contenido de la reserva
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Cliente:', nombreCliente),
                  const SizedBox(height: 8),
                  _buildInfoRow('Fecha de reserva:', fecha),
                  const SizedBox(height: 8),
                  _buildInfoRow('Hora Recogida:', hora),
                  const SizedBox(height: 8),
                  _buildInfoRow('Dirección de encuentro:', direccion),
                  const SizedBox(height: 12),

                  // Botón Ver Detalles
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        final reservaDetalle = ReservaDetalle(
                          cliente: nombreCliente,
                          fechaReserva: fecha,
                          horaRecogida: hora,
                          direccionEncuentro: direccion,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReservaDetalleCompletoScreen(
                              reserva: reservaDetalle,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver Detalles >',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
