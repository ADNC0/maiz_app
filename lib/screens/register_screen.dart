import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:maiz_app/screens/login_screen.dart';
import 'package:maiz_app/screens/verification_screen.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/db_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _loading = false;
  bool _obscureText = true;
  bool _acceptedPrivacy = false;
  // 0: Débil · 1: Normal · 2: Fuerte
  int _passwordStrength = 0;

  static final Uri _privacyPolicyUri = Uri.parse(
    'https://www.freeprivacypolicy.com/live/b70f83c0-94f0-425a-8334-ca17ff3b1674',
  );

  @override
  void initState() {
    super.initState();
    passwordController.addListener(() {
      _checkPasswordStrength(passwordController.text);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ========================================================
  // HELPER PARA ALERTAS AMIGABLES
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

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      _privacyPolicyUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showFriendlyAlert(
        'No se pudo abrir el enlace',
        'Intenta de nuevo en unos segundos.',
        isError: true,
      );
    }
  }

  // ========================================================
  // LÓGICA DE REGISTRO
  // ========================================================
  Future<void> _register() async {
    if (!_acceptedPrivacy) {
      _showFriendlyAlert(
        'Falta confirmación',
        'Debes aceptar la política de privacidad para crear tu cuenta.',
        isError: true,
      );
      return;
    }

    // 1. Esto activa las validaciones visuales (Rojo y mensajes)
    if (!_formKey.currentState!.validate()) {
      // Si algo está mal, detenemos aquí. Los campos ya se pusieron rojos.
      return;
    }

    setState(() => _loading = true);

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final connectivity = await Connectivity().checkConnectivity();
    bool success = false;

    if (connectivity != ConnectivityResult.none) {
      // antes de crear la cuenta, probamos si el correo ya existe
      final taken = await ApiService.isEmailTaken(email);
      if (taken) {
        setState(() => _loading = false);
        _showFriendlyAlert(
            "Correo no disponible", "Ya existe una cuenta con ese correo.",
            isError: true);
        return;
      }
      // Aquí el FRONT consume el servicio de backend:
      // POST /api/auth/request-otp con nombre, correo y clave.
      final response = await ApiService.requestOtp(name, email, password);
      // Solo si el backend responde success=true se permite pasar
      // a la pantalla de verificación.
      if (response != null && response['success'] == true) {
        if (mounted) {
          setState(() => _loading = false);
          // Se navega a verificación enviando los datos ya escritos,
          // para no pedirlos de nuevo al usuario.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationScreen(
                email: email,
                name: name,
                password: password,
              ),
            ),
          );
        }
        return;
      }

      setState(() => _loading = false);

      final backendMessage =
          (response?['message'] ?? response?['mensaje'] ?? '').toString();
      final backendCode =
          (response?['code'] ?? response?['error'] ?? '').toString();
      final statusCode = response?['statusCode'];

      if (statusCode == 403) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("⚠️ Error de Seguridad"),
            content: const Text(
                "No tienes autorización para crear cuentas administrativas"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Entendido"),
              )
            ],
          ),
        );
        return;
      }

      // Si backend marca CORREO_INVALIDO (o success=false), se bloquea
      // navegación y se muestra alerta para corregir el correo.
      final isInvalidEmail = backendMessage == 'CORREO_INVALIDO' ||
          backendCode == 'CORREO_INVALIDO' ||
          response?['success'] == false;

      if (isInvalidEmail) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("⚠️ Correo no válido"),
            content: const Text(
                "El correo ingresado no existe o no puede recibir mensajes. Por favor, usa una cuenta real de Gmail o Hotmail."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Entendido"),
              )
            ],
          ),
        );
      } else {
        _showFriendlyAlert(
          'No se pudo enviar el código',
          'Intenta de nuevo en unos segundos.',
          isError: true,
        );
      }
      return;
    }

    if (!success) {
      // Intento offline si falla la red
      await DBService.saveUser(name, email, password, synced: 0);
      success = true;
    }

    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green[800]),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  "¡Bienvenido! 🌽",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          content: const Text(
              "Registro local guardado sin internet. Cuando tengas conexión, vuelve a intentar para solicitar el código."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Text("Iniciar Sesión",
                  style: TextStyle(color: Colors.green[800])),
            ),
          ],
        ),
      );
    } else {
      _showFriendlyAlert(
          "Error", "No se pudo crear la cuenta. Inténtalo de nuevo.",
          isError: true);
    }
  }

  // ========================================================
  // FORTALEZA DE CONTRASEÑA
  // ========================================================
  void _checkPasswordStrength(String value) {
    final hasMin8 = value.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[^A-Za-z0-9\s]').hasMatch(value);
    final score =
        [hasMin8, hasUpper, hasNumber, hasSpecial].where((c) => c).length;
    setState(() {
      if (score <= 2) {
        _passwordStrength = 0; // Débil
      } else if (score == 3) {
        _passwordStrength = 1; // Normal
      } else {
        _passwordStrength = 2; // Fuerte
      }
    });
  }

  Widget _buildPasswordStrengthBar() {
    if (passwordController.text.isEmpty) return const SizedBox.shrink();
    const labels = ['Débil', 'Normal', 'Fuerte'];
    final colors = [
      Colors.redAccent,
      Colors.amber,
      const Color(0xFF4CAF50),
    ];
    const progressValues = [0.33, 0.67, 1.0];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValues[_passwordStrength],
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(colors[_passwordStrength]),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _passwordStrength == 2
                    ? Icons.check_circle
                    : Icons.info_outline,
                size: 14,
                color: colors[_passwordStrength],
              ),
              const SizedBox(width: 4),
              Text(
                'Contraseña ${labels[_passwordStrength]}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors[_passwordStrength],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

    // ESTILO COMÚN PARA INPUTS (Bordes redondeados)
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    );

    // ESTILO PARA ERRORES (Borde rojo redondeado)
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. SCROLL PRINCIPAL (Todo sube junto)
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Stack(
          children: [
            // 2. IMAGEN DE FONDO
            SizedBox(
              height: size.height * 0.45,
              width: double.infinity,
              child: Image.asset(
                'assets/imagen_login.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // 3. FORMULARIO SUPERPUESTO
            Container(
              margin: EdgeInsets.only(top: size.height * 0.35),
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(30, 50, 30, 20),
                  constraints: BoxConstraints(minHeight: size.height * 0.65),

                  // ENVOLVEMOS EN FORM PARA VALIDACIÓN
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Crear Cuenta",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            "Únete a nuestra comunidad agrícola",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // === CAMPO NOMBRE ===
                        _buildLabel("Nombre Completo"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          maxLength: 50, // Bloquea al llegar a 50
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Por favor, dinos tu nombre.';
                            if (value.length < 3)
                              return 'El nombre es muy corto.';
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                          decoration: InputDecoration(
                            hintText: "Juan Pérez",
                            prefixIcon: Icon(Icons.person_outline,
                                color: Colors.grey[600]),
                            filled: true,
                            fillColor: lightGreenBg,
                            counterText: "", // Oculta el contador "0/50"
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder,
                            errorBorder: errorBorder, // Borde Rojo
                            focusedErrorBorder: errorBorder,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // === CAMPO CORREO ===
                        _buildLabel("Correo Electrónico"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          maxLength: 50, // Bloquea al llegar a 50
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'El correo es obligatorio.';
                            final regex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!regex.hasMatch(value))
                              return 'El formato no parece correcto.';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "ejemplo@correo.com",
                            prefixIcon: Icon(Icons.email_outlined,
                                color: Colors.grey[600]),
                            filled: true,
                            fillColor: lightGreenBg,
                            counterText: "",
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder,
                            errorBorder: errorBorder,
                            focusedErrorBorder: errorBorder,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // === CAMPO CONTRASEÑA ===
                        _buildLabel("Contraseña"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          maxLength: 20, // Bloquea al llegar a 20
                          obscureText: _obscureText,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Crea una contraseña segura.';
                            if (_passwordStrength == 0)
                              return 'La contraseña es muy débil. Mejórala.';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "********",
                            prefixIcon: Icon(Icons.lock_outline,
                                color: Colors.grey[600]),
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
                            counterText: "",
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder,
                            errorBorder: errorBorder,
                            focusedErrorBorder: errorBorder,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),

                        // BARRA DE FORTALEZA DE CONTRASEÑA
                        _buildPasswordStrengthBar(),

                        const SizedBox(height: 12),

                        // ACEPTACIÓN DE POLÍTICAS
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: lightGreenBg.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.translate(
                                offset: const Offset(-6, -6),
                                child: Checkbox(
                                  value: _acceptedPrivacy,
                                  activeColor: darkGreen,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptedPrivacy = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    children: [
                                      const Text(
                                        'Acepto el tratamiento de mis datos y la ',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13),
                                      ),
                                      GestureDetector(
                                        onTap: _openPrivacyPolicy,
                                        child: Text(
                                          'Política de Privacidad',
                                          style: TextStyle(
                                            color: leafGreen,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        '.',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // BOTÓN REGISTRAR
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            // Este botón dispara _register().
                            // Si hay loading o validaciones incompletas,
                            // queda deshabilitado (onPressed = null).
                            onPressed: _loading ||
                                    !_acceptedPrivacy ||
                                    (_passwordStrength == 0 &&
                                        passwordController.text.isNotEmpty)
                                ? null
                                // Punto exacto donde inicia el consumo del
                                // servicio (requestOtp) dentro de _register().
                                : _register,
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
                                    "REGISTRARSE",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("¿Ya tienes cuenta? ",
                                style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                );
                              },
                              child: Text(
                                "Inicia Sesión",
                                style: TextStyle(
                                  color: leafGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Espacio extra al final
                        const SizedBox(height: 40),
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
