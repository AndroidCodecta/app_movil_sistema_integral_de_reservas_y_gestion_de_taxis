// Archivo: 'reservas_page.dart'

import 'package:flutter/material.dart';
import '/utils/reservas_service.dart';
import 'reservas_detalle.dart'; // Importa la pantalla de detalle
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

// --- WIDGET PRINCIPAL: ReservasScreen ---

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  // Usamos fetchReservasList (todas las reservas activas)
  List<Map<String, dynamic>> reservas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  // Función de carga de datos que se usa para la carga inicial y el refresh
  Future<void> _loadReservas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservasData = await ReservasService.fetchReservasList();

      if (mounted) {
        setState(() {
          // Asumo que fetchReservasList devuelve List<Map<String, dynamic>>
          // Si devuelve List<dynamic>, podría ser necesario castear aquí, pero
          // confiaremos en la inferencia por el momento, ya que la falla es en el card.
          reservas = reservasData;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar reservas: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error al cargar las reservas. Intente de nuevo.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                : _errorMessage != null
                ? Center(child: Text('Error: $_errorMessage'))
                : reservas.isEmpty
                ? RefreshIndicator(
                    onRefresh: _loadReservas,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: _buildEmptyState(),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReservas,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: reservas.length,
                      itemBuilder: (context, index) {
                        final reservaData = reservas[index];
                        final int reservaId = reservaData["id"] ?? 0;

                        return ReservaDetalleCard(
                          reservaData: reservaData,
                          onTap: (id) async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
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
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  // --- WIDGET DE ESTADO VACÍO ---
  Widget _buildEmptyState() {
    return const Center(child: Text("No tienes reservas 🚗"));
  }
}

// --- WIDGET DE TARJETA: ReservaDetalleCard (Utilizado en la lista) ---

class ReservaDetalleCard extends StatelessWidget {
  final Map<String, dynamic> reservaData;
  final Function(int id) onTap;

  const ReservaDetalleCard({
    super.key,
    required this.reservaData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int id = reservaData["id"] ?? 0;

    // 🚨 CORRECCIÓN CLAVE: Casteamos el mapa anidado a Map<String, dynamic>
    // Esto asegura que podemos acceder a los campos "nombres" y "apellidos" correctamente.
    final Map<String, dynamic> cliente = (reservaData["cliente"] is Map)
        ? reservaData["cliente"] as Map<String, dynamic>
        : <String, dynamic>{};

    final nombreCliente =
        "${cliente["nombres"] ?? ""} ${cliente["apellidos"] ?? ""}".trim();

    final fechaHora = reservaData["fecha_hora"]?.toString() ?? "";
    final fecha = fechaHora.isNotEmpty ? fechaHora.split(" ")[0] : "---";
    final hora = fechaHora.split(" ").length > 1
        ? fechaHora.split(" ")[1].substring(0, 5)
        : "---";

    final direccion = reservaData["d_encuentro"] ?? "Sin dirección";

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
                'Reserva N° ${id.toString().padLeft(4, '0')}',
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
