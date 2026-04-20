import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// Asegúrate de que estos imports existan en tu proyecto
import 'package:maiz_app/screens/disease_info_screen.dart';
import 'package:maiz_app/screens/user_parcels_screen.dart';
import 'package:maiz_app/screens/diagnosis_history_screen.dart';
import 'package:maiz_app/screens/login_screen.dart';

import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/session_service.dart';

class HomeAgricultor extends StatefulWidget {
  final String userName;
  final int userId;

  const HomeAgricultor({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<HomeAgricultor> createState() => _HomeAgricultorState();
}

class _HomeAgricultorState extends State<HomeAgricultor> {
  // --- PALETA DE COLORES ---
  static const Color primaryGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color bgColor = Color(0xFFF1F8E9);

  // Índices válidos: 0 (Parcelas), 1 (Historial), 2 (Perfil).
  int currentIndex = 0;

  File? profileImage;
  final ImagePicker _picker = ImagePicker();

  int totalDiagnosticos = 0;
  int totalParcelas = 0;

  // Variables locales para mostrar en pantalla
  late String displayUserName;
  late String displayUserEmail;

  @override
  void initState() {
    super.initState();
    displayUserName = SessionService.userName ?? widget.userName;
    displayUserEmail = SessionService.userEmail ?? "Sin correo registrado";

    _loadStats();
    _loadProfileImage();
  }

  // ================================
  // LÓGICA DE DATOS
  // ================================
  Future<void> _loadProfileImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/profile_${widget.userId}.jpg");
    if (await file.exists()) {
      setState(() => profileImage = file);
    }
  }

  Future<File> _saveProfileLocally(File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final saved = File("${dir.path}/profile_${widget.userId}.jpg");
    return await image.copy(saved.path);
  }

  Future<void> _pickProfileImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final saved = await _saveProfileLocally(File(picked.path));
    setState(() => profileImage = saved);
  }

  Future<void> _loadStats() async {
    final userId = widget.userId;
    final diagnos = await ApiService.fetchDiagnoses(userId: userId);
    final parcelas = await ApiService.fetchParcels(userId);

    if (mounted) {
      setState(() {
        totalDiagnosticos = diagnos?.length ?? 0;
        totalParcelas = parcelas?.length ?? 0;
      });
    }
  }

