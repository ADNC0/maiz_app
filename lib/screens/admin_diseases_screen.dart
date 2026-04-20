import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';

class AdminDiseasesScreen extends StatefulWidget {
  const AdminDiseasesScreen({super.key});

  @override
  State<AdminDiseasesScreen> createState() => _AdminDiseasesScreenState();
}

class _AdminDiseasesScreenState extends State<AdminDiseasesScreen> {
  late Future<_DiseaseSummary> _future;

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _future = _loadSummary();
  }

  Future<_DiseaseSummary> _loadSummary() async {
    final users = await ApiService.fetchUsers() ?? [];
    final Map<String, int> counts = {};
    int totalImages = 0;

    for (final u in users) {
      final int userId =
          (u['id'] is int) ? u['id'] : int.tryParse("${u['id']}") ?? 0;
      if (userId == 0) continue;

      final diags = await ApiService.fetchDiagnoses(userId: userId) ?? [];
      totalImages += diags.length;

      for (final d in diags) {
        final label =
            "${d['label'] ?? d['disease'] ?? d['prediction'] ?? d['class'] ?? d['result'] ?? 'Sin etiqueta'}";
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _DiseaseSummary(
      totalImages: totalImages,
      entries: entries,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Resumen de enfermedades"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_DiseaseSummary>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snap.data;
            if (data == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(40),
                children: const [
                  Center(child: Text("No se pudo cargar el resumen.")),
                ],
              );
            }

            if (data.entries.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(40),
                children: const [
                  Center(child: Text("Aún no hay diagnósticos registrados.")),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              children: [
                // ===== TOTAL =====
                _glassCard(
                  child: ListTile(
                    leading: const Icon(Icons.image_outlined,
                        color: primaryGreen, size: 32),
                    title: const Text(
                      "Total de imágenes analizadas",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      "${data.totalImages}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Enfermedades más comunes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                // ===== LIST =====
                ...data.entries.map((e) {
                  final percent = data.totalImages == 0
                      ? 0
                      : (e.value * 100 / data.totalImages);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _glassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.coronavirus_outlined,
                              color: primaryGreen,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${percent.toStringAsFixed(1)}% del total",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              e.value.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===== GLASS CARD =====
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DiseaseSummary {
  final int totalImages;
  final List<MapEntry<String, int>> entries;

  _DiseaseSummary({
    required this.totalImages,
    required this.entries,
  });
}
