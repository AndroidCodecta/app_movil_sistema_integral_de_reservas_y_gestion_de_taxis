import 'reservas_detalle.dart';
import 'package:flutter/material.dart';
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
class ReservasScreen extends StatelessWidget {
  const ReservasScreen({super.key});

  // Datos de prueba para reservas
  static final List<ReservaDetalle> reservasPrueba = [
    ReservaDetalle(
      cliente: "Jorge Alberto González Heredia",
      fechaReserva: "28/08/2025",
      horaRecogida: "2:00 PM",
      direccionEncuentro: "Campoy, San Juan de Lurigancno, Perú",
    ),
    ReservaDetalle(
      cliente: "Jorge Alberto González Heredia",
      fechaReserva: "28/08/2025",
      horaRecogida: "2:00 PM",
      direccionEncuentro: "Campoy, San Juan de Lurigancno, Perú",
    ),
    ReservaDetalle(
      cliente: "Jorge Alberto González Heredia",
      fechaReserva: "28/08/2025",
      horaRecogida: "2:00 PM",
      direccionEncuentro: "Campoy, San Juan de Lurigancno, Perú",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Reservas', estiloLogin: false),

          // Lista de reservas
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: reservasPrueba
                    .map((reserva) => ReservaDetalleCard(reserva: reserva))
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

// Widget para cada card de reserva detallada
class ReservaDetalleCard extends StatelessWidget {
  final ReservaDetalle reserva;

  const ReservaDetalleCard({super.key, required this.reserva});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReservaDetalleCompletoScreen(reserva: reserva),
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
                color: Colors.amber,
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
                  _buildInfoRow('Cliente:', reserva.cliente),
                  const SizedBox(height: 8),
                  _buildInfoRow('Fecha de reserva:', reserva.fechaReserva),
                  const SizedBox(height: 8),
                  _buildInfoRow('Hora Recogida:', reserva.horaRecogida),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Dirección de encuentro:',
                    reserva.direccionEncuentro,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}
