import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/session_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  // Datos fijos del dataset usado para entrenar la IA (no deben cambiar).
  static const List<Map<String, dynamic>> fixedDatasetCounts = [
    {"label": "hoja_sana", "count": 885},
    {"label": "mancha_gris", "count": 513},
    {"label": "roya", "count": 870},
    {"label": "tizon", "count": 879},
    {"label": "no_maiz", "count": 1011},
  ];

  final List<String> fixedLabels = const [
    "hoja_sana",
    "mancha_gris",
    "roya",
    "tizon",
    "no_maiz",
  ];

  final List<Color> fixedColors = const [
    Colors.green,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.blue,
  ];

  Map<String, dynamic>? overview;
  List<Map<String, dynamic>> diseases = [];
  List<Map<String, dynamic>> dataset = [];
  bool loading = true;
  bool error = false;
  bool unauthorizedRole = false;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = false;
      unauthorizedRole = false;
    });

    try {
      final role = (SessionService.userRole ?? '').trim().toLowerCase();
      if (role != 'administrador') {
        if (!mounted) return;
        setState(() {
          loading = false;
          unauthorizedRole = true;
        });
        return;
      }

      final resDiseases = await ApiService.fetchAdminStatsDiseases();
      final resOverview = await ApiService.fetchAdminStatsOverview();
      final resDataset = await ApiService.fetchAdminStatsDataset();

      if (resDiseases == null || resOverview == null) {
        if (!mounted) return;
        setState(() => error = true);
        return;
      }

      final diseaseRows = _extractListPayload(resDiseases);
      final datasetRows = resDataset != null
          ? _extractListPayload(resDataset)
          : <Map<String, dynamic>>[];
      final overviewMap = _extractOverviewPayload(resOverview);

      diseases = fixedLabels.map((lbl) {
        final match = diseaseRows.firstWhere(
          (x) => (x['disease'] ?? x['label'] ?? '').toString() == lbl,
          orElse: () => {'count': 0},
        );
        return {'label': lbl, 'count': _toInt(match['count'])};
      }).toList();

      if (datasetRows.isNotEmpty) {
        dataset = fixedLabels.map((lbl) {
          final match = datasetRows.firstWhere(
            (x) => (x['disease'] ?? x['label'] ?? '').toString() == lbl,
            orElse: () => {'count': 0},
          );
          return {'label': lbl, 'count': _toInt(match['count'])};
        }).toList();
      } else {
        dataset = List<Map<String, dynamic>>.from(fixedDatasetCounts);
      }

      overview = overviewMap;

      if (!mounted) return;
      setState(() => loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => error = true);
    }
  }

  List<Map<String, dynamic>> _extractListPayload(Map<String, dynamic> payload) {
    final dynamic listData = payload['data'] ??
        payload['items'] ??
        payload['stats'] ??
        payload['diseases'];
    if (listData is List) {
      return listData
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractOverviewPayload(Map<String, dynamic> payload) {
    final dynamic data =
        payload['totals'] ?? payload['overview'] ?? payload['data'] ?? payload;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return {
        'users': _toInt(map['users'] ?? map['total_users']),
        'diagnoses': _toInt(map['diagnoses'] ?? map['total_diagnoses']),
      };
    }
    return {'users': 0, 'diagnoses': 0};
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  int datasetTotal() {
    return dataset.fold(0, (sum, item) => sum + (item["count"] as int));
  }

  List<PieChartSectionData> buildDiseaseChart() {
    return diseases.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value["count"] as int).toDouble();

      return PieChartSectionData(
        value: value,
        color: fixedColors[index],
        radius: 70,
        title: '',
      );
    }).toList();
  }

  List<PieChartSectionData> buildDatasetChart() {
    return dataset.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value["count"] as int).toDouble();

      return PieChartSectionData(
        value: value,
        color: fixedColors[index],
        radius: 70,
        title: '',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Error cargando estadísticas",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
            )
          ],
        ),
      );
    }

    if (unauthorizedRole) {
      return const Center(
        child: Text(
          'Acceso restringido: solo Administrador.',
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              _statCard("Usuarios", "${overview?['users'] ?? 0}", Icons.people,
                  primaryGreen),
              const SizedBox(width: 10),
              _statCard("Diagnósticos", "${overview?['diagnoses'] ?? 0}",
                  Icons.medical_services, Colors.orange),
            ],
          ),
          const SizedBox(height: 30),
          _title("Enfermedades comunes"),
          _subtitle("Basado en diagnósticos reales hechos por los usuarios."),
          SizedBox(
            height: 260,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 4,
                sections: buildDiseaseChart(),
              ),
            ),
          ),
          _legend(diseases),
          const SizedBox(height: 40),
          _title("Total de datos utilizados para entrenar la IA"),
          _subtitle("Cantidad total de imágenes procesadas por la IA."),
          SizedBox(
            height: 260,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 4,
                sections: buildDatasetChart(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.green.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_chart,
                        size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total de imágenes",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        "${datasetTotal()}",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _legend(dataset),
        ],
      ),
    );
  }

  Widget _title(String text) => Text(text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));

  Widget _subtitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );

  Widget _legend(List<Map<String, dynamic>> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value["label"];
        final count = entry.value["count"];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: fixedColors[index],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
              Text("$count",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
