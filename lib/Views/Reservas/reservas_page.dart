import 'package:flutter/material.dart';
import '/utils/reservas_service.dart';
import 'reservas_detalle.dart'; // Importa la nueva pantalla de detalle (se asume que existe)
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

// --- WIDGET PRINCIPAL: ReservasScreen ---

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<Map<String, dynamic>> reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  Future<void> _loadReservas() async {
    final reservasData = await ReservasService.fetchReservasList();
    setState(() {
      reservas = reservasData;
      _isLoading = false;
    });
  }

  // Recarga la lista si la pantalla de detalle devuelve 'true'
  void _onDetailClosed(dynamic result) {
    if (result == true) {
      _loadReservas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Reservas', estiloLogin: false),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD60A)),
                  )
                : reservas.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: reservas.length,
                    itemBuilder: (context, index) {
                      final reservaData = reservas[index];
                      final int reservaId = reservaData["id"] ?? 0;

                      return ReservaDetalleCard(
                        reservaData: reservaData,
                        onTap: (id) async {
                          // Navegación con ID
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Usamos el ID para cargar el detalle
                              builder: (context) =>
                                  ReservaDetalleCompletoScreen(reservaId: id),
                            ),
                          );
                          _onDetailClosed(result);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
    );
  }
}

// --- WIDGET DE TARJETA: ReservaDetalleCard ---

class ReservaDetalleCard extends StatelessWidget {
  final Map<String, dynamic> reservaData;
  final Function(int id) onTap; // Callback que recibe el ID

  const ReservaDetalleCard({
    super.key,
    required this.reservaData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int id = reservaData["id"] ?? 0;
    final cliente = reservaData["cliente"] ?? {};
    final nombreCliente =
        "${cliente["nombres"] ?? ""} ${cliente["apellidos"] ?? ""}".trim();

    final fechaHora = reservaData["fecha_hora"]?.toString() ?? "";
    final fecha = fechaHora.isNotEmpty ? fechaHora.split(" ")[0] : "---";
    final hora = fechaHora.split(" ").length > 1
        ? fechaHora.split(" ")[1].substring(0, 5)
        : "---";

    final direccion = reservaData["d_encuentro"] ?? "Sin dirección";
    final vehiculo = reservaData["vehiculo"] ?? {};
    final placa = vehiculo["placa"]?.toString() ?? "N/A";

    if (id == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => onTap(id),
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
            // Header amarillo
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
              child: Text(
                'Reserva N° 00$id',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                  _buildInfoRow('Fecha y Hora:', '$fecha - $hora'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Dirección de encuentro:', direccion),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => onTap(id),
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

// --- CLASE OBSOLETA ---
// Mantener solo si es usada por un sistema de navegación antiguo, de lo contrario, eliminar.
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