  // ================================
  // DIÁLOGO DE EDICIÓN
  // ================================
  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: displayUserName);
    final emailCtrl = TextEditingController(text: displayUserEmail);
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text("Editar Mis Datos",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.black),
                        decoration:
                            _inputDecoration("Nombre completo", Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "El nombre es obligatorio";
                          if (value.length > 50) return "Máximo 50 caracteres";
                          if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                              .hasMatch(value)) {
                            return "Solo se permiten letras y espacios";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black),
                        decoration:
                            _inputDecoration("Correo electrónico", Icons.email),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "El correo es obligatorio";
                          final parts = value.split('@');
                          if (parts.length != 2)
                            return "Formato de correo inválido";
                          final domain = parts[1].toLowerCase();
                          final allowedDomains = [
                            'gmail.com',
                            'hotmail.com',
                            'yahoo.com'
                          ];
                          bool isAllowed = allowedDomains.contains(domain) ||
                              domain.endsWith('.ec');
                          if (!isAllowed) return "Dominio no permitido";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: obscurePassword,
                        style: const TextStyle(color: Colors.black),
                        decoration:
                            _inputDecoration("Nueva contraseña", Icons.lock)
                                .copyWith(
                          hintText: "Opcional (min 6 caracteres)",
                          suffixIcon: IconButton(
                            icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey),
                            onPressed: () => setStateDialog(
                                () => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length < 6) return "Mínimo 6 caracteres";
                          }
                          return null;
                        },
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(color: primaryGreen),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isLoading)
                  TextButton(
                    child: const Text("Cancelar",
                        style: TextStyle(color: Colors.grey)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                if (!isLoading)
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                    child: const Text("Guardar",
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateDialog(() => isLoading = true);

                      final userIdToUpdate = widget.userId;
                      final res = await ApiService.updateUserProfile(
                        userId: userIdToUpdate,
                        nombre: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        clave: passCtrl.text.isEmpty ? null : passCtrl.text,
                      );
                      setStateDialog(() => isLoading = false);

                      if (res['success'] == true) {
                        final nuevoNombre = nameCtrl.text.trim();
                        final nuevoEmail = emailCtrl.text.trim();
                        SessionService.userName = nuevoNombre;
                        SessionService.userEmail = nuevoEmail;
                        setState(() {
                          displayUserName = nuevoNombre;
                          displayUserEmail = nuevoEmail;
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res['message']),
                            backgroundColor: Colors.green));
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res['message'] ?? "Error"),
                            backgroundColor: Colors.red));
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: primaryGreen),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2)),
    );
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro que deseas salir?"),
        actions: [
          TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Salir", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // ================================
  // PANTALLA DE PERFIL
  // ================================
  Widget _buildProfileScreen() {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          ClipPath(
            clipper: BackgroundWaveClipper(),
            child: Container(
              height: size.height * 0.35,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF81C784), darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
                bottom:
                    20), // Ajustado ya que el menú no flota sobre el contenido
            child: Column(
              children: [
                SizedBox(height: size.height * 0.08),
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImage != null
                                ? FileImage(profileImage!) as ImageProvider
                                : null,
                            child: profileImage == null
                                ? Text(
                                    displayUserName.isNotEmpty
                                        ? displayUserName[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                        fontSize: 50,
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen))
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              color: darkGreen, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(displayUserName,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(displayUserEmail,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white)),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                            color: darkGreen.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                            icon: Icons.qr_code_scanner,
                            value: "$totalDiagnosticos",
                            label: "Diagnósticos"),
                        VerticalDivider(
                            color: Colors.grey[200], thickness: 2, width: 40),
                        _buildStatItem(
                            icon: Icons.grass,
                            value: "$totalParcelas",
                            label: "Parcelas"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      _buildActionButton(
                          icon: Icons.edit,
                          text: "Editar Datos ",
                          color: Colors.blueAccent,
                          onTap: _showEditProfileDialog),
                      const SizedBox(height: 20),
                      _buildActionButton(
                          icon: Icons.logout,
                          text: "Cerrar Sesión",
                          color: Colors.redAccent,
                          onTap: _confirmarLogout,
                          isOutlined: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      {required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen, size: 30),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String text,
      required Color color,
      required VoidCallback onTap,
      bool isOutlined = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: isOutlined ? Border.all(color: color) : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 15),
            Text(text,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isOutlined ? color : Colors.black87)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: isOutlined ? color : Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  // ================================
  // BUILD PRINCIPAL - MENÚ PEGADO ABAJO
  // ================================
  @override
  Widget build(BuildContext context) {
    // Definimos las 3 pantallas actuales
    List<Widget> screens = [
      UserParcelsScreen(userId: widget.userId), // Index 0
      DiagnosisHistoryScreen(userId: widget.userId), // Index 1
      _buildProfileScreen(), // Index 2
      const DiseaseInfoScreen(), // Index 3
    ];

    // --- PROTECCIÓN CONTRA EL ERROR ---
    if (currentIndex >= screens.length) {
      currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: bgColor,
      // 1. Usamos AnimatedSwitcher directamente en el body (Sin Stack)
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: screens[currentIndex],
      ),

      // 2. Usamos bottomNavigationBar para que esté pegado y fijo
      bottomNavigationBar: Container(
        height: 70, // Altura del menú
        decoration: BoxDecoration(
          color: Colors.white,
          // Sombra solo en la parte superior para dar profundidad
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          // Evita que se tape con la barra de gestos en iPhone modernos
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAnimatedNavItem(0, Icons.agriculture_rounded, "Parcelas"),
              _buildAnimatedNavItem(1, Icons.history_rounded, "Historial"),
              _buildAnimatedNavItem(2, Icons.person_rounded, "Perfil"),
              _buildAnimatedNavItem(3, Icons.menu_book_rounded, "Guía"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(int index, IconData icon, String label) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      // Comportamiento de click transparente
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 20 : 10, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryGreen.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Importante para que no ocupe todo el espacio
          children: [
            Icon(icon,
                color: isSelected ? primaryGreen : Colors.grey, size: 28),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }
}

class BackgroundWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height - 30);
    path.quadraticBezierTo(
        size.width * 3 / 4, size.height - 60, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
