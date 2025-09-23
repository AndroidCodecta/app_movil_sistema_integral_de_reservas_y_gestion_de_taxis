import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  final String? titulo;
  final String? nombreChat;
  final bool estiloLogin;
  const LogoHeader({
    super.key,
    this.titulo,
    this.nombreChat,
    this.estiloLogin = false,
  });

  @override
  Widget build(BuildContext context) {
    if (estiloLogin) {
      return Container(
        width: double.infinity,
        height: 180,
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LOGO',
              style: TextStyle(
                color: Color.fromRGBO(255, 214, 10, 1),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Mi app Chofer',
              style: TextStyle(
                color: Color.fromRGBO(255, 214, 10, 1),
                fontSize: 32,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!estiloLogin)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed('/profile');
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1C1C1C)),
                    ),
                  ),
                const Spacer(),
                const Text(
                  'LOGO',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 214, 10, 1),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                nombreChat ?? (titulo ?? ''),
                style: const TextStyle(
                  color: Color.fromRGBO(255, 214, 10, 1),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
