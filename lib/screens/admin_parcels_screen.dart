import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/screens/admin_user_detail_screen.dart';
import 'package:maiz_app/screens/admin_diseases_screen.dart';

class AdminParcelsScreen extends StatefulWidget {
  const AdminParcelsScreen({super.key});

  @override
  State<AdminParcelsScreen> createState() => _AdminParcelsScreenState();
}

class _AdminParcelsScreenState extends State<AdminParcelsScreen> {
  late Future<List<Map<String, dynamic>>?> _usersFuture;

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _usersFuture = ApiService.fetchUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = ApiService.fetchUsers();
    });
  }

  _UserSummary _extractSummaryFromUser(Map<String, dynamic> user) {
    final parcelsCount = _readFirstInt(user, const [
      'parcels_count',
      'parcelas_count',
      'total_parcels',
      'parcel_count',
      'crops_count',
    ]);

    final imagesCount = _readFirstInt(user, const [
      'diagnoses_count',
      'diagnosticos_count',
      'images_count',
      'imagenes_count',
      'total_diagnoses',
      'total_images',
    ]);

    return _UserSummary(
      parcelsCount: parcelsCount,
      imagesCount: imagesCount,
    );
  }

  int? _readFirstInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is double) return value.round();
      final parsed = int.tryParse('$value');
      if (parsed != null) return parsed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(40),
              children: const [
                Center(child: Text("No hay usuarios para mostrar.")),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            children: [
              // ===== HEADER =====
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Gestión de parcelas",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDiseasesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.coronavirus_outlined),
                    label: const Text("Enfermedades"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ===== USERS =====
              ...users.map((u) {
                final int userId = (u['id'] is int)
                    ? u['id']
                    : int.tryParse("${u['id']}") ?? 0;
                final String name = "${u['name'] ?? 'Sin nombre'}";
                final String email = "${u['email'] ?? ''}";

                if (userId == 0) {
                  return _userCardError();
                }

                final summary = _extractSummaryFromUser(u);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _glassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _miniStat(
                                  icon: Icons.map_outlined,
                                  label: "Parcelas",
                                  value: summary.parcelsCount?.toString() ??
                                      "N/D",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _miniStat(
                                  icon: Icons.image_outlined,
                                  label: "Imágenes",
                                  value:
                                      summary.imagesCount?.toString() ?? "N/D",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminUserDetailScreen(
                                      userId: userId,
                                      userName: name,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Ver detalles"),
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
    );
  }

  // ===== MINI STAT =====
  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
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
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
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

  Widget _userCardError() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: const ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text("Usuario inválido"),
        subtitle: Text("No tiene identificador válido."),
      ),
    );
  }
}

class _UserSummary {
  final int? parcelsCount;
  final int? imagesCount;

  _UserSummary({
    required this.parcelsCount,
    required this.imagesCount,
  });
}
