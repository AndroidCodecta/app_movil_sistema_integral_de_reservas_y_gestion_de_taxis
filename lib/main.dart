import 'package:flutter/material.dart';
import 'Views/Inicio/inicio_page.dart';
import 'Views/Reservas/reservas_page.dart';
import 'Views/Login/login_page.dart';
import 'Views/Chats/chat_user_list_page.dart';
import 'Views/Solicitudes/solicitudes_page.dart';
import 'Views/Profile/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/reservas': (context) => const ReservasScreen(),
        '/chat_users': (context) => ChatUserListPage(),
        '/solicitudes': (context) => const SolicitudesPage(),
        '/profile': (context) => const ProfilePage(
          // nombre: 'Jorge Alberto González Heredia',
          // correo: 'demo@correo.com',
        ),
      },
    );
  }
}
