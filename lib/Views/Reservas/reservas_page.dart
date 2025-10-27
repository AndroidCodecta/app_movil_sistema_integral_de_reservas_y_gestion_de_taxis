import 'package:flutter/material.dart';
import '../../utils/session_manager.dart';
import 'reservas_detalle.dart';
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

  factory ReservaDetalle.fromMap(Map<String, dynamic> map) {
    return ReservaDetalle(
      cliente: map['cliente']?.toString() ?? 'Usuario',
      fechaReserva: map['fecha']?.toString() ?? '---',
      horaRecogida: map['hora_recogida']?.toString() ?? '---',
      direccionEncuentro: map['d_encuentro']?.toString() ?? '---',
    );
  }
}

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<ReservaDetalle> reservas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  Future<void> _loadReservas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await SessionManager.fetchReservasFromApi();

      final parsed = data.map((e) => ReservaDetalle.fromMap(e)).toList();

      setState(() {
        reservas = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

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
                  : _error != null
                  ? Center(
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
                  : reservas.isEmpty
                  ? const Center(child: Text('No hay reservas'))
                  : RefreshIndicator(
                onRefresh: _loadReservas,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservas.length,
                  itemBuilder: (context, index) {
                    final reserva = reservas[index];
                    return Padding(
                      padding:
                      const EdgeInsets.only(bottom: 16.0),
                      child: ReservaDetalleCard(reserva: reserva),
                    );
                  },
                ),
              ),
            ),
            const CustomBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

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
                child: const Center(
                  child: Text(
                    'Reserva',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cliente: ${reserva.cliente}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Fecha: ${reserva.fechaReserva}'),
              const SizedBox(height: 4),
              Text('Hora: ${reserva.horaRecogida}'),
              const SizedBox(height: 4),
              Text('Dirección: ${reserva.direccionEncuentro}'),
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
