import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/db_service.dart';
import 'package:maiz_app/screens/disease_info_screen.dart';
import 'package:maiz_app/screens/home_agricultor.dart';

class DiagnosisScreen extends StatefulWidget {
  final String userName;
  final int userId;

  const DiagnosisScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  // --- PALETA DE COLORES ---
  static const Color primaryGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color bgColor = Color(0xFFF1F8E9);
  static const Color cardColor = Colors.white;

  File? _image;
  String? _diagnosis;
  String? _recommendation;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // ===========================================================
  // MENÚ PARA TOMAR / SUBIR UNA FOTO (Lógica Intacta)
  // ===========================================================
  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt_rounded, color: primaryGreen),
                  title: const Text("Tomar foto",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _tomarFoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: primaryGreen),
                  title: const Text("Seleccionar de la galería",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarDeGaleria();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _tomarFoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _procesarImagen(File(picked.path));
  }

  Future<void> _seleccionarDeGaleria() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _procesarImagen(File(picked.path));
  }

  // ===========================================================
  // PROCESAR IMAGEN (ONLINE / OFFLINE) - (Lógica Intacta)
  // ===========================================================
  Future<void> _procesarImagen(File file) async {
    setState(() {
      _image = file;
      _diagnosis = null;
      _recommendation = null;
      _isLoading = true;
    });

    Position position = await Geolocator.getCurrentPosition();
    final createdAt = DateTime.now().toIso8601String();
    final connected = await ApiService.checkBackendHealth();

    if (connected) {
      try {
        final result = await ApiService.uploadImage(file);

        if (result == null) throw Exception("Nulo");

        final diagnosis = result['disease']?.toString() ?? 'Desconocido';
        final recommendation = result['recommendation']?.toString() ?? '';
        final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;

        await DBService.saveDiagnosis(
          imagePath: file.path,
          userId: widget.userId,
          disease: diagnosis,
          recommendation: recommendation,
          confidence: confidence,
          isCornLeaf: true,
          latitude: position.latitude,
          longitude: position.longitude,
          createdAt: createdAt,
        );

        setState(() {
          _diagnosis = diagnosis;
          _recommendation = recommendation;
        });
      } catch (e) {
        await DBService.saveDiagnosis(
          imagePath: file.path,
          userId: widget.userId,
          disease: "Guardado localmente",
          recommendation: "",
          confidence: 0.0,
          isCornLeaf: true,
          latitude: position.latitude,
          longitude: position.longitude,
          createdAt: createdAt,
        );

        setState(() {
          _diagnosis = "Guardado localmente (sin conexión)";
          _recommendation = "";
        });
      }
    } else {
      await DBService.saveDiagnosis(
        imagePath: file.path,
        userId: widget.userId,
        disease: "Pendiente",
        recommendation: "Se analizará luego",
        confidence: 0.0,
        isCornLeaf: true,
        latitude: position.latitude,
        longitude: position.longitude,
        createdAt: createdAt,
      );

      setState(() {
        _diagnosis = "Guardado localmente (sin conexión)";
        _recommendation = "";
      });
    }

    setState(() => _isLoading = false);
  }

  void _goToHistorial() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeAgricultor(
          userName: widget.userName,
          userId: widget.userId,
        ),
      ),
    );
  }

  // ===========================================================
  // UI DECORADA Y ANIMADA
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. FONDO DECORATIVO (Wave Gradient)
          ClipPath(
            clipper: _HeaderWaveClipper(),
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

          // 2. CONTENIDO SCROLLABLE
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // --- HEADER ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Nuevo Diagnóstico",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Botón flotante pequeño para ir al historial
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.history_rounded,
                                color: Colors.white),
                            onPressed: _goToHistorial,
                            tooltip: "Ver Historial",
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Analiza la salud de tus cultivos",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- TARJETA DE ACCIÓN (SUBIR FOTO) ---
                    _buildUploadCard(),

                    const SizedBox(height: 20),

                    // --- RESULTADO ANIMADO ---
                    // AnimatedSwitcher hace una transición suave cuando cambia el contenido
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      child: _image == null
                          ? const SizedBox
                              .shrink() // Espacio vacío si no hay imagen
                          : _buildResultCard(), // Muestra la tarjeta si hay imagen
                    ),

                    const SizedBox(height: 80), // Espacio final
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SABER MÁS: enlaza diagnóstico con guía de enfermedades
  // ==========================================================
  DiseaseData? _matchDisease(String? name) {
    if (name == null) return null;
    final lower = name.toLowerCase();
    for (final d in kDiseases) {
      if (lower.contains(d.name.toLowerCase())) return d;
    }
    return null;
  }

  Widget _buildSaberMasButton() {
    final matched = _matchDisease(_diagnosis);
    if (matched == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: matched.primaryColor,
            side: BorderSide(color: matched.primaryColor, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          icon: Icon(matched.icon, size: 20),
          label: Text(
            'Saber más sobre ${matched.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DiseaseDetailScreen(disease: matched),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Botón grande para subir foto
  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _mostrarOpcionesImagen,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_a_photo_rounded,
                      size: 40, color: primaryGreen),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Escanear Planta",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Toca para abrir cámara o galería",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Tarjeta de Resultados (Diseño Médico/Técnico)
  Widget _buildResultCard() {
    // Usamos Key para que AnimatedSwitcher detecte cambios
    return Container(
      key: const ValueKey("ResultCard"),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // IMAGEN
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: SizedBox(
              height: 250,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_image!, fit: BoxFit.cover),
                  // Gradiente sutil sobre la imagen
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTENIDO DE TEXTO
          Padding(
            padding: const EdgeInsets.all(20),
            child: _isLoading
                ? Column(
                    children: [
                      const CircularProgressIndicator(color: primaryGreen),
                      const SizedBox(height: 15),
                      Text(
                        "Analizando imagen...",
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined,
                              color: primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "RESULTADO DEL ANÁLISIS",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Diagnóstico
                      Text(
                        _diagnosis ?? "Desconocido",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),

                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 15),

                      // Recomendación
                      if (_recommendation != null &&
                          _recommendation!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Recomendación:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.2)),
                          ),
                          child: Text(
                            _recommendation!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF455A64),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "No hay recomendaciones disponibles o el análisis se guardó localmente.",
                          style: TextStyle(color: Colors.grey),
                        )
                      ],
                      // Botón "Saber más" cuando se detecta una enfermedad conocida
                      _buildSaberMasButton(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// CLIPPER PARA EL FONDO (WAVE)
// ===========================================================
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
