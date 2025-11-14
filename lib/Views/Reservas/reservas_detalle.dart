import 'package:flutter/material.dart';
import '/utils/reservas_service.dart'; // ¡USAMOS EL NUEVO SERVICE!
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';
import '../Maps/maps_page.dart';

// =================================================================
// CLASE MODELO (ReservaDetalleModel) - NECESARIA PARA PARSEAR EL DETALLE COMPLETO
// Se extrae de la API con los datos anidados (cliente, vehiculo)
// =================================================================
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
  });

  // Método de fábrica para crear una instancia desde un mapa JSON
  factory ReservaDetalleModel.fromJson(Map<String, dynamic> data) {
    final cliente = data["cliente"] as Map<String, dynamic>? ?? {};
    final vehiculo = data["vehiculo"] as Map<String, dynamic>? ?? {};
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
    );
  }
}

// =================================================================
// PANTALLA DE DETALLE (ReservaDetalleCompletoScreen) - Ahora carga por ID
// =================================================================
class ReservaDetalleCompletoScreen extends StatefulWidget {
  final int reservaId; // ¡Ahora recibe el ID!
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

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  // Función de carga de datos que se usa para la carga inicial y el refresh
  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // LLAMADA CORREGIDA: Usamos el nuevo service y el ID
    final data = await ReservasService.fetchReservaDetalle(widget.reservaId);

    if (data != null) {
      try {
        final ReservaDetalleModel reservaCompleta =
            ReservaDetalleModel.fromJson(data);

        setState(() {
          _reservaDetalle = reservaCompleta;
        });
      } catch (e) {
        print("Error al parsear datos: $e");
        setState(() {
          _errorMessage = "Error al procesar los datos de la reserva.";
        });
      }
    } else {
      setState(() {
        _errorMessage =
            "No se pudo cargar el detalle de la reserva ID: ${widget.reservaId}.";
      });
    }

    setState(() {
      _isLoading = false;
    });
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

  // CONTENEDOR PRINCIPAL: Usa BoxDecoration (SIN CANVAS)
  Widget _buildDetailContainer(ReservaDetalleModel reserva) {
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
          // Header principal
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
              'Reserva N° 00${reserva.id}',
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
                // 1. Información General
                _buildSectionTitle('Información de la Reserva'),
                _buildInfoRow('Fecha:', reserva.fechaReserva),
                _buildInfoRow('Hora:', reserva.horaRecogida),
                _buildInfoRow('Tiempo de Espera:', reserva.tiempoEspera),

                const Divider(height: 30),

                // 2. Cliente y Ubicaciones
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

                // 3. Auto Asignado
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

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapsScreen()),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
      ),
    );
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
                // ----------------------------------------------------
                // IMPLEMENTACIÓN DEL REFRESHINDICATOR
                // ----------------------------------------------------
                : RefreshIndicator(
                    onRefresh:
                        _fetchDetail, // <-- Conecta la función de recarga
                    child: SingleChildScrollView(
                      // Asegura que siempre se puede deslizar para recargar
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
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}
