import 'package:flutter/material.dart';
import '../Maps/maps_page.dart';
import '../Inicio/inicio_page.dart';
import '../Reservas/reservas_page.dart';
import '../Solicitudes/solicitudes_page.dart';

class MainLayoutScreen extends StatefulWidget {
  final int initialIndex;
  final bool? viajeIniciado;
  final int? reservaId;
  final String? montoViaje;
  final String? tipoPago;
  final String? direccionOrigen;
  final String? direccionDestino;
  final String? fechaHoraProgramadaStr;

  const MainLayoutScreen({
    super.key,
    this.initialIndex = 0,
    this.viajeIniciado,
    this.reservaId,
    this.montoViaje,
    this.tipoPago,
    this.direccionOrigen,
    this.direccionDestino,
    this.fechaHoraProgramadaStr,
  });

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const HomeScreen(reservas: []),
      const ReservasScreen(),
      const SolicitudesPage(),
      MapsScreen(
        viajeIniciado: widget.viajeIniciado ?? false,
        reservaId: widget.reservaId,
        montoViaje: widget.montoViaje,
        tipoPago: widget.tipoPago,
        direccionOrigen: widget.direccionOrigen,
        direccionDestino: widget.direccionDestino,
        fechaHoraProgramadaStr: widget.fechaHoraProgramadaStr,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
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
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: _currentIndex == 0
                  ? const Icon(Icons.home)
                  : const Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _currentIndex == 1
                  ? const Icon(Icons.notifications)
                  : const Icon(Icons.notifications_none),
              label: 'Reservas',
            ),
            BottomNavigationBarItem(
              icon: _currentIndex == 2
                  ? const Icon(Icons.person)
                  : const Icon(Icons.person_outline),
              label: 'Solicitudes',
            ),
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
