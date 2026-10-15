import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/db_service.dart';
import 'package:maiz_app/screens/diagnosis_detail_screen.dart';
import 'package:maiz_app/services/session_service.dart'; // Asegúrate de importar esto

class CropDiagnosisScreen extends StatefulWidget {
  final int cropId;
  final String cropName;

  const CropDiagnosisScreen({
    super.key,
    required this.cropId,
    required this.cropName,
  });

  @override
  State<CropDiagnosisScreen> createState() => _CropDiagnosisScreenState();
}

class _CropDiagnosisScreenState extends State<CropDiagnosisScreen> {
  bool loading = true;
  List<Map<String, dynamic>> diagnoses = [];

  static const Color primaryGreen = Color(0xFF2E7D32);

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

  bool _isNoEsPlaga(String diseaseName) {
    final normalized = _normalizeText(diseaseName.replaceAll('_', ' '));
    return normalized.contains('no es plaga') || normalized.contains('no plaga');
  }

  bool _isPlaceholderRecommendation(String recommendation) {
    final normalized = _normalizeText(recommendation.replaceAll('_', ' '));
    if (normalized.isEmpty) return true;

    if (normalized == 'n/a' || normalized == 'na') return true;

    if (normalized.contains('sin recomendacion')) return true;
    if (normalized.contains('no recommendation')) return true;
    if (normalized.contains('recomendacion no disponible')) return true;
    if (normalized.contains('recommendation not available')) return true;

    return false;
  }

  String _resolveRecommendation(Map<String, dynamic> diag) {
    final recommendation = (diag['recommendation'] ?? '').toString().trim();
    final disease = (diag['disease'] ?? diag['label'] ?? '').toString();

    if (!_isPlaceholderRecommendation(recommendation)) {
      return recommendation;
    }

    if (_isNoEsPlaga(disease)) {
      return 'Sin recomendación disponible.';
    }

    return _fallbackRecommendation(disease);
  }

  String _formatConfidence(dynamic rawValue) {
    final value = double.tryParse('$rawValue') ?? 0.0;
    final pct = value <= 1.0 ? value * 100.0 : value;
    return '${pct.toStringAsFixed(2)}%';
  }

