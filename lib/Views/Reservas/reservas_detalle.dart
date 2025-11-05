import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';
import '../Maps/maps_page.dart';

class ReservaDetalleCompletoScreen extends StatelessWidget {
  final dynamic reserva;
  const ReservaDetalleCompletoScreen({super.key, required this.reserva});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Detalle Reserva', estiloLogin: false),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Un solo container para toda la información
                  Container(
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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Detalle de la reserva',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Información de reserva
                              const Text(
                                'Información de reserva',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Fecha: ${reserva.fechaReserva}'),
                              Text('Hora: ${reserva.horaRecogida}'),
                              Text(
                                'Dirección de encuentro: ${reserva.direccionEncuentro}',
                              ),
                              const Divider(height: 24),
                              // Información del cliente
                              const Text(
                                'Información del cliente',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Cliente: ${reserva.cliente}'),
                              const Divider(height: 24),
                              // Auto asignado
                              const Text(
                                'Auto asignado',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Image.network(
                                    'https://www.shutterstock.com/image-vector/car-icon-48x48-perfect-pixel-260nw-1171602043.jpg',
                                    width: 80,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text('Placa: ABC-123'),
                                      Text('Marca: Mazda'),
                                      Text('Modelo: CX-5'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- BOTÓN INICIAR VIAJE (NUEVO) ---
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navega a MapsScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapsScreen(),
                        ),
                      );
                      // Nota: El contador de tiempo muerto (WAITING_INITIAL)
                      // se inicia automáticamente en el initState de MapsScreen.
                    },
                    icon: const Icon(Icons.navigation_sharp, size: 28),
                    label: const Text(
                      'Iniciar Viaje',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ), // Color distintivo para acción
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
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
