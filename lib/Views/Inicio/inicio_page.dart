import 'package:flutter/material.dart';
import '../Reservas/reservas_detalle.dart';
import '../Reservas/reservas_page.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Datos de prueba
  static final List<ReservaDetalle> reservasPrueba = [
    ReservaDetalle(
      cliente: "Jorge Alberto González Heredia",
      fechaReserva: "28/08/2025",
      horaRecogida: "2:00 PM",
      direccionEncuentro: "Campoy, San Juan de Lurigancho, Perú",
    ),
    ReservaDetalle(
      cliente: "Jorge Alberto González Heredia",
      fechaReserva: "28/08/2025",
      horaRecogida: "2:00 PM",
      direccionEncuentro: "Campoy, San Juan de Lurigancho, Perú",
    ),
    ReservaDetalle(
      cliente: "Jorge Alberto González Heredia",
      fechaReserva: "28/08/2025",
      horaRecogida: "2:00 PM",
      direccionEncuentro: "Campoy, San Juan de Lurigancho, Perú",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Inicio', estiloLogin: false),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Botones de estado
                  const StatusButtons(),
                  const SizedBox(height: 16),

                  // Lista de reservas con datos de prueba
                  ...reservasPrueba.map(
                    (reserva) => ReservaCard(reserva: reserva),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

class StatusButtons extends StatelessWidget {
  const StatusButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(255, 214, 10, 1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: const Text(
            'Estado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Activo - botón interactivo sin navegación
        AnimatedActiveButton(),
        const SizedBox(height: 8),

        // Resumen de hoy - botón navegable
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReservasScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(255, 214, 10, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Resumen de hoy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Botón animado para estado activo/inactivo
class AnimatedActiveButton extends StatefulWidget {
  const AnimatedActiveButton({super.key});

  @override
  State<AnimatedActiveButton> createState() => _AnimatedActiveButtonState();
}

class _AnimatedActiveButtonState extends State<AnimatedActiveButton> {
  bool activo = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          activo = !activo;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo
              ? const Color.fromARGB(255, 104, 230, 119)
              : Colors.redAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          activo ? 'Activo' : 'Inactivo',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Widget para cada card de reserva (solo UI)
class ReservaCard extends StatelessWidget {
  final ReservaDetalle reserva;

  const ReservaCard({super.key, required this.reserva});

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
            // Header de Auto y Reserva
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Auto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 255, 214, 10),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reserva',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Placa: ABC-123',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            'Marca: Mazda',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            'Modelo: CX-5',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Información de la reserva
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Cliente:', reserva.cliente),
                        _buildInfoRow(
                          'Fecha de reserva:',
                          reserva.fechaReserva,
                        ),
                        _buildInfoRow('Hora Recogida:', reserva.horaRecogida),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
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
