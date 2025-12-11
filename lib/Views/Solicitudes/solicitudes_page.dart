import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    if (solicitudes.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final rawData = await SolicitudService.listarSolicitudes();
      final List<Map<String, dynamic>> registros =
      List<Map<String, dynamic>>.from(rawData);

      if (mounted) {
        setState(() {
          solicitudes = registros;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando solicitudes: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _responderSolicitud(int solicitudChoferId, int estado) async {
    try {
      await SolicitudService.responderSolicitud(
        solicitudChoferId: solicitudChoferId,
        estado: estado,
      );

      final mensaje =
      estado == 1 ? 'Solicitud aceptada' : 'Solicitud rechazada';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: estado == 1 ? Colors.green : Colors.red,
          ),
        );
      }

      setState(() {
        solicitudes.removeWhere((s) {
          final solicitudChofer =
          s['solicitud_chofer'] as Map<String, dynamic>?;
          final id = solicitudChofer?['id'];
          return id != null && id.toString() == solicitudChoferId.toString();
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyStateWithRefresh(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSolicitudes,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: Text('No hay asignaciones pendientes'),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        extendBody: true,
        body: Column(
          children: [
            const LogoHeader(titulo: 'Asignaciones', estiloLogin: false),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : solicitudes.isEmpty
                  ? _buildEmptyStateWithRefresh(context)
                  : RefreshIndicator(
                onRefresh: _loadSolicitudes,
                child: ListView.separated(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 0, bottom: 100),
                  itemCount: solicitudes.length,
                  separatorBuilder: (ctx, index) =>
                  const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final s = solicitudes[index];
                    final reserva = s;
                    final cliente = reserva['cliente'] ?? {};
                    final solicitudChofer =
                        reserva['solicitud_chofer'] ?? {};

                    final idSolicitudChofer = int.tryParse(
                        solicitudChofer['id']?.toString() ??
                            '0') ??
                        0;

                    final nombreCliente =
                    '${cliente['nombres'] ?? ''} ${cliente['apellidos'] ?? ''}'
                        .trim()
                        .isEmpty
                        ? 'Usuario'
                        : '${cliente['nombres']} ${cliente['apellidos']}';

                    final clienteTipo =
                    (cliente['empresa_id'] != null)
                        ? 'Por convenio'
                        : 'Libre';

                    final fechaCompleta =
                        reserva['fecha_hora']?.toString() ?? '---';
                    final partesFecha = fechaCompleta.split(' ');
                    final fecha = partesFecha.isNotEmpty
                        ? partesFecha[0]
                        : '---';
                    final hora = partesFecha.length > 1
                        ? partesFecha[1]
                        : '---';

                    final espera =
                        reserva['tiempo_espera']?.toString() ?? '---';
                    final origen =
                        reserva['d_encuentro']?.toString() ?? '---';
                    final destino =
                        reserva['d_destino']?.toString() ?? '---';
                    final precio =
                        reserva['precio']?.toString() ?? '---';

                    return _SolicitudCard(
                      cliente: nombreCliente,
                      fecha: fecha,
                      hora: hora,
                      espera: espera,
                      origen: origen,
                      destino: destino,
                      precio: precio,
                      clienteTipo: clienteTipo,
                      onAceptar: () =>
                          _responderSolicitud(idSolicitudChofer, 1),
                      onRechazar: () =>
                          _responderSolicitud(idSolicitudChofer, 0),
                    );
                  },
                ),
              ),
            ),
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
  final String origen;
  final String destino;
  final String precio;
  final String clienteTipo;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  const _SolicitudCard({
    required this.cliente,
    required this.fecha,
    required this.hora,
    required this.espera,
    required this.origen,
    required this.destino,
    required this.precio,
    required this.clienteTipo,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
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
            const SizedBox(height: 16),
            Text(
              'Cliente: $cliente',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            // Text('Fecha: $fecha  •  Hora: $hora'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tipo: $clienteTipo',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$precio',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Fecha y hora: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(espera),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text('Origen: $origen')),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text('Destino: $destino')),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onAceptar,
                    child:
                    const Text('Aceptar', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onRechazar,
                    child:
                    const Text('Rechazar', style: TextStyle(fontSize: 16)),
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