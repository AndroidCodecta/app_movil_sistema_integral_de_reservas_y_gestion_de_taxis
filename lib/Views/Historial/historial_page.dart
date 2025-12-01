// Archivo: 'historial_page.dart'

import 'package:flutter/material.dart';
import 'dart:async';
// 🚨 Importación clave para la navegación a la vista de detalle
import 'historial_detalle.dart';
import '/utils/reservas_service.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

// =======================================================
// MODELO DE DATOS PARA EL HISTORIAL (Para la lista)
// =======================================================
class ReservaHistorial {
  final String id;
  final String cliente;
  final String fechaReserva;
  final String horaRecogida;
  final String direccionEncuentro;
  final String dDestino;

  ReservaHistorial({
    required this.id,
    required this.cliente,
    required this.fechaReserva,
    required this.horaRecogida,
    required this.direccionEncuentro,
    required this.dDestino,
  });

  factory ReservaHistorial.fromMap(Map<String, dynamic> map) {
    // --- 1. MANEJO SEGURO DEL CLIENTE ---
    String nombreCliente = 'Usuario Desconocido';
    final Map<String, dynamic>? clienteData =
        map['cliente'] as Map<String, dynamic>?;

    if (clienteData != null) {
      final String nombres = clienteData['nombres']?.toString() ?? '';
      final String apellidos = clienteData['apellidos']?.toString() ?? '';

      final String nombreCompleto = '$nombres $apellidos'.trim();
      nombreCliente = nombreCompleto.isNotEmpty
          ? nombreCompleto
          : 'Cliente Desconocido';
    }

    // --- 2. MANEJO SEGURO DE FECHA Y HORA ---
    final String fechaHora = map['fecha_hora']?.toString() ?? '';
    List<String> partesFechaHora = fechaHora.split(' ');

    String fecha = partesFechaHora.isNotEmpty ? partesFechaHora[0] : '---';

    String hora = '---';
    if (partesFechaHora.length > 1) {
      final String horaCompleta = partesFechaHora[1];
      if (horaCompleta.length >= 5) {
        hora = horaCompleta.substring(0, 5); // Toma HH:MM
      }
    }

    return ReservaHistorial(
      id: map['id']?.toString() ?? 'N/A',
      cliente: nombreCliente,
      fechaReserva: fecha,
      horaRecogida: hora,
      direccionEncuentro:
          map['d_encuentro']?.toString() ??
          'Dirección de encuentro no disponible',
      dDestino: map['d_destino']?.toString() ?? 'Destino no disponible',
    );
  }
}

// =======================================================
// PANTALLA DE HISTORIAL
// =======================================================
class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  List<ReservaHistorial> _finishedReservations = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ⚠️ Usando fetchReservasList, ajusta esto si tienes una función específica para historial (ej: fetchReservasHistorial)
      final List<Map<String, dynamic>> rawData =
          await ReservasService.fetchReservasList();

      final List<ReservaHistorial> historial = rawData
          .map((map) => ReservaHistorial.fromMap(map))
          .toList();

      if (mounted) {
        setState(() {
          _finishedReservations = historial;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Fallo la carga de datos: ${e.toString()}';
        });
      }
      debugPrint('Error al cargar historial: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- FUNCIÓN DE NAVEGACIÓN ACTIVA ---
  void _goToDetails(String id) async {
    // 🚨 NAVEGACIÓN A HISTORIAL_DETALLE.DART
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistorialDetalleScreen(reservaId: id),
      ),
    );

    // Opcional: Recargar si la vista de detalle retorna 'true'
    if (result == true) {
      _loadHistorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Historial', estiloLogin: false),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD60A)),
                  )
                : _errorMessage != null
                ? Center(
                    child: Text(
                      'Error de Conexión: $_errorMessage',
                      textAlign: TextAlign.center,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistorial,
                    child: _finishedReservations.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 3,
                              ),
                              _buildEmptyState(),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _finishedReservations.length,
                            itemBuilder: (context, index) {
                              final reserva = _finishedReservations[index];
                              return HistorialCard(
                                reserva: reserva,
                                onTap: () => _goToDetails(reserva.id),
                              );
                            },
                          ),
                  ),
          ),
          const CustomBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No hay viajes finalizados en tu historial.\n\nDesliza hacia abajo para actualizar.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

// =======================================================
// TARJETA DE HISTORIAL (Estilo de ReservaDetalleCard)
// =======================================================
class HistorialCard extends StatelessWidget {
  final ReservaHistorial reserva;
  final VoidCallback onTap;

  const HistorialCard({super.key, required this.reserva, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final int id = int.tryParse(reserva.id) ?? 0;

    if (id == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER AMARILLO: ID de Viaje
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD60A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'Viaje N° ${id.toString().padLeft(4, '0')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 2. CUERPO DE DETALLES
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Cliente:', reserva.cliente),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Fecha y Hora:',
                    '${reserva.fechaReserva} - ${reserva.horaRecogida}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Dirección de encuentro:',
                    reserva.direccionEncuentro,
                  ),
                  const SizedBox(height: 12),

                  // 🚨 Botón "Ver Detalles"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTap,
                      child: const Text(
                        'Ver Detalles >',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
