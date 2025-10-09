import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../../Utils/session_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? choferData;
  List<Map<String, dynamic>> reservas = [];
  bool _isLoading = true;
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = await SessionManager.getUser();
    final reservasData = await SessionManager.getReservas();
    setState(() {
      userData = user;
      choferData = user?['chofer'];
      reservas = reservasData;
      _isLoading = false;
    });
  }

  String _getNombreCompleto() {
    if (choferData == null) return 'Cargando...';
    final nombres = choferData!['nombres'] ?? '';
    final apellidoPaterno = choferData!['apellido_paterno'] ?? '';
    final apellidoMaterno = choferData!['apellido_materno'] ?? '';
    return '$nombres $apellidoPaterno $apellidoMaterno'.trim();
  }

  String _getEstado() {
    if (choferData == null) return 'Inactivo';
    final estadoActivo = choferData!['estado_activo'] ?? 0;
    return estadoActivo == 1 ? 'Activo' : 'Inactivo';
  }

  int _contarAutosDesignados() {
    if (reservas.isEmpty) return 0;
    final vehiculosUnicos = <int>{};
    for (var reserva in reservas) {
      if (reserva['vehiculo_id'] != null) {
        vehiculosUnicos.add(reserva['vehiculo_id'] as int);
      }
    }
    return vehiculosUnicos.length;
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const LogoHeader(titulo: 'Perfil', estiloLogin: false),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2 * 255),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 214, 10, 1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              choferData != null && choferData!['nombres'] != null
                                  ? choferData!['nombres'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getNombreCompleto(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              label: 'Estado: ',
                              value: _getEstado(),
                            ),
                            const SizedBox(height: 4),
                            _InfoRow(
                              label: 'Autos designados hoy: ',
                              value: _contarAutosDesignados().toString(),
                            ),
                            const SizedBox(height: 4),
                            _InfoRow(
                              label: 'Número de reservas hoy: ',
                              value: reservas.length.toString(),
                            ),
                            const SizedBox(height: 4),
                            _InfoRow(
                              label: 'DNI: ',
                              value: choferData?['dni'] ?? 'N/A',
                            ),
                            const SizedBox(height: 4),
                            _InfoRow(
                              label: 'Celular: ',
                              value: choferData?['celular'] ?? 'N/A',
                            ),
                            const SizedBox(height: 4),
                            _InfoRow(
                              label: 'Correo: ',
                              value: choferData?['correo'] ?? userData?['email'] ?? 'N/A',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AnimatedScale(
                          scale: _buttonScale,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeInOut,
                          child: SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTapDown: (_) {
                                setState(() => _buttonScale = 0.95);
                              },
                              onTapUp: (_) {
                                setState(() => _buttonScale = 1.0);
                                _cerrarSesion();
                              },
                              onTapCancel: () {
                                setState(() => _buttonScale = 1.0);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Cerrar sesión',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, color: Colors.black),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
