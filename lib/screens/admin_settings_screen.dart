import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  final ImagePicker _picker = ImagePicker();
  File? profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // ================================================================
  // CARGAR FOTO DEL ADMIN
  // ================================================================
  Future<void> _loadProfileImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/admin_profile.jpg");

    if (await file.exists()) {
      setState(() => profileImage = file);
    }
  }

  // ================================================================
  // GUARDAR FOTO
  // ================================================================
  Future<File> _saveLocally(File img) async {
    final dir = await getApplicationDocumentsDirectory();
    final saved = File("${dir.path}/admin_profile.jpg");
    return await img.copy(saved.path);
  }

  // ================================================================
  // ELEGIR NUEVA FOTO
  // ================================================================
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked == null) return;

    final saved = await _saveLocally(File(picked.path));

    setState(() => profileImage = saved);
  }

  // ================================================================
  // VER FOTO EN GRANDE
  // ================================================================
  void _viewImage() {
    if (profileImage == null) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.file(profileImage!),
        ),
      ),
    );
  }

  // ================================================================
  // UI SUPER PRO
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        toolbarHeight: 90,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Perfil del Administrador",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Gestión general del sistema",
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ============================================================
            // FOTO, NOMBRE, ROL
            // ============================================================
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: [

                    GestureDetector(
                      onTap: _pickImage,
                      onLongPress: _viewImage,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: CircleAvatar(
                          key: ValueKey(profileImage?.path ?? "default"),
                          radius: 60,
                          backgroundColor: primaryGreen.withOpacity(0.15),

                          backgroundImage: profileImage != null
                              ? FileImage(
                                  profileImage!,
                                  scale: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toDouble(),
                                )
                              : null,

                          child: profileImage == null
                              ? const Icon(Icons.person,
                                  size: 60, color: primaryGreen)
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      "Administrador General",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),

                    const Text(
                      "Control y supervisión del sistema",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    Chip(
                      label: const Text(
                        "ADMIN",
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: primaryGreen,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ============================================================
            // SECCIÓN DE INFORMACIÓN
            // ============================================================
            _infoSection(
              title: "Información del sistema",
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📌 Versión instalada: 1.0.0"),
                  SizedBox(height: 6),
                  Text("🛠 Última actualización: 2025"),
                  SizedBox(height: 6),
                  Text("📚 Módulos habilitados: Diagnósticos / Parcelas / Usuarios"),
                  SizedBox(height: 6),
                  Text("🔐 Permisos: Acceso total a la plataforma"),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ============================================================
            // OPCIONES ADMIN
            // ============================================================
            _infoSection(
              title: "Herramientas de administración",
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.people, color: primaryGreen),
                    title: Text("Gestión de usuarios"),
                    subtitle: Text("Crear, editar o eliminar cuentas"),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.analytics, color: primaryGreen),
                    title: Text("Estadísticas del sistema"),
                    subtitle: Text("Visualiza datos globales"),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.security, color: primaryGreen),
                    title: Text("Configuraciones avanzadas"),
                    subtitle: Text("Parámetros internos del sistema"),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ================================================================
  // CARD ESTILO MODERNO
  // ================================================================
  Widget _infoSection({required String title, required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
