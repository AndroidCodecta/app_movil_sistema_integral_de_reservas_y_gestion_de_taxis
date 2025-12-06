import 'package:flutter/material.dart';
import '../Maps/maps_page.dart';
import '../Inicio/inicio_page.dart';
import '../Reservas/reservas_page.dart';
import '../Solicitudes/solicitudes_page.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    // Index 0: Home
    const HomeScreen(reservas: [],),

    // Index 1: Reservas
    const ReservasScreen(),

    // Index ?: Chat (COMENTADO)
    // const Center(child: Text("Chat Screen")),

    const SolicitudesPage(),

    // Index 3: Mapa
    const MapsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
            // Aquí ya no usamos Navigator, solo cambiamos el índice
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

            // ITEM COMENTADO: CHAT
            // BottomNavigationBarItem(
            //   icon: _currentIndex == 2 // Cuidado con los índices si descomentas
            //       ? const Icon(Icons.chat)
            //       : const Icon(Icons.chat_outlined),
            //   label: 'Chat',
            // ),

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