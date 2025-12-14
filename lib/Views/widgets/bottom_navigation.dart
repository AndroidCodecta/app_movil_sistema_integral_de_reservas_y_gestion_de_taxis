import 'package:flutter/material.dart';
import '../Maps/maps_page.dart';
import '../Inicio/inicio_page.dart';
import '../Reservas/reservas_page.dart';
import '../Solicitudes/solicitudes_page.dart';

class MainLayoutScreen extends StatefulWidget {
  // Permitir inicializar con un índice específico
  final int initialIndex;
  final bool? viajeIniciado;
  final int? reservaId;
  final DateTime? horaEsperadaRecogidaReal;
  final String? montoViaje;
  final String? tipoPago;

  const MainLayoutScreen({
    super.key,
    this.initialIndex = 0,
    this.viajeIniciado,
    this.reservaId,
    this.horaEsperadaRecogidaReal,
    this.montoViaje,
    this.tipoPago,
  });

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Inicializar con el índice recibido
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Crear lista de pantallas dinámicamente
    final List<Widget> _screens = [
      // Index 0: Home
      const HomeScreen(reservas: []),

      // Index 1: Reservas
      const ReservasScreen(),

      // Index 2: Solicitudes
      const SolicitudesPage(),

      // Index 3: Mapa - AHORA PUEDE RECIBIR PARÁMETROS
      MapsScreen(
        viajeIniciado: widget.viajeIniciado ?? false,
        reservaId: widget.reservaId,
        fechaHoraProgramadaStr: widget.horaEsperadaRecogidaReal?.toString(),
        montoViaje: widget.montoViaje,
        tipoPago: widget.tipoPago,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _currentIndex,
          onTap: (index) {
            // Solo cambiar de índice (mantiene el bottom nav visible)
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            // ITEM 0: HOME
            BottomNavigationBarItem(
              icon: _currentIndex == 0
                  ? const Icon(Icons.home)
                  : const Icon(Icons.home_outlined),
              label: 'Home',
            ),

            // ITEM 1: RESERVAS
            BottomNavigationBarItem(
              icon: _currentIndex == 1
                  ? const Icon(Icons.notifications)
                  : const Icon(Icons.notifications_none),
              label: 'Reservas',
            ),

            // ITEM 2: SOLICITUDES
            BottomNavigationBarItem(
              icon: _currentIndex == 2
                  ? const Icon(Icons.person)
                  : const Icon(Icons.person_outline),
              label: 'Solicitudes',
            ),

            // ITEM 3: MAPA
            BottomNavigationBarItem(
              icon: _currentIndex == 3
                  ? const Icon(Icons.map)
                  : const Icon(Icons.map_outlined),
              label: 'Mapa',
            ),
          ],
        ),
      ),
    );
  }
}