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

    final localesPendientes =
        await DBService.obtenerDiagnosticosLocalesPorParcela(widget.cropId);

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
                          final String label =
                              diag['label'] ?? diag['disease'] ?? 'Desconocido';
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
                                              diag['recommendation'] ??
                                                  'Sin recomendación',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Confianza: ${confValue.toStringAsFixed(2)}%",
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
