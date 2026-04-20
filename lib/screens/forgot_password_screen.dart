import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/screens/reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // ========================================================
  // HELPER PARA ALERTAS (INTACTO)
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
            onPressed: () {
              Navigator.pop(ctx); // Cierra diálogo
              if (!isError) {
                Navigator.pop(context); // Si es éxito, vuelve al Login
              }
            },
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

  // ========================================================
  // LÓGICA DE RECUPERACIÓN (INTACTA)
  // ========================================================
  Future<void> _sendRecoveryCode() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showFriendlyAlert(
        "Falta información",
        "Por favor, ingresa tu correo electrónico para continuar.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.sendPasswordRecovery(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      // ÉXITO
      _showFriendlyAlert(
        "¡Código Enviado! 🌽",
        response['message'] ?? 'Revisa tu bandeja de entrada.',
        isError: false,
      );
    } else {
      // ERROR
      _showFriendlyAlert(
        "Ocurrió un problema",
        response['message'] ?? 'No pudimos enviar el código.',
        isError: true,
      );
    }
  }

  // ========================================================
  // DISEÑO VISUAL (AJUSTADO: SCROLL GLOBAL)
  // ========================================================
  @override
  Widget build(BuildContext context) {
    // Paleta de colores
    final darkGreen = const Color(0xFF2E5E4E);
    final lightGreenBg = const Color(0xFFE8F5E9);

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. SCROLL PRINCIPAL (Envuelve todo)
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(), // Evita el rebote blanco arriba
        child: Stack(
          children: [
            // 2. IMAGEN DE FONDO (Ahora dentro del scroll)
            SizedBox(
              height: size.height * 0.50,
              width: double.infinity,
              child: Image.asset(
                'assets/imagen_login.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // 3. PANEL ONDULADO BLANCO
            // Usamos Container con margen top para superponerlo
            Container(
              margin: EdgeInsets.only(top: size.height * 0.35),
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  // Padding interno
                  padding: const EdgeInsets.fromLTRB(30, 50, 30, 20),
                  // Aseguramos altura mínima para cubrir pantalla en móviles grandes
                  constraints: BoxConstraints(minHeight: size.height * 0.65),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icono decorativo
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: lightGreenBg,
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.lock_reset, size: 50, color: darkGreen),
                      ),

                      const SizedBox(height: 20),

                      // Título
                      Text(
                        "Recuperar Cuenta",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),

                      const SizedBox(height: 30),

                      // INPUT EMAIL
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 8),
                          child: Text(
                            "Correo Electrónico",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "ejemplo@correo.com",
                          prefixIcon: Icon(Icons.email_outlined,
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

                      const SizedBox(height: 30),

                      // BOTÓN ENVIAR
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendRecoveryCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(color: darkGreen, width: 2),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "ENVIAR CÓDIGO",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(color: darkGreen, width: 2),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            "VOLVER A INICIAR SESIÓN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ResetPasswordScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(color: darkGreen, width: 2),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            "YA TENGO UN TOKEN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // 4. BOTÓN ATRÁS (Flotante dentro del Stack scrolleable)
            // Se moverá hacia arriba cuando hagas scroll
            Positioned(
              top: 40,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================
// CLASE ONDA (INTACTA)
// ========================================================
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
