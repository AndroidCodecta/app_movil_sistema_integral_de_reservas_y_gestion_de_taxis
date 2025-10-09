import 'package:flutter/material.dart';
import '../../utils/session_manager.dart';
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
    print('Solicitudes cargadas: $data');
    // Filtrar entradas inválidas o vacías que puedan haberse guardado como Map
    List<Map<String, dynamic>> filtered = [];
    for (final item in data) {
      if (item.isEmpty) continue;

      bool valid = false;

      // Si tiene campo 'cliente' con datos
      if (item['cliente'] != null) {
        final c = item['cliente'];
        if (c is Map) {
          final nombres = (c['nombres'] ?? '').toString().trim();
          final apellidos = (c['apellidos'] ?? '').toString().trim();
          if ((nombres + apellidos).trim().isNotEmpty) valid = true;
        } else if (c.toString().trim().isNotEmpty) {
          valid = true;
        }
      }

      // Campos alternativos comunes
      for (final key in [
        'fecha',
        'fecha_hora',
        'hora',
        'direccion',
        'd_encuentro',
        'direccionEncuentro',
      ]) {
        if (!valid &&
            item[key] != null &&
            item[key].toString().trim().isNotEmpty) {
          valid = true;
          break;
        }
      }

      if (valid) {
        filtered.add(Map<String, dynamic>.from(item));
      }
    }

    // Depuración: muestra conteo original y filtrado
    // ignore: avoid_print
    print('Solicitudes válidas: ${filtered.length} / ${data.length}');

    setState(() {
      solicitudes = filtered;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const LogoHeader(titulo: 'Solicitudes', estiloLogin: false),
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

                        final cliente = s['cliente']?.toString() ?? 'Usuario';
                        final fecha = s['fecha']?.toString() ?? '---';
                        final hora = s['hora']?.toString() ?? '---';
                        final espera = s['espera']?.toString() ?? '---';
                        final direccion = s['direccion']?.toString() ?? '---';

                        return Column(
                          children: [
                            _SolicitudCard(
                              cliente: cliente,
                              fecha: fecha,
                              hora: hora,
                              espera: espera,
                              direccion: direccion,
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
