import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

class SolicitudesPage extends StatelessWidget {
  const SolicitudesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const LogoHeader(titulo: 'Solicitudes', estiloLogin: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SolicitudCard(
                    cliente: 'Jorge Alberto Gonzáles Heredia',
                    fecha: '28/08/2025',
                    hora: '2:00 PM',
                    espera: '----',
                    direccion: 'Campoy, San Juan de Lurigancho, Perú',
                  ),
                  const SizedBox(height: 16),
                  _SolicitudCard(
                    cliente: 'Jorge Alberto Gonzáles Heredia',
                    fecha: '28/08/2025',
                    hora: '2:00 PM',
                    espera: '2:00h',
                    direccion: 'Campoy, San Juan de Lurigancho, Perú',
                  ),
                ],
              ),
            ),
            const CustomBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final String cliente;
  final String fecha;
  final String hora;
  final String espera;
  final String direccion;

  const _SolicitudCard({
    required this.cliente,
    required this.fecha,
    required this.hora,
    required this.espera,
    required this.direccion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Solicitud',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: $cliente',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Fecha de reserva: $fecha'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Hora Recogida: $hora'),
                const SizedBox(width: 16),
                Text(
                  'Tiempo de espera: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  espera,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Dirección de encuentro: $direccion'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('Aceptar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
