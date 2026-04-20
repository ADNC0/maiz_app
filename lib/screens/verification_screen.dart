import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maiz_app/screens/home_admin.dart';
import 'package:maiz_app/screens/home_agricultor.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/session_service.dart';

class VerificationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const VerificationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse('${value ?? ''}');
  }

  void _showMessage(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateAccount() async {
    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage('Codigo invalido', 'Ingresa un codigo de 6 digitos.',
          isError: true);
      return;
    }

    setState(() => _loading = true);

    final response = await ApiService.registerWithOtp(
      name: widget.name,
      email: widget.email,
      password: widget.password,
      code: code,
    );

    if (!mounted) return;

    if (response == null) {
      setState(() => _loading = false);
      _showMessage('Error', 'No se pudo confirmar tu cuenta.', isError: true);
      return;
    }

    final bool ok = response['success'] == true;
    if (!ok) {
      setState(() => _loading = false);
      _showMessage(
        'Confirmacion fallida',
        'Código incorrecto',
        isError: true,
      );
      return;
    }

    final token = (response['token'] ??
            response['jwt'] ??
            response['access_token'] ??
            response['accessToken'])
        ?.toString();

    if (token == null || token.isEmpty) {
      setState(() => _loading = false);
      _showMessage('Error', 'Verificacion exitosa pero sin token.',
          isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario_token', token);
    await ApiService.setToken(token);

    final user = response['user'];
    final int userId = _toInt(response['usuario_id'] ?? user?['id']) ?? 0;
    final String role =
        (response['usuario_rol'] ?? user?['role'] ?? 'Agricultor').toString();
    final String name =
        (response['usuario_nombre'] ?? user?['name'] ?? 'Usuario').toString();
    final String email =
        (response['usuario_email'] ?? user?['email'] ?? widget.email)
            .toString();

    SessionService.setUser(id: userId, name: name, email: email, role: role);
    await SessionService.persistCurrentSession();

    setState(() => _loading = false);

    if (role.toLowerCase() == 'administrador') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeAdmin()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeAgricultor(userName: name, userId: userId),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar Cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Te enviamos un codigo a ${widget.email}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Codigo de 6 digitos',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _activateAccount,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
