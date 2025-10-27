import 'package:flutter/material.dart';
import '../../utils/session_manager.dart';
import '../../utils/solicitud_service.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

class SolicitudesPage extends StatefulWidget {
  const SolicitudesPage({super.key});

  @override
  State<SolicitudesPage> createState() => _SolicitudesPageState();
}

class _SolicitudesPageState extends State<SolicitudesPage> {
  List<Map<String, dynamic>> solicitudes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSolicitudes();
  }

  Future<void> _loadSolicitudes() async {
    final data = await SessionManager.getSolicitudes();
    List<Map<String, dynamic>> registros = [];

    if (data.isNotEmpty) {
      final primer = data.first;
      if (primer.containsKey('data') && primer['data'] is List) {
        registros = List<Map<String, dynamic>>.from(primer['data']);
      } else if (data is List) {
        registros = List<Map<String, dynamic>>.from(data);
      }
    }

    setState(() {
      solicitudes = registros;
      _isLoading = false;
    });
  }

  Future<void> _responderSolicitud(int solicitudChoferId, int estado) async {
    try {
      await SolicitudService.responderSolicitud(
        solicitudChoferId: solicitudChoferId,
        estado: estado,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estado == 1
              ? 'Solicitud aceptada correctamente'
              : 'Solicitud rechazada'),
          backgroundColor: estado == 1 ? Colors.green : Colors.red,
        ),
      );

      // eliminar la solicitud de la lista local
      setState(() {
        solicitudes.removeWhere(
                (s) => s['id'] == solicitudChoferId || s['solicitud_chofer_id'] == solicitudChoferId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const LogoHeader(titulo: 'Asignaciones', estiloLogin: false),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : solicitudes.isEmpty
                  ? const Center(child: Text('No hay solicitudes'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: solicitudes.length,
                itemBuilder: (context, index) {
                  final s = solicitudes[index];
                  final reserva = s['reserva'] ?? {};
                  final cliente = reserva['cliente'] ?? {};
                  final idSolicitud = s['id'] ?? s['solicitud_chofer_id'] ?? 0;

                  final nombreCliente =
                  '${cliente['nombres'] ?? ''} ${cliente['apellidos'] ?? ''}'
                      .trim()
                      .isEmpty
                      ? 'Usuario'
                      : '${cliente['nombres']} ${cliente['apellidos']}';

                  final fecha = reserva['fecha_hora']?.toString() ?? '---';
                  final espera = reserva['tiempo_espera']?.toString() ?? '---';
                  final direccion =
                      reserva['d_encuentro']?.toString() ?? '---';

                  return Column(
                    children: [
                      _SolicitudCard(
                        cliente: nombreCliente,
                        fecha: fecha.split(' ')[0],
                        hora: fecha.split(' ').length > 1
                            ? fecha.split(' ')[1]
                            : '---',
                        espera: espera,
                        direccion: direccion,
                        onAceptar: () =>
                            _responderSolicitud(idSolicitud, 1),
                        onRechazar: () =>
                            _responderSolicitud(idSolicitud, 0),
                      ),
                      const SizedBox(height: 16),
                    ],
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

class _SolicitudCard extends StatelessWidget {
  final String cliente;
  final String fecha;
  final String hora;
  final String espera;
  final String direccion;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  const _SolicitudCard({
    required this.cliente,
    required this.fecha,
    required this.hora,
    required this.espera,
    required this.direccion,
    required this.onAceptar,
    required this.onRechazar,
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
                  'Asignación',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Cliente: $cliente',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Fecha de reserva: $fecha'),
            const SizedBox(height: 4),
            Row(children: [Text('Hora Recogida: $hora')]),
            Row(
              children: [
                const Text('Tiempo de espera: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(espera, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: onAceptar,
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
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: onRechazar,
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