  Widget _fallbackImage() {
    return Container(
      alignment: Alignment.center,
      color: Colors.black12,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDiagnoses();
  }

  Future<void> _loadDiagnoses() async {
    setState(() => loading = true);

    final rawList = await ApiService.fetchDiagnosesByCrop(widget.cropId);
    final filteredList = (rawList ?? []).where((item) {
      final diseaseName = (item['disease'] ?? '').toString().toLowerCase();
      return !diseaseName.contains('no_maiz') &&
          !diseaseName.contains('unknown');
    }).toList();

    final localesPendientes = await DBService
      .obtenerDiagnosticosLocalesPendientesPorParcela(widget.cropId);

    final merged = [
      ...localesPendientes,
      ...filteredList,
    ];

    // Deduplicar priorizando la ruta remota (server_image_path) para que
    // el mismo diagnóstico offline + online no genere dos tarjetas.
    String _normalizePath(String value) {
      final clean = value.trim();
      if (clean.isEmpty) return '';
      // Toma solo el nombre de archivo para coincidir local/servidor
      final parts = clean.split(RegExp(r'[\\/]'));
      return parts.isNotEmpty ? parts.last : clean;
    }

    String _dedupKey(Map<String, dynamic> item) {
      final serverImg =
          (item['server_image_path'] ?? item['serverImagePath'])?.toString();
      if (serverImg != null && serverImg.isNotEmpty) {
        return 'srvimg_${_normalizePath(serverImg)}';
      }

      final img = (item['image_path'] ?? item['imagePath'])?.toString();
      if (img != null && img.isNotEmpty) {
        return 'img_${_normalizePath(img)}';
      }

      final srv = item['server_id']?.toString();
      if (srv != null && srv.isNotEmpty) return 'srv_$srv';

      final id = item['id']?.toString();
      if (id != null && id.isNotEmpty) return 'loc_$id';

      return (item['created_at'] ??
              item['createdAt'] ??
              DateTime.now().toIso8601String())
          .toString();
    }

    final Map<String, Map<String, dynamic>> unique = {};
    for (final item in merged) {
      unique[_dedupKey(item)] = item;
    }

    final mergedList = unique.values.toList();

    merged.sort((a, b) {
      final aDate = DateTime.tryParse(
              '${a['created_at'] ?? a['createdAt'] ?? a['createdAt']}') ??
          DateTime.now();
      final bDate = DateTime.tryParse(
              '${b['created_at'] ?? b['createdAt'] ?? b['createdAt']}') ??
          DateTime.now();
      return bDate.compareTo(aDate);
    });
    mergedList.sort((a, b) {
      final aDate = DateTime.tryParse(
              '${a['created_at'] ?? a['createdAt'] ?? a['createdAt']}') ??
          DateTime.now();
      final bDate = DateTime.tryParse(
              '${b['created_at'] ?? b['createdAt'] ?? b['createdAt']}') ??
          DateTime.now();
      return bDate.compareTo(aDate);
    });

    setState(() {
      diagnoses = mergedList;
      loading = false;
    });
  }

  // ============================================================
  // UI FINAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      // ============================================================
      // APPBAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            children: [
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  Icons.spa, // 🌱 icono suave
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(text: "Diagnósticos de ${widget.cropName}"),
            ],
          ),
        ),
      ),

      // ❌ ELIMINADO: FloatingActionButton (Botón Nuevo Diagnóstico)

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : diagnoses.isEmpty
              ? const Center(
                  child: Text(
                    "No hay diagnósticos válidos para este cultivo.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDiagnoses,
                  child: FutureBuilder<String>(
                    future: ApiService.baseUrl,
                    builder: (context, snap) {
                      final base = snap.data ?? "";

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: diagnoses.length,
                        itemBuilder: (context, index) {
                          final diag = diagnoses[index];

                          final double confValue =
                              double.tryParse('${diag['confidence']}') ?? 0.0;
                          final bool isPending = confValue == 0.0;
                            final String rawLabel =
                              (diag['label'] ?? diag['disease'] ?? 'Desconocido')
                                .toString();
                            final String label = _prettyDiseaseLabel(rawLabel);
                            final String recommendation =
                              _resolveRecommendation(diag);
                          final localPath =
                              (diag["image_path"] ?? diag["imagePath"] ?? "")
                                  .toString();
                          final remotePath = (diag['server_image_path'] ??
                                  diag['serverImagePath'] ??
                                  '')
                              .toString();

                          String? networkUrl;
                          if (remotePath.isNotEmpty) {
                            networkUrl = remotePath.startsWith('http')
                                ? remotePath
                                : "$base/${remotePath.startsWith("/") ? remotePath.substring(1) : remotePath}";
                          } else if (localPath.startsWith('http')) {
                            networkUrl = localPath;
                          } else if (localPath.isNotEmpty &&
                              !localPath.startsWith('http')) {
                            networkUrl =
                                "$base/${localPath.startsWith("/") ? localPath.substring(1) : localPath}";
                          }

                          final fileCandidate = (localPath.isNotEmpty &&
                                  !localPath.startsWith('http'))
                              ? File(localPath)
                              : null;

                          return GestureDetector(
                            onTap: () {
                              // ====================================================
                              // 🚀 AQUÍ OCURRE LA MAGIA DEL NOMBRE
                              // ====================================================
                              // Creamos una copia de los datos del diagnóstico
                              // y le inyectamos el nombre del usuario desde SessionService
                              Map<String, dynamic> diagConNombre =
                                  Map.from(diag);

                              if (SessionService.userName != null) {
                                diagConNombre['user_name'] =
                                    SessionService.userName;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DiagnosisDetailScreen(
                                      diag: diagConNombre),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                    0.9), // Fondo un poco más sólido
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Row(
                                  children: [
                                    // ==============================
                                    // IMAGEN
                                    // ==============================
                                    SizedBox(
                                      height: 120,
                                      width: 120,
                                      child: (fileCandidate != null &&
                                              fileCandidate.existsSync())
                                          ? Image.file(
                                              fileCandidate,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _fallbackImage(),
                                            )
                                          : (networkUrl != null
                                              ? Image.network(
                                                  networkUrl,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, progress) {
                                                    if (progress == null)
                                                      return child;
                                                    return Container(
                                                      alignment:
                                                          Alignment.center,
                                                      color: Colors.black12,
                                                      child:
                                                          const CircularProgressIndicator(),
                                                    );
                                                  },
                                                  errorBuilder: (_, __, ___) =>
                                                      _fallbackImage(),
                                                )
                                              : _fallbackImage()),
                                    ),

                                    const SizedBox(width: 16),

                                    // ==============================
                                    // TEXTO
                                    // ==============================
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal:
                                              8, // Un poco de padding derecho
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isPending
                                                  ? "⏳ PENDIENTE (Sincronizando...)"
                                                  : "Resultado: $label",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isPending
                                                    ? Colors.orange
                                                    : primaryGreen,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              recommendation,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Confianza: ${_formatConfidence(diag['confidence'])}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
