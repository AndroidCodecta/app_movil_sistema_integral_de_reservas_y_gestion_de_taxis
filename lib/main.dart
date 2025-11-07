import 'package:flutter/material.dart';
// Ocultamos ReservasScreen de inicio_page.dart para evitar el conflicto
import 'Views/Inicio/inicio_page.dart' hide ReservasScreen;
import 'Views/Reservas/reservas_page.dart';
import 'Views/Login/login_page.dart';
import 'Views/Chats/chat_user_list_page.dart';
import 'Views/Maps/maps_page.dart';
import 'Views/Solicitudes/solicitudes_page.dart';
import 'Views/Profile/profile_page.dart';
import 'Utils/session_manager.dart';

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
        '/home': (context) => FutureBuilder(
          future: Future.wait([
            SessionManager.getReservas(),
            SessionManager.getSolicitudes(),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Asegúrate de que los tipos sean correctos para evitar futuros errores
            final reservas = snapshot.data![0] as List<dynamic>;
            //final solicitudes = snapshot.data![1] as List<dynamic>;
            return HomeScreen(
              reservas: reservas,
              //solicitudes: solicitudes,
            );
          },
        ),
        // Aquí se usa la ReservasScreen de 'Views/Reservas/reservas_page.dart'
        '/reservas': (context) => const ReservasScreen(),
        '/chat_users': (context) => ChatUserListPage(),
        '/solicitudes': (context) => const SolicitudesPage(),
        '/profile': (context) => const ProfilePage(),
        '/maps': (context) => const MapsScreen(),
      },
    );
  }
}
