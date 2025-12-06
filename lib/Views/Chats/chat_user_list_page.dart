import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/header.dart';
import 'chat_page.dart';

class ChatUserListPage extends StatelessWidget {
  final List<Map<String, String>> usuarios = [
    {'nombre': 'Juan Pérez', 'correo': 'juan@correo.com'},
    {'nombre': 'Ana Torres', 'correo': 'ana@correo.com'},
    {'nombre': 'Carlos Ruiz', 'correo': 'carlos@correo.com'},
    {'nombre': 'María López', 'correo': 'maria@correo.com'},
  ];

  ChatUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const LogoHeader(titulo: 'Usuarios', estiloLogin: false),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              itemCount: usuarios.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(usuario['nombre']![0])),
                  title: Text(usuario['nombre']!),
                  subtitle: Text(usuario['correo']!),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          nombre: usuario['nombre']!,
                          correo: usuario['correo']!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}