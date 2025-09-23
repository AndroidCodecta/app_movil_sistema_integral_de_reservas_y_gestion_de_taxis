import 'package:flutter/material.dart';
import '../widgets/header.dart';

class ChatPage extends StatefulWidget {
  final String nombre;
  final String correo;

  const ChatPage({super.key, required this.nombre, required this.correo});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, String>> mensajes = [
    {
      'remitente': 'yo',
      'texto':
          '¡Hola ${DateTime.now().hour < 12 ? 'buenos días' : 'buenas tardes'}!',
    },
    {'remitente': 'otro', 'texto': '¡Hola! ¿En qué puedo ayudarte?'},
  ];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviarMensaje() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      mensajes.add({'remitente': 'yo', 'texto': _controller.text.trim()});
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          LogoHeader(
            titulo: 'Chat',
            nombreChat: widget.nombre,
            estiloLogin: false,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = mensajes[index];
                final esMio = mensaje['remitente'] == 'yo';
                return Align(
                  alignment: esMio
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: esMio ? Colors.amber[200] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(mensaje['texto']!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.grey),
                  onPressed: _enviarMensaje,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
