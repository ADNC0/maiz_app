import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Importaciones de tus pantallas y servicios
import 'package:maiz_app/screens/register_screen.dart';
import 'package:maiz_app/screens/home_admin.dart';
import 'package:maiz_app/screens/home_agricultor.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/db_service.dart';
import 'package:maiz_app/services/session_service.dart';
import 'package:maiz_app/screens/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores de texto
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Variables de estado
  bool _loading = false;
  bool _obscureText = true;

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse('${value ?? ''}');
  }

  // ========================================================
  // MÉTODOS DE AYUDA (Validaciones y Alertas)
  // ========================================================

  void _showFriendlyAlert(String title, String message,
      {bool isError = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : Colors.green[800],
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style: TextStyle(color: Colors.green[900], fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Entendido",
              style: TextStyle(
                  color: Colors.green[800], fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateEmail(String email) {
    // Regex para validar emails comunes y dominios de Ecuador
    final regex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com|yahoo\.com|.*\.ec)$');
    return regex.hasMatch(email);
  }

  // ========================================================
  //  LÓGICA DE LOGIN ESTRICTA Y SEGURA
  // ========================================================
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 1. Validaciones básicas de formulario
    if (email.isEmpty || password.isEmpty) {
      _showFriendlyAlert("¡Ups!", "Por favor completa todos los campos.",
          isError: true);
      return;
    }

    if (!_validateEmail(email)) {
      _showFriendlyAlert("Correo no válido",
          "Solo aceptamos correos de Gmail, Hotmail, Yahoo o dominios de Ecuador (.ec).",
          isError: true);
      return;
    }

    setState(() => _loading = true);

    final connectivity = await Connectivity().checkConnectivity();

    // Variables de control para el flujo
    bool loginExitoso = false;
    Map<String, dynamic>?
        userMap; // Aquí guardaremos los datos finales del usuario

    // ---------------------------------------------------------
    // 2. INTENTO ONLINE (Si hay internet)
    // ---------------------------------------------------------
    if (connectivity.any((result) => result != ConnectivityResult.none)) {
      try {
        // Llamamos al backend
        final response = await ApiService.login(email, password);

        if (response != null) {
          // El servidor respondió (ya sea éxito o error controlado)

          if (response['success'] == true) {
            // ✅ LOGIN CORRECTO (ONLINE)
            final String tokenFromResponse =
                (response['token'] ?? '').toString().trim();
            if (tokenFromResponse.isEmpty) {
              setState(() => _loading = false);
              _showFriendlyAlert(
                "Login inválido",
                "No se recibió token del servidor. No se puede iniciar sesión.",
                isError: true,
              );
              return;
            }

            final apiUser = response['user'];
            final resolvedId = _toInt(response['usuario_id'] ?? apiUser?['id']);
            final resolvedName =
                (response['usuario_nombre'] ?? apiUser?['name'] ?? '')
                    .toString()
                    .trim();
            final resolvedRole =
                (response['usuario_rol'] ?? apiUser?['role'] ?? 'Agricultor')
                    .toString()
                    .trim();
            final resolvedEmail =
                (response['usuario_email'] ?? apiUser?['email'] ?? email)
                    .toString()
                    .trim();
            final resolvedToken = tokenFromResponse;

            if (resolvedId == null || resolvedName.isEmpty) {
              throw Exception(
                  'Respuesta de login sin usuario_id/usuario_nombre');
            }

            // Guardamos/Actualizamos en SQLite, asegurando server_id
            await DBService.upsertUserByEmail(
              name: resolvedName,
              email: resolvedEmail,
              password: password,
              serverId: resolvedId,
              synced: 1,
            );

            // Preparamos los datos para la sesión
            userMap = {
              if (apiUser is Map<String, dynamic>) ...apiUser,
              'usuario_id': resolvedId,
              'usuario_nombre': resolvedName,
              'usuario_rol':
                  resolvedRole.isNotEmpty ? resolvedRole : 'Agricultor',
              'usuario_email': resolvedEmail,
              // Backward-compatible aliases used across the app
              'id': resolvedId,
              'name': resolvedName,
              'role': resolvedRole.isNotEmpty ? resolvedRole : 'Agricultor',
              'email': resolvedEmail,
            };

            if (resolvedToken != null && resolvedToken.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('usuario_token', resolvedToken);
            }

            loginExitoso = true;
          } else {
            // 🛑 ERROR LÓGICO (Contraseña mal o Cuenta Bloqueada)
            setState(() => _loading = false);

            String msg = (response['mensaje'] ??
                    response['error'] ??
                    "Error de autenticación")
                .toString();

            if (msg.toLowerCase().contains("desactivada")) {
              _showFriendlyAlert("Cuenta en Pausa 🌽", msg, isError: true);
            } else {
              _showFriendlyAlert("Datos Incorrectos",
                  "El correo o la contraseña no coinciden.",
                  isError: true);
            }
            return; // SALIMOS DE LA FUNCIÓN INMEDIATAMENTE
          }
        }
      } catch (e) {
        print("Error API: $e");
        // Continuamos al bloque offline...
      }
    }

    // ---------------------------------------------------------
    // 3. INTENTO OFFLINE (Solo si no hubo internet o falló conexión técnica)
    // ---------------------------------------------------------
    if (!loginExitoso) {
      // Buscamos en la base de datos local del teléfono
      final localUser = await DBService.loginOffline(email, password);

      if (localUser != null) {
        // ✅ LOGIN CORRECTO (OFFLINE)
        final serverId = localUser['server_id'] ?? localUser['id'];

        userMap = {
          'usuario_id': serverId,
          'usuario_nombre': localUser['name'],
          'usuario_rol': localUser['role'] ?? 'Agricultor',
          'usuario_email': localUser['email'],
          'id': serverId,
          'name': localUser['name'],
          'email': localUser['email'],
          // Recuperamos el rol. Si no existe en local, por seguridad es Agricultor
          'role': localUser['role'] ?? 'Agricultor',
        };
        loginExitoso = true;
      }
    }

    setState(() => _loading = false);

    // ---------------------------------------------------------
    // 4. REDIRECCIÓN FINAL - AQUÍ ESTÁ EL ARREGLO
    // ---------------------------------------------------------
    if (loginExitoso && userMap != null) {
      // A. Guardar sesión en memoria RAM (SessionService)
      // SOLO guardamos ID, Nombre y Correo (NO el rol)
      SessionService.setUser(
        id: _toInt(userMap!['usuario_id'] ?? userMap!['id']) ?? 0,
        name: (userMap!['usuario_nombre'] ?? userMap!['name'] ?? '').toString(),
        email: (userMap!['usuario_email'] ?? userMap!['email'] ?? email)
            .toString(),
        role: (userMap!['usuario_rol'] ?? userMap!['role'] ?? '').toString(),
      );
      await SessionService.persistCurrentSession();

      // B. Analizar el rol para redirigir
      // Usamos .toString().trim() para eliminar espacios invisibles que rompen la lógica
      final String userRole =
          (userMap!['usuario_rol'] ?? userMap!['role']).toString().trim();
      final String normalizedRole = userRole.toLowerCase();

      print(
          "DEBUG - ROL DETECTADO: '$userRole'"); // Mira esto en la consola si falla

      if (mounted) {
        if (userRole == 'Administrador' || normalizedRole == 'administrador') {
          print('Navegando a Home de Admin');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdmin()),
          );
        } else if (normalizedRole == 'agricultor') {
          print('Navegando a Home de Agricultor');
          await SessionService.persistIfAgricultor();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeAgricultor(
                userName:
                    (userMap!['usuario_nombre'] ?? userMap!['name']).toString(),
                userId: _toInt(userMap!['usuario_id'] ?? userMap!['id']) ?? 0,
              ),
            ),
          );
        } else {
          print("Rol no reconocido: $userRole");
          await SessionService.clear();
          _showFriendlyAlert(
            'Rol no reconocido',
            'No se pudo determinar el módulo para este usuario. Vuelve a iniciar sesión.',
            isError: true,
          );
        }
      }
    } else {
      _showFriendlyAlert("No pudimos ingresar",
          "Verifica tu conexión a internet o tus credenciales guardadas.",
          isError: true);
    }
  }

  // ========================================================
  // DISEÑO VISUAL
  // ========================================================
  @override
  Widget build(BuildContext context) {
    final darkGreen = const Color(0xFF2E5E4E);
    final lightGreenBg = const Color(0xFFE8F5E9);
    final leafGreen = const Color(0xFF4CAF50);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Stack(
          children: [
            // 1. IMAGEN DE FONDO
            SizedBox(
              height: size.height * 0.50,
              width: double.infinity,
              child: Image.asset(
                'assets/imagen_login.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // 2. PANEL ONDULADO BLANCO
            Container(
              margin: EdgeInsets.only(top: size.height * 0.35),
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(30, 50, 30, 20),
                  constraints: BoxConstraints(minHeight: size.height * 0.65),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TÍTULO
                      Center(
                        child: Text(
                          "Bienvenido de Nuevo",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Inicia sesión en tu cuenta",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // INPUT EMAIL
                      _buildLabel("Correo Electrónico"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "ejemplo@gmail.com",
                          prefixIcon: Icon(Icons.person_outline,
                              color: Colors.grey[600]),
                          filled: true,
                          fillColor: lightGreenBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // INPUT PASSWORD
                      _buildLabel("Contraseña"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: "********",
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.grey[600]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: lightGreenBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),

                      // OLVIDÉ CONTRASEÑA
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // BOTÓN LOGIN
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "INGRESAR",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // REGISTRO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("¿No tienes cuenta? ",
                              style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Regístrate",
                              style: TextStyle(
                                color: leafGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, 40);

    var firstControlPoint = Offset(size.width / 4, 0);
    var firstEndPoint = Offset(size.width / 2, 0);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, 0);
    var secondEndPoint = Offset(size.width, 40);

    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
