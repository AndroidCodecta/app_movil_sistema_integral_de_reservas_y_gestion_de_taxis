import 'package:flutter/material.dart';
import '../../utils/session_manager.dart'; // Mantengo los imports originales
import 'reservas_detalle.dart'; // Mantengo los imports originales
import '../widgets/header.dart'; // Mantengo los imports originales
import '../widgets/bottom_navigation.dart'; // Mantengo los imports originales

// =======================================================
// MODELO DE DATOS DE UNA RESERVA
// =======================================================
class ReservaDetalle {
  final String id; // <--- AÑADIDO: ID de la reserva
  final String cliente;
  final String fechaReserva;
  final String horaRecogida;
  final String direccionEncuentro;

  ReservaDetalle({
    required this.id, // <--- AÑADIDO
    required this.cliente,
    required this.fechaReserva,
    required this.horaRecogida,
    required this.direccionEncuentro,
  });

  factory ReservaDetalle.fromMap(Map<String, dynamic> map) {
    return ReservaDetalle(
      id: map['id']?.toString() ?? 'N/A', // <--- USADO: id con fallback
      cliente: map['cliente']?.toString() ?? 'Usuario',
      fechaReserva: map['fechaReserva']?.toString() ?? '---',
      horaRecogida: map['horaRecogida']?.toString() ?? '---',
      direccionEncuentro: map['direccionEncuentro']?.toString() ?? '---',
    );
  }
}

// =======================================================
// PANTALLA DE RESERVAS (VERSIÓN DEMO SIN API)
// =======================================================
class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<ReservaDetalle> reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservasDemo();
  }

  // =======================================================
  // DEMO: CARGA RESERVAS DE MUESTRA SIN CONECTAR AL SERVIDOR
  // =======================================================
  Future<void> _loadReservasDemo() async {
    await Future.delayed(const Duration(seconds: 1)); // simula carga
    final mockData = [
      {
        'id': 'R1001', // <--- AÑADIDO ID DE MUESTRA
        'cliente': 'Juan Pérez',
        'fechaReserva': '2025-10-14',
        'horaRecogida': '09:00 AM',
        'direccionEncuentro': 'Av. Siempre Viva 742',
      },
      {
        'id': 'R1002', // <--- AÑADIDO ID DE MUESTRA
        'cliente': 'María López',
        'fechaReserva': '2025-10-15',
        'horaRecogida': '02:30 PM',
        'direccionEncuentro': 'Calle Las Flores 128',
      },
      {
        'id': 'R1003', // <--- AÑADIDO ID DE MUESTRA
        'cliente': 'Carlos Rojas',
        'fechaReserva': '2025-10-16',
        'horaRecogida': '07:45 AM',
        'direccionEncuentro': 'Jr. Los Cedros 255',
      },
    ];

    setState(() {
      reservas = mockData.map((e) => ReservaDetalle.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  // =======================================================
  // CONSTRUCCIÓN DE LA INTERFAZ
  // =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const LogoHeader(titulo: 'Reservas', estiloLogin: false),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reservas.isEmpty
                  ? const Center(child: Text('No hay reservas'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reservas.length,
                itemBuilder: (context, index) {
                  final reserva = reservas[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ReservaDetalleCard(reserva: reserva),
                  );
                },
              ),
            ),
            const CustomBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// TARJETA VISUAL DE CADA RESERVA
// =======================================================
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
      child: Card(
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
                child: Center(
                  // <--- MODIFICADO: Uso de reserva.id
                  child: Text(
                    'Nro. Reserva: ${reserva.id}',
                    style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${reserva.cliente}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Fecha de reserva: ${reserva.fechaReserva}'),
              const SizedBox(height: 4),
              Text('Hora Recogida: ${reserva.horaRecogida}'),
              const SizedBox(height: 4),
              Text('Dirección de encuentro: ${reserva.direccionEncuentro}'),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReservaDetalleCompletoScreen(reserva: reserva),
                      ),
                    );
                  },
                  child: const Text(
                    'Ver Detalles >',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}