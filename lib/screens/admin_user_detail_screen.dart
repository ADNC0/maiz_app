import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  // Future principal que controla TODO
  late Future<List<dynamic>> _masterFuture;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static final Color backgroundColor = Colors.grey[100]!;

  @override
  void initState() {
    super.initState();
    // Ejecutamos la lógica maestra de carga y precaché
    _masterFuture = _loadDataAndPrecacheImages();
  }

  /// Esta función hace TRES cosas:
  /// 1. Pide los datos JSON (Texto).
  /// 2. Busca las URLs de las imágenes dentro de los datos.
  /// 3. Fuerza la descarga de las imágenes (precache) ANTES de mostrar la pantalla.
  Future<List<dynamic>> _loadDataAndPrecacheImages() async {
    try {
      // 1. Cargar datos crudos
      final results = await Future.wait([
        ApiService.fetchParcels(widget.userId),
        ApiService.fetchDiagnoses(userId: widget.userId),
        ApiService.baseUrl,
      ]);

      final diagnoses = results[1] as List<Map<String, dynamic>>? ?? [];
      final baseUrl = results[2] as String;

      if (diagnoses.isEmpty) return results;

      // 2. Recolectar todas las URLs válidas
      final List<Future<void>> imagePreloadFutures = [];

      for (var d in diagnoses) {
        final rawPath = _getImagePath(d);
        if (rawPath != null) {
          String? fullUrl;
          if (rawPath.startsWith("http")) {
            fullUrl = rawPath;
          } else if (baseUrl.isNotEmpty) {
            fullUrl = rawPath.startsWith("/")
                ? "$baseUrl$rawPath"
                : "$baseUrl/$rawPath";
          }

          // 3. Si hay URL, forzamos la descarga (Precache)
          if (fullUrl != null && mounted) {
            // Añadimos la tarea de descarga a una lista de espera
            final imageProvider = NetworkImage(fullUrl);
            imagePreloadFutures.add(
              precacheImage(imageProvider, context).catchError((e) {
                // Si una imagen falla, no detenemos todo, solo la ignoramos en el precache
                debugPrint("Error precargando imagen: $e");
              }),
            );
          }
        }
      }

      // 4. Esperar a que TODAS las imágenes se descarguen
      if (imagePreloadFutures.isNotEmpty) {
        await Future.wait(imagePreloadFutures);
      }

      // Solo devolvemos los datos cuando las imágenes ya están en memoria
      return results;
    } catch (e) {
      debugPrint("Error general: $e");
      rethrow;
    }
  }

  // --- Funciones de utilidad ---

  String _getDiagnosisLabel(Map<String, dynamic> d) {
    return "${d['label'] ?? d['disease'] ?? d['prediction'] ?? d['class'] ?? d['result'] ?? 'Sin etiqueta'}";
  }

  String? _getImagePath(Map<String, dynamic> d) {
    final keys = [
      'image_url',
      'imageUrl',
      'url',
      'image',
      'image_path',
      'imagePath',
      'path',
      'file'
    ];
    for (final k in keys) {
      final v = d[k];
      if (v != null && "$v".trim().isNotEmpty) return "$v";
    }
    return null;
  }

  void _openImageZoom(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: Image.network(imageUrl),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Widgets de UI ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 🌽 WIDGET DE CARGA DEL CHOCLO 🌽
  Widget _buildCornLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 15, spreadRadius: 5)
              ],
            ),
            child: const Icon(
              Icons.agriculture,
              size: 80,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              color: primaryGreen,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Descargando imágenes...",
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),

      // FutureBuilder controla toda la pantalla
      body: FutureBuilder<List<dynamic>>(
        future: _masterFuture,
        builder: (context, snapshot) {
          // 1. ESTADO DE CARGA: Muestra el Choclo
          // Se quedará aquí hasta que TODAS las imágenes estén descargadas
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildCornLoader();
          }

          // 2. ESTADO DE ERROR
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Error al cargar datos:\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          }

          // 3. DATOS LISTOS (Solo se muestra cuando todo, incluido imágenes, está listo)
          final data = snapshot.data!;
          final parcels = data[0] as List<Map<String, dynamic>>? ?? [];
          final diagnoses = data[1] as List<Map<String, dynamic>>? ?? [];
          final baseUrl = data[2] as String;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ================= SECCIÓN PARCELAS =================
                _buildSectionTitle("Parcelas", Icons.map_outlined),

                if (parcels.isEmpty)
                  _buildEmptyState(
                      "El usuario no tiene parcelas.", Icons.landscape_outlined)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: parcels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = parcels[i];
                      final name =
                          "${p['name'] ?? p['variety'] ?? p['crop_name'] ?? 'Parcela'}";
                      final lat = p['latitude'] ?? p['lat'];
                      final lng = p['longitude'] ?? p['lng'];

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on,
                                color: primaryGreen),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              children: [
                                Icon(Icons.gps_fixed,
                                    size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  "${lat ?? '-'}, ${lng ?? '-'}",
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                /// ================= SECCIÓN IMÁGENES (GALERÍA) =================
                const SizedBox(height: 10),
                _buildSectionTitle(
                    "Galería de Diagnósticos", Icons.photo_library_outlined),

                if (diagnoses.isEmpty)
                  _buildEmptyState("El usuario no tiene diagnósticos.",
                      Icons.image_not_supported_outlined)
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: diagnoses.length,
                    itemBuilder: (context, i) {
                      final d = diagnoses[i];
                      final label = _getDiagnosisLabel(d);
                      final rawPath = _getImagePath(d);

                      String? url;
                      if (rawPath != null) {
                        if (rawPath.startsWith("http")) {
                          url = rawPath;
                        } else if (baseUrl.isNotEmpty) {
                          url = rawPath.startsWith("/")
                              ? "$baseUrl$rawPath"
                              : "$baseUrl/$rawPath";
                        }
                      }

                      return GestureDetector(
                        onTap: url == null
                            ? null
                            : () => _openImageZoom(context, url!),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  // Como YA hicimos precache, aquí no hace falta LoadingBuilder complejo
                                  // porque la imagen ya está en memoria. Saldrá instantáneamente.
                                  child: url == null
                                      ? Container(
                                          color: Colors.grey[100],
                                          child: const Icon(
                                            Icons.broken_image_rounded,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: Colors.grey[100],
                                            child: const Icon(
                                              Icons.error_outline,
                                              size: 30,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(16)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "DIAGNÓSTICO:",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
