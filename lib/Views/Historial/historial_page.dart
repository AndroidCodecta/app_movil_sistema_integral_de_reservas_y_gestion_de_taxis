import 'package:flutter/material.dart';
// ⚠️ IMPORTACIONES REQUERIDAS
// Asumiendo que ReservaDetalle está en la siguiente ruta (ajusta si es necesario)
import '../Reservas/reservas_detalle.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

// =======================================================
// MODELO DE DATOS PARA EL HISTORIAL (Ampliado de ReservaDetalle)
// =======================================================
class ReservaHistorial {
  final String id;
  final String cliente;
  final String fechaReserva;
  final String horaRecogida;
  final String direccionEncuentro;
  final double costoTotal;
  final int? calificacion; // Se mantiene en el modelo por si se usa en otro lado, pero se ignora en la UI.

  ReservaHistorial({
    required this.id,
    required this.cliente,
    required this.fechaReserva,
    required this.horaRecogida,
    required this.direccionEncuentro,
    required this.costoTotal,
    this.calificacion,
  });

  factory ReservaHistorial.fromMap(Map<String, dynamic> map) {
    return ReservaHistorial(
      id: map['id']?.toString() ?? 'N/A',
      cliente: map['cliente']?.toString() ?? 'Usuario Desconocido',
      fechaReserva: map['fechaReserva']?.toString() ?? '---',
      horaRecogida: map['horaRecogida']?.toString() ?? '---',
      direccionEncuentro: map['direccionEncuentro']?.toString() ?? '---',
      costoTotal: (map['costoTotal'] as num?)?.toDouble() ?? 0.00,
      calificacion: map['calificacion'] as int?,
    );
  }
}

// =======================================================
// PANTALLA DE HISTORIAL
// =======================================================
class HistorialPage extends StatelessWidget {

  // DATOS DE EJEMPLO
  final List<ReservaHistorial> _finishedReservations = [
    ReservaHistorial(
      id: '001',
      cliente: 'Laura Vásquez',
      fechaReserva: '2025-09-20',
      horaRecogida: '17:30',
      direccionEncuentro: 'Av. Libertador 456',
      costoTotal: 15.75,
      calificacion: 5,
    ),
    ReservaHistorial(
      id: '002',
      cliente: 'Pedro Torres',
      fechaReserva: '2025-09-18',
      horaRecogida: '10:00',
      direccionEncuentro: 'Jr. Los Álamos 301',
      costoTotal: 8.90,
      calificacion: 4,
    ),
    ReservaHistorial(
      id: '003',
      cliente: 'Ana Jiménez',
      fechaReserva: '2025-09-17',
      horaRecogida: '21:00',
      direccionEncuentro: 'Plaza Mayor',
      costoTotal: 22.50,
      calificacion: null,
    ),
  ];

  HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Historial', estiloLogin: false),
          Expanded(
            child: _finishedReservations.isEmpty
                ? const Center(
              child: Text(
                'No hay viajes finalizados en tu historial.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _finishedReservations.length,
              itemBuilder: (context, index) {
                final reserva = _finishedReservations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: HistorialCard(reserva: reserva),
                );
              },
            ),
          ),
          const CustomBottomNavBar(),
        ],
      ),
    );
  }
}

// =======================================================
// TARJETA DE HISTORIAL (ACTUALIZADA sin Calificación)
// =======================================================
class HistorialCard extends StatelessWidget {
  final ReservaHistorial reserva;

  const HistorialCard({super.key, required this.reserva});

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER AMARILLO: ID de Viaje y Costo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Viaje Nro: ${reserva.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  // Muestra el costo total del viaje
                  '\$${reserva.costoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Color.fromARGB(255, 11, 102, 35), // Color verde oscuro
                  ),
                ),
              ],
            ),
          ),

          // 2. CUERPO DE DETALLES
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info principal del viaje
                const Text(
                  'Detalles del Viaje',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoRow('Cliente:', reserva.cliente),
                _buildInfoRow('Fecha:', reserva.fechaReserva),
                _buildInfoRow('Hora:', reserva.horaRecogida),
                _buildInfoRow('Dirección:', reserva.direccionEncuentro),

                const Divider(height: 24),

                // Auto asignado (datos fijos de ejemplo)
                const Text(
                  'Auto utilizado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 40, color: Colors.grey),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Placa: ABC-123', style: TextStyle(fontSize: 14)),
                        Text('Marca: Mazda', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),

                // NOTA: Se eliminó la sección de Calificación aquí.
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' $value'),
          ],
        ),
      ),
    );
  }
}