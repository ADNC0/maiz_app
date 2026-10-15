import 'dart:io'; // Necesario para cargar la imagen local si falla la red
import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/db_service.dart';
import 'package:maiz_app/screens/diagnosis_detail_screen.dart';

class DiagnosisHistoryScreen extends StatefulWidget {
  final int userId;

  const DiagnosisHistoryScreen({super.key, required this.userId});

  @override
  State<DiagnosisHistoryScreen> createState() => _DiagnosisHistoryScreenState();
}

class _DiagnosisHistoryScreenState extends State<DiagnosisHistoryScreen> {
  // --- PALETA DE COLORES (Consistente con Home) ---
  static const Color primaryGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color bgColor = Color(0xFFF1F8E9);
  static const Color cardColor = Colors.white;

  bool loading = true;
  List<Map<String, dynamic>> diagnoses = [];

  String _diagKey(Map<String, dynamic> item) {
    final serverImagePath =
        (item['server_image_path'] ?? item['serverImagePath'] ?? '')
            .toString()
            .trim();
    if (serverImagePath.isNotEmpty) {
      return 'srvimg_${_normalizePath(serverImagePath)}';
    }

    final id = item['id']?.toString();
    if (id != null && id.isNotEmpty) return 'id_$id';

    final serverId = item['server_id']?.toString();
    if (serverId != null && serverId.isNotEmpty) return 'server_$serverId';

    final imagePath = (item['image_path'] ?? '').toString();
    final createdAt = (item['created_at'] ?? '').toString();
    return 'path_${_normalizePath(imagePath)}_$createdAt';
  }

  String _normalizePath(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '';
    final parts = clean.split(RegExp(r'[\\/]'));
    return parts.isNotEmpty ? parts.last : clean;
  }

  String _normalizeText(String value) {
    var text = value.trim().toLowerCase();
    const withDia = 'áéíóúüñ';
    const withoutDia = 'aeiouun';
    for (var i = 0; i < withDia.length; i++) {
      text = text.replaceAll(withDia[i], withoutDia[i]);
    }
    return text;
  }

  String _prettyDiseaseLabel(dynamic rawValue) {
    final raw = (rawValue ?? '').toString().trim();
    if (raw.isEmpty) return 'Desconocido';

    final normalized = _normalizeText(raw.replaceAll('_', ' '));
    if (normalized.contains('no es plaga') || normalized.contains('no plaga')) {
      return 'No es plaga';
    }
    if (normalized.contains('gusano ejercito')) return 'Gusano ejercito';
    if (normalized.contains('gusano cortador')) return 'Gusano cortador';
    if (normalized.contains('pulgones') || normalized.contains('pulgon')) {
      return 'Pulgones';
    }
    if (normalized.contains('pulgilla') || normalized.contains('chicharrita')) {
      return 'Pulgilla';
    }

    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  String _extractDiagnosisName(Map<String, dynamic> item) {
    final value = (item['disease'] ??
            item['label'] ??
            item['disease_name'] ??
            item['prediction'] ??
            item['class'] ??
            item['result'] ??
            '')
        .toString()
        .trim();
    return value;
  }

  String _fallbackRecommendation(String diseaseName) {
    final normalized = _normalizeText(diseaseName.replaceAll('_', ' '));

    if (normalized.contains('no es plaga') || normalized.contains('no plaga')) {
      return 'No se detecta plaga en la imagen. No apliques insecticida; revisa la planta y toma otra foto enfocada para confirmar.';
    }
    if (normalized.contains('pulgones') || normalized.contains('pulgon')) {
      return 'Monitorea el enves de la hoja y aplica control suave (jabon potasico o neem) solo si aumenta la presencia de pulgones.';
    }
    if (normalized.contains('gusano cortador')) {
      return 'Revisa base del tallo al atardecer y retira larvas visibles. Si el dano avanza, aplica control dirigido en la base.';
    }
    if (normalized.contains('gusano ejercito')) {
      return 'Inspecciona bordes del cultivo y controla focos tempranos. Si hay alta infestacion, aplica manejo integrado de forma localizada.';
    }
    if (normalized.contains('pulgilla') || normalized.contains('chicharrita')) {
      return 'Mantén monitoreo semanal y controla malezas alrededor. Actua solo si observas aumento de insectos y dano nuevo.';
    }

    return 'Mantén monitoreo del cultivo y repite la captura con buena luz para obtener una recomendación más precisa.';
  }

  String _resolveRecommendation(Map<String, dynamic> diag) {
    final recommendation = (diag['recommendation'] ?? '').toString().trim();
    final disease = _extractDiagnosisName(diag);
    if (recommendation.isNotEmpty) return recommendation;
    return _fallbackRecommendation(disease);
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ==========================================================
  // 🔽 AQUÍ ESTÁ EL CAMBIO IMPORTANTE: FILTRO ANTI NO_MAIZ 🔽
  // ==========================================================
  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => loading = true);

    List<Map<String, dynamic>> rawList = [];

    try {
      // 1. Intentar cargar de Internet
      final online = await ApiService.checkBackendHealth();
      final localRows = await DBService.getAllDiagnoses(userId: widget.userId);

      if (online) {
        final result = await ApiService.fetchDiagnoses(userId: widget.userId);

        if (result != null && result.isNotEmpty) {
          // Se fusiona con local para no perder diagnósticos que aún no estén
          // reflejados por el endpoint remoto en ese instante.
          rawList = [
            ...localRows,
            ...result,
          ];
        } else {
          // Si internet da lista vacía, usamos local por seguridad.
          rawList = localRows;
        }
      } else {
        // 2. Si no hay internet, cargar de Base de Datos local
        rawList = localRows;
      }
    } catch (e) {
      print("Error cargando historial: $e");
      rawList = await DBService.getAllDiagnoses(userId: widget.userId);
    }

    // 3. FILTRADO INTELIGENTE (Detecta mayúsculas/minúsculas)
    // Solo dejamos pasar los que NO contengan "no_maiz"
    final filteredList = rawList.where((item) {
      // Obtenemos el nombre efectivo sin depender de un único campo.
      final diseaseName = _extractDiagnosisName(item).toLowerCase();

      // Si contiene "no_maiz", devolvemos false (se elimina de la lista)
      // También filtramos "unknown" por si acaso
      return !diseaseName.contains('no_maiz') &&
          !diseaseName.contains('unknown');
    }).toList();

    // 3.1 Eliminar duplicados por id/clave estable para evitar tarjetas repetidas
    final uniqueMap = <String, Map<String, dynamic>>{};
    for (final item in filteredList) {
      uniqueMap[_diagKey(item)] = item;
    }
    final uniqueList = uniqueMap.values.toList();

    // 4. Actualizamos la pantalla con la lista limpia
    if (mounted) {
      setState(() {
        diagnoses.clear();
        diagnoses.addAll(uniqueList);
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      // Usamos un Stack para el fondo decorativo
      body: Stack(
        children: [
          // 1. FONDO ONDULADO (Decoración)
          ClipPath(
            clipper: _HistoryWaveClipper(),
            child: Container(
              height: size.height * 0.35, // Altura del encabezado
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF81C784), darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABECERA PERSONALIZADA ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history_edu_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Historial",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "Tus diagnósticos pasados",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- LISTA DE DIAGNÓSTICOS ---
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(color: darkGreen),
                        )
                      : diagnoses.isEmpty
                          ? _buildEmptyState()
                          : Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: FutureBuilder<String>(
                                future: ApiService.baseUrl,
                                builder: (context, snap) {
                                  final base = snap.data ?? "";

                                  return RefreshIndicator(
                                    onRefresh: _loadHistory,
                                    color: darkGreen,
                                    backgroundColor: Colors.white,
                                    child: ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(
                                          top: 0, bottom: 20),
                                      itemCount: diagnoses.length,
                                      itemBuilder: (context, index) {
                                        final diag = diagnoses[index];
                                        return KeyedSubtree(
                                          key: ValueKey(_diagKey(diag)),
                                          child:
                                              _buildDiagnosisCard(diag, base),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS DECORATIVOS AUXILIARES
  // ==========================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 15),
          Text(
            "Aún no tienes diagnósticos",
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Text(
            "Escanea tu primera planta para comenzar",
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(Map<String, dynamic> diag, String base) {
    final imagePath = diag["image_path"] ?? "";

    // LOGICA DE IMAGEN HIBRIDA (Fix para modo offline/sincronizado)
    Widget imageWidget;
    if (imagePath.startsWith("http")) {
      imageWidget = Image.network(imagePath,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
    } else if (imagePath.startsWith("/") ||
        imagePath.contains("cache") ||
        imagePath.contains("data/user")) {
      // Si es una ruta local del celular
      imageWidget = Image.file(File(imagePath),
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
    } else {
      // Si es una ruta relativa del servidor
      final url =
          "$base/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}";
      imageWidget = Image.network(url,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
    }

    final double confidence = (diag['confidence'] is num)
        ? (diag['confidence'] as num).toDouble()
        : 0.0;

    final String dateStr = (diag["created_at"] ?? "").toString();
    final String displayDate =
        dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    final diseaseLabel = _prettyDiseaseLabel(_extractDiagnosisName(diag));
    final recommendationText = _resolveRecommendation(diag);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiagnosisDetailScreen(diag: diag),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: "diag_img_${diag['id'] ?? UniqueKey()}",
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageWidget,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            displayDate,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        diseaseLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendationText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getConfidenceColor(confidence).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _getConfidenceColor(confidence)
                                  .withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 14,
                                color: _getConfidenceColor(confidence)),
                            const SizedBox(width: 4),
                            Text(
                              "${(confidence * 100).toStringAsFixed(0)}% Precisión",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getConfidenceColor(confidence),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Icon(Icons.chevron_right_rounded,
                      color: Colors.grey[300]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported_rounded, color: Colors.grey[400]),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return darkGreen;
    if (confidence > 0.5) return Colors.orange[700]!;
    return Colors.red[400]!;
  }
}

class _HistoryWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
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
