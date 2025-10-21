import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../Utils/session_manager.dart';
// Asegúrate de que ReservaDetalle esté definido en este archivo o importado aquí
import '../Reservas/reservas_detalle.dart';
import '../Reservas/reservas_page.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';

// >>> AÑADIR IMPORTACIÓN DE HISTORIALPAGE AQUÍ <<<
// Nota: La ruta exacta puede variar según tu estructura de carpetas
import '../Historial/historial_page.dart';

class HomeScreen extends StatefulWidget {
  final List reservas;

  const HomeScreen({super.key, required this.reservas});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFromPrefs();
  }

  Future<void> _loadDataFromPrefs() async {
    final reservasData = await SessionManager.getReservas();
    print('Reservas cargadas: $reservasData'); // Depuración: revisa en la consola
    setState(() {
      reservas = reservasData ?? [];
      _isLoading = false;
    });
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
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const StatusButtons(),
                  const SizedBox(height: 16),
                  if (reservas.isEmpty ||
                      reservas.every(
                            (r) =>
                        r == null ||
                            r is! Map ||
                            r.isEmpty ||
                            r['cliente'] == null ||
                            r['fecha_hora'] == null ||
                            r['d_encuentro'] == null,
                      ))
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
                          "No tienes reservas por el momento 🚗",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    ...reservas
                        .where(
                          (r) =>
                      r != null &&
                          r is Map &&
                          r.isNotEmpty &&
                          r['cliente'] != null &&
                          r['fecha_hora'] != null &&
                          r['d_encuentro'] != null,
                    )
                        .map((r) {
                      final cliente = r["cliente"] ?? {};
                      final reserva = ReservaDetalle(
                        // FIX: Se añadió el campo 'id' que es requerido
                        id: r["id"]?.toString() ?? 'ID_NO_DISPONIBLE',
                        cliente:
                        "${cliente["nombres"] ?? ""} ${cliente["apellidos"] ?? ""}"
                            .trim(),
                        fechaReserva: (r["fecha_hora"] ?? "")
                            .toString()
                            .split(" ")[0],
                        horaRecogida:
                        (r["fecha_hora"] ?? "").toString().split(" ").length >
                            1
                            ? r["fecha_hora"].split(" ")[1]
                            : "",
                        direccionEncuentro: r["d_encuentro"] ?? "",
                      );
                      return ReservaCard(reserva: reserva);
                    }),
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

// -------------------------------------------------------------
// WIDGETS
// -------------------------------------------------------------

class StatusButtons extends StatelessWidget {
  const StatusButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Alinea el ButtonBar al centro si no ocupa todo el ancho
      children: [
        // >>> BUTTON BAR CON BOTÓN HISTORIAL <<<
        ButtonBarTheme(
          data: const ButtonBarThemeData(
            // Centra los botones dentro del ButtonBar
            alignment: MainAxisAlignment.center,
            // AÑADIDO: Relleno horizontal para que no se pegue a los lados
            //padding: EdgeInsets.symmetric(horizontal: 0),
          ),
          child: ButtonBar(
            children: [
              // Botón "Historial"
              ElevatedButton(
                // Acción al presionar el botón
                onPressed: () {
                  // Usamos Navigator.push para navegar a una nueva pantalla
                  Navigator.push(
                    context,
                    // MaterialPageRoute define la nueva ruta (pantalla)
                    MaterialPageRoute(
                      // builder construye la nueva pantalla, que es tu HistorialPage
                      builder: (context) => HistorialPage(), // Aquí usa la clase importada
                    ),
                  );
                },
                // Estilo del botón
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300], // Color de fondo
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Relleno para que sea más grande
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Bordes redondeados
                  ),
                  minimumSize: Size.zero, // Permite que el padding defina el tamaño
                ),
                // Contenido visible del botón: el texto "Historial"
                child: const Text(
                  'Historial',
                  style: TextStyle(color: Colors.black, fontSize: 14), // Color y tamaño del texto
                ),
              ),
            ],
          ),
        ),
        // >>> FIN BUTTON BAR <<<

        const SizedBox(height: 16), // Separación entre el botón de historial y el título de estado

        // TÍTULO "ESTADO"
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(255, 214, 10, 1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: const Text(
            'Estado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const EstadoChoferButton(),
        const SizedBox(height: 8),

        // TÍTULO "RESUMEN DE HOY"
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReservasScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(255, 214, 10, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Resumen de hoy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// El resto de las clases (EstadoChoferButton, ReservaCard) siguen igual...

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
    setState(() => _isLoading = true);

    final token = await SessionManager.getToken();
    final userId = await SessionManager.getUserId();

    if (token == null || userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No hay sesión iniciada")),
        );
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
        setState(() => activo = estado == 1);
      } else if (response.statusCode == 404) {
        setState(() => activo = false);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEstado() async {
    if (activo != null) {
      final nuevoEstado = !activo!;

      // Simulación de cambio de estado optimista
      setState(() {
        activo = nuevoEstado;
        _isLoading = true;
      });

      final token = await SessionManager.getToken();
      final userId = await SessionManager.getUserId();

      if (token == null || userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay sesión iniciada")),
          );
        }
        setState(() {
          activo = !nuevoEstado; // Revertir si falla
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
        "http://servidorcorman.dyndns.org:7019/api/chofer/cambio_estado", // Asumiendo endpoint para cambiar estado
      );

      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "id_user": userId,
            "estado": nuevoEstado ? 1 : 0,
          }),
        );

        if (response.statusCode == 200) {
          // El estado se actualizó correctamente en el servidor
          // Ya se actualizó localmente, solo quitamos la carga.
        } else {
          // Si el servidor no confirma, revertimos el estado
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Error al cambiar estado: ${response.statusCode}",
                ),
              ),
            );
          }
          setState(() {
            activo = !nuevoEstado;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error de conexión al cambiar estado: $e")),
          );
        }
        setState(() {
          activo = !nuevoEstado;
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && activo == null) {
      return const CircularProgressIndicator();
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

class ReservaCard extends StatelessWidget {
  final ReservaDetalle reserva;

  const ReservaCard({super.key, required this.reserva});

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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                  Column(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Placa: -',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            'Marca: -',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            'Modelo: -',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            'Toca para ver más detalles',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Cliente:', reserva.cliente),
                        _buildInfoRow(
                          'Fecha de reserva:',
                          reserva.fechaReserva,
                        ),
                        _buildInfoRow('Hora Recogida:', reserva.horaRecogida),
                        _buildInfoRow(
                          'Dirección de encuentro:',
                          reserva.direccionEncuentro,
                        ),
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
            TextSpan(text: ' $value'),
          ],
        ),
      ),
    );
  }
}