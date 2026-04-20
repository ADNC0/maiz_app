import 'package:flutter/material.dart';
import 'dart:ui';

// Importaciones de tus pantallas de Admin
import 'package:maiz_app/screens/user_management_screen.dart';
import 'package:maiz_app/screens/admin_stats_screen.dart';
// import 'package:maiz_app/screens/admin_parcels_screen.dart'; // Ya no se usa en el menú principal

// Importamos la pantalla de enfermedades para el botón
import 'package:maiz_app/screens/admin_diseases_screen.dart';
import 'package:maiz_app/screens/login_screen.dart';

// Importar servicios
import 'package:maiz_app/services/session_service.dart';
import 'package:maiz_app/services/api_service.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  // Paleta de colores
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentYellow = Color(0xFFFFD600);

  int _selectedIndex = 0;

  // Variables de estado
  int? adminId;
  String adminName = "";
  String adminEmail = "";

  // Controladores
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rolCargado = (SessionService.userRole ?? '').trim();
    print('DEBUG ROL: $rolCargado');
    final bool adminPermitido = rolCargado == 'Administrador' ||
        rolCargado.toLowerCase() == 'administrador';
    print('DEBUG ADMIN PERMITIDO: $adminPermitido');
    _loadSessionData();
  }

  void _loadSessionData() {
    setState(() {
      adminId = SessionService.userId;
      adminName = SessionService.userName ?? "Administrador";
      adminEmail = SessionService.userEmail ?? "admin@sistema.com";
    });
  }

  // ========================================================
  // ✏️ LÓGICA DE EDICIÓN
  // ========================================================
  void _showEditProfileDialog() {
    _nameController.text = adminName;
    _emailController.text = adminEmail;
    _passController.clear();

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
              title: const Text("Editar Perfil",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration("Nombre", Icons.person),
                        style: const TextStyle(color: Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Requerido";
                          if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')
                              .hasMatch(value)) {
                            return "Solo letras";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration("Correo", Icons.email),
                        style: const TextStyle(color: Colors.black),
                        validator: (val) => (val == null || !val.contains('@'))
                            ? "Correo inválido"
                            : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _passController,
                        obscureText: obscurePassword,
                        style: const TextStyle(color: Colors.black),
                        decoration:
                            _inputDecoration("Nueva Contraseña", Icons.lock)
                                .copyWith(
                          hintText: "Opcional",
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setStateDialog(
                                () => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          if (val != null && val.isNotEmpty && val.length < 6)
                            return "Mínimo 6 caracteres";
                          return null;
                        },
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(color: primaryGreen),
                        )
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isLoading)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancelar",
                        style: TextStyle(color: Colors.grey)),
                  ),
                if (!isLoading)
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateDialog(() => isLoading = true);

                      final res = await ApiService.updateUserProfile(
                        userId: adminId!,
                        nombre: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        clave: _passController.text.isEmpty
                            ? null
                            : _passController.text,
                      );

                      setStateDialog(() => isLoading = false);

                      if (res['success'] == true) {
                        final nuevoNombre = _nameController.text.trim();
                        final nuevoEmail = _emailController.text.trim();
                        SessionService.userName = nuevoNombre;
                        SessionService.userEmail = nuevoEmail;

                        setState(() {
                          adminName = nuevoNombre;
                          adminEmail = nuevoEmail;
                        });

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Actualizado correctamente"),
                              backgroundColor: Colors.green),
                        );
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(res['message'] ?? "Error"),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text("Guardar",
                        style: TextStyle(color: Colors.white)),
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
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: primaryGreen),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text("Cerrar sesión", style: TextStyle(color: Colors.black)),
        content: const Text("¿Deseas salir del sistema?",
            style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child:
                const Text("Sí, salir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // VISTA "PERFIL"
  // ========================================================
  Widget _buildAdminProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentYellow, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryGreen,
                    child: Text(
                      adminName.isNotEmpty ? adminName[0].toUpperCase() : "A",
                      style: const TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(adminName,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text(adminEmail, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Editar Datos",
                        style: TextStyle(color: Colors.white)),
                    onPressed: _showEditProfileDialog,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Información",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen)),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.verified_user, color: Colors.blue),
              title: const Text("Rol de Usuario",
                  style: TextStyle(color: Colors.black)),
              subtitle: const Text("Administrador General"),
              trailing: Chip(
                label: Text("ID: $adminId",
                    style: const TextStyle(color: Colors.black)),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double headerHeight = size.height * 0.20;

    // 🔽 CAMBIO: Lista reducida a solo 3 páginas (Usuarios, Gráficas, Perfil)
    final List<Widget> pages = [
      const UserManagementScreen(), // 1. Usuarios
      const AdminStatsScreen(), // 2. Gráficas
      _buildAdminProfileTab(), // 3. Perfil
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, ${adminName.split(' ')[0]}",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
            const Text(
              "Panel de Control",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          // 🔽 CAMBIO: Botón de Enfermedades (Agregado aquí porque se quitó la pantalla de parcelas)
          IconButton(
            icon: const Icon(Icons.coronavirus_outlined, color: Colors.white),
            tooltip: "Gestión de Enfermedades",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDiseasesScreen()),
              );
            },
          ),
          // Botón de Logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),

      body: Stack(
        children: [
          // 1. EL FONDO (ENCABEZADO VERDE)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight + 40,
            child: CustomPaint(
              painter: HeaderPainter(color: primaryGreen),
            ),
          ),

          // 2. EL CONTENIDO
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: headerHeight + 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: pages[_selectedIndex],
                ),
              ),
            ),
          ),
        ],
      ),

      // 🔽 CAMBIO: Menú inferior actualizado con 3 ítems
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          items: const [
            // 1. Usuarios
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Usuarios'),
            // 2. Gráficas (Antes Stats)
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Gráficas'),
            // 3. Perfil
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

// ===== PAINTER =====
class HeaderPainter extends CustomPainter {
  final Color color;

  const HeaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    final double h = size.height * 0.80;

    path.lineTo(0, h);

    path.cubicTo(size.width * 0.30, h + 20, size.width * 0.70, h - 30,
        size.width, h - 15);

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
