import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../Utils/session_manager.dart';
import '../../Utils/reservas_service.dart';
import '../Reservas/reservas_detalle.dart';
import '../Reservas/reservas_page.dart';
import '../Historial/historial_page.dart'; // IMPORTACIÓN DEL HISTORIAL
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

class ReservaCard extends StatelessWidget {
  final ReservaDetalle reserva;
  final int? reservaId;
  final Map<String, dynamic>? vehiculoData;

  const ReservaCard({
    super.key,
    required this.reserva,
    this.reservaId,
    this.vehiculoData,
  });

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
            TextSpan(text: ' ${value.isEmpty ? 'No especificado' : value}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (reservaId == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text("Error: ID de reserva faltante para ${reserva.cliente}"),
      );
    }

    final placa = vehiculoData?['placa']?.toString() ?? 'N/A';
    final marca = vehiculoData?['marca']?.toString() ?? 'N/A';
    final modelo = vehiculoData?['año_modelo']?.toString() ?? 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReservaDetalleCompletoScreen(reservaId: reservaId!),
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
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                        fontSize: 14,
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
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          'Placa: $placa',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Marca: $marca',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Modelo: $modelo',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toca para ver más detalles',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blueGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Cliente:', reserva.cliente),
                        _buildInfoRow('Fecha:', reserva.fechaReserva),
                        _buildInfoRow('Hora:', reserva.horaRecogida),
                        _buildInfoRow('Encuentro:', reserva.direccionEncuentro),
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
}

class EstadoChoferButton extends StatefulWidget {
  const EstadoChoferButton({super.key});

  @override
  State<EstadoChoferButton> createState() => _EstadoChoferButtonState();
}

class _EstadoChoferButtonState extends State<EstadoChoferButton> {
  bool? activo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEstado();
  }

  Future<void> _fetchEstado() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final token = await SessionManager.getToken();
    final userId = await SessionManager.getUserId();

    if (token == null || userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No hay sesión iniciada")));
        setState(() => _isLoading = false);
      }
      return;
    }

    final url = Uri.parse(
      "http://servidorcorman.dyndns.org:7019/api/chofer/estado",
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"id_user": userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final estado = data["data"]?["estado"];
        if (mounted) setState(() => activo = estado == 1);
      } else if (response.statusCode == 404) {
        if (mounted) setState(() => activo = false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error ${response.statusCode}: no se pudo obtener estado",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleEstado() {
    if (activo != null) {
      setState(() {
        activo = !activo!;
      });
      print(
        'Simulando envío de estado a API: ${!activo! ? 'Activo' : 'Inactivo'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (activo == null) {
      return const Text("Estado no disponible. Intente de nuevo.");
    }

    return GestureDetector(
      onTap: _toggleEstado,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo == true
              ? const Color.fromARGB(255, 104, 230, 119)
              : Colors.redAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          activo == true ? 'Activo' : 'Inactivo',
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

// ======================================================================
// WIDGET MODIFICADO: StatusButtons con título e ícono de historial
// ======================================================================
class StatusButtons extends StatelessWidget {
  const StatusButtons({super.key});

  @override
  Widget build(BuildContext context) {
    Widget _buildSectionTitle(String title, {bool isTop = true}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 214, 10, 1),
          borderRadius: BorderRadius.only(
            topLeft: isTop ? const Radius.circular(12) : Radius.zero,
            topRight: isTop ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Widget para "Resumen de hoy" con ícono de historial
    Widget _buildResumenConHistorial() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          color: Color.fromRGBO(255, 214, 10, 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Espaciador para centrar el título
            const SizedBox(width: 40),

            // Título centrado
            const Expanded(
              child: Text(
                'Resumen de hoy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Ícono de historial a la derecha
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistorialPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSectionTitle('Estado'),
        const SizedBox(height: 8),
        const EstadoChoferButton(),
        const SizedBox(height: 8),
        _buildResumenConHistorial(), // Nuevo widget con historial
      ],
    );
  }
}

// ======================================================================
// PANTALLA PRINCIPAL
// ======================================================================
class HomeScreen extends StatefulWidget {
  final List reservas;

  const HomeScreen({super.key, required this.reservas});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _rawReservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFromApiAndPrefs();
  }

  Future<void> _loadDataFromApiAndPrefs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    List<dynamic> fetchedReservas = [];

    try {
      fetchedReservas = await SessionManager.fetchReservasFromApi();
    } catch (e) {
      print(
        'Fallo al obtener reservas de la API: $e. Intentando cargar desde cache.',
      );
      fetchedReservas = await SessionManager.getReservas();
      if (mounted && fetchedReservas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error de conexión. Mostrando datos antiguos (o ninguno).',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _rawReservas = fetchedReservas;
        _isLoading = false;
      });
    }
  }

  bool get _shouldShowNoReservasMessage {
    return _buildReservaCards().isEmpty;
  }

  List<Widget> _buildReservaCards() {
    final validReservas = _rawReservas.where((r) {
      return r != null &&
          r is Map &&
          r.isNotEmpty &&
          r['id'] != null &&
          r['cliente'] != null &&
          r['fecha_hora'] != null &&
          r['d_encuentro'] != null;
    }).toList();

    if (validReservas.isEmpty) {
      return [];
    }

    return validReservas
        .map((r) {
          final cliente = r["cliente"] ?? {};
          final vehiculo = r["vehiculo"] ?? {};

          final int? idReserva = r["id"] is int
              ? r["id"]
              : int.tryParse(r["id"]?.toString() ?? '');

          if (idReserva == null) {
            return Container();
          }

          final reserva = ReservaDetalle(
            cliente: "${cliente["nombres"] ?? ""} ${cliente["apellidos"] ?? ""}"
                .trim(),
            fechaReserva: (r["fecha_hora"] ?? "").toString().split(" ")[0],
            horaRecogida:
                (r["fecha_hora"] ?? "").toString().split(" ").length > 1
                ? r["fecha_hora"].split(" ")[1]
                : "",
            direccionEncuentro: r["d_encuentro"] ?? "",
          );

          return ReservaCard(
            key: ValueKey(idReserva),
            reserva: reserva,
            reservaId: idReserva,
            vehiculoData: vehiculo,
          );
        })
        .whereType<ReservaCard>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Inicio', estiloLogin: false),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDataFromApiAndPrefs,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const StatusButtons(),
                          const SizedBox(height: 16),
                          if (_shouldShowNoReservasMessage)
                            Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "No tienes reservas por el momento 🚗\nDesliza hacia abajo para buscar nuevas reservas.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._buildReservaCards(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}
