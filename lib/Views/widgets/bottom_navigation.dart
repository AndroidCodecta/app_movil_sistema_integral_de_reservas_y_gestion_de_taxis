import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        currentIndex: CustomBottomNavBar.getCurrentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/reservas');
              break;
            case 2:
              Navigator.pushNamed(context, '/chat_users');
              break;
            case 3:
              Navigator.pushNamed(context, '/solicitudes');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: CustomBottomNavBar.getCurrentIndex(context) == 0
                ? const Icon(Icons.home)
                : const Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomBottomNavBar.getCurrentIndex(context) == 1
                ? const Icon(Icons.notifications)
                : const Icon(Icons.notifications_none),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: CustomBottomNavBar.getCurrentIndex(context) == 2
                ? const Icon(Icons.chat)
                : const Icon(Icons.chat_outlined),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: CustomBottomNavBar.getCurrentIndex(context) == 3
                ? const Icon(Icons.person)
                : const Icon(Icons.person_outline),
            label: 'Solicitudes',
          ),
        ],
      ),
    );
  }

  static int getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/home':
        return 0;
      case '/reservas':
        return 1;
      case '/chat_users':
        return 2;
      case '/solicitudes':
        return 3;
      default:
        return 0;
    }
  }
}
