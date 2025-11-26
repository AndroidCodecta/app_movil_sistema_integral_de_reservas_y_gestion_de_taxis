// Archivo: 'solicitudes_page.dart'
import 'package:flutter/material.dart';
import '../../utils/session_manager.dart'; // Importaciones originales
import '../../utils/solicitud_service.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

class SolicitudesPage extends StatefulWidget {
  const SolicitudesPage({super.key});

  @override
  State<SolicitudesPage> createState() => _SolicitudesPageState();
}

class _SolicitudesPageState extends State<SolicitudesPage> {
  // Las solicitudes ahora contienen la data de la RESERVA (que incluye cliente, etc.)
  List<Map<String, dynamic>> solicitudes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSolicitudes();
  }

  // Función de carga de solicitudes (ahora más simple gracias al SolicitudService corregido)
  Future<void> _loadSolicitudes() async {
    if (solicitudes.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // 1. Llamamos al servicio (que ahora extrae 'reservas_solicitudes'['data'])
      final rawData = await SolicitudService.listarSolicitudes();

      // 2. Convertimos la data limpia
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
        setState(() {
          _isLoading = false;
        });
        // Muestra el error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar solicitudes: ${e.toString()}'),
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

      final mensaje = estado == 1
          ? 'Solicitud aceptada correctamente'
          : 'Solicitud rechazada';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: estado == 1 ? Colors.green : Colors.red,
        ),
      );

      // El ID de la solicitud de chofer está ANIDADO
      // Lo que se debe eliminar de la lista local es la RESERVA,
      // cuyo ID es el 'id' del elemento de la lista.
      setState(() {
        // Usamos el id de la SOLICITUD_CHOFER para la condición de eliminación
        solicitudes.removeWhere((s) {
          final solicitudChofer =
              s['solicitud_chofer'] as Map<String, dynamic>?;
          final idSolicitudChofer = solicitudChofer?['id'];

          // Compara el ID de la solicitud_chofer con el ID que se acaba de responder
          return idSolicitudChofer != null &&
              idSolicitudChofer.toString() == solicitudChoferId.toString();
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget para el estado de lista vacía que permite recargar
  Widget _buildEmptyStateWithRefresh(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSolicitudes, // Conecta la función de recarga
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(child: Text('No hay solicitudes pendientes')),
            ),
          );
        },
      ),
    );
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
                  ? _buildEmptyStateWithRefresh(context)
                  : RefreshIndicator(
                      onRefresh: _loadSolicitudes,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: solicitudes.length,
                        itemBuilder: (context, index) {
                          final s = solicitudes[index];

                          // La data de la reserva es 's' misma en este endpoint, pero
                          // tu código original usaba 'reserva', lo corrijo para usar 's' directamente.
                          // Pero lo más importante: extraemos la SOLICITUD_CHOFER para obtener el ID de respuesta.
                          final reserva = s; // s es la reserva
                          final cliente = reserva['cliente'] ?? {};
                          final solicitudChofer =
                              reserva['solicitud_chofer'] ?? {};

                          // ESTA ES LA CLAVE PARA PASAR EL ID CORRECTO A LA FUNCIÓN DE RESPUESTA
                          final idSolicitudChofer =
                              int.tryParse(
                                solicitudChofer['id']?.toString() ?? '0',
                              ) ??
                              0;

                          final nombreCliente =
                              '${cliente['nombres'] ?? ''} ${cliente['apellidos'] ?? ''}'
                                  .trim()
                                  .isEmpty
                              ? 'Usuario'
                              : '${cliente['nombres']} ${cliente['apellidos']}';

                          final fechaCompleta =
                              reserva['fecha_hora']?.toString() ?? '---';
                          final partesFechaHora = fechaCompleta.split(' ');
                          final fecha = partesFechaHora.isNotEmpty
                              ? partesFechaHora[0]
                              : '---';
                          final hora = partesFechaHora.length > 1
                              ? partesFechaHora[1]
                              : '---';

                          final espera =
                              reserva['tiempo_espera']?.toString() ?? '---';
                          final direccion =
                              reserva['d_encuentro']?.toString() ?? '---';

                          return Column(
                            children: [
                              _SolicitudCard(
                                cliente: nombreCliente,
                                fecha: fecha,
                                hora: hora,
                                espera: espera,
                                direccion: direccion,
                                // Pasamos el ID de la solicitud_chofer ANIDADA
                                onAceptar: () =>
                                    _responderSolicitud(idSolicitudChofer, 1),
                                onRechazar: () =>
                                    _responderSolicitud(idSolicitudChofer, 0),
                              ),
                              const SizedBox(height: 16),
                            ],
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

class _SolicitudCard extends StatelessWidget {
  // ... (El código de _SolicitudCard se mantiene igual)
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
            Text(
              'Cliente: $cliente',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Fecha de reserva: $fecha'),
            const SizedBox(height: 4),
            Row(children: [Text('Hora Recogida: $hora')]),
            Row(
              children: [
                const Text(
                  'Tiempo de espera: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
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
