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
  static const Duration blockRequestTimeout = Duration(seconds: 7);
  static const Duration retryDelay = Duration(milliseconds: 400);

  // Datos fijos del dataset de enfermedades usado para entrenar la IA.
  static const List<Map<String, dynamic>> fixedDiseaseDatasetCounts = [
    {"label": "hoja sana", "count": 885},
    {"label": "mancha gris", "count": 513},
    {"label": "roya", "count": 870},
    {"label": "tizon", "count": 879},
    {"label": "no maiz", "count": 1011},
  ];

  // Datos fijos del dataset de plagas usado para entrenar la IA.
  static const List<Map<String, dynamic>> fixedPestDatasetCounts = [
    {"label": "gusano cortador amarillo", "count": 1143},
    {"label": "no es plaga", "count": 1011},
    {"label": "pulgilla", "count": 3789},
    {"label": "gusano ejercito", "count": 858},
    {"label": "pulgones", "count": 839},
  ];

  final List<String> fixedDiseaseLabels = const [
    "hoja sana",
    "mancha gris",
    "roya",
    "tizon",
    "no maiz",
  ];

  final List<Color> chartColors = const [
    Colors.green,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.cyan,
    Colors.amber,
    Colors.deepOrange,
    Colors.lime,
  ];

  Map<String, dynamic>? overview;
  List<Map<String, dynamic>> diseases = [];
  List<Map<String, dynamic>> dataset = [];
  List<Map<String, dynamic>> pestDataset =
      List<Map<String, dynamic>>.from(fixedPestDatasetCounts);
  bool loading = true;
  bool error = false;
  bool unauthorizedRole = false;

  bool overviewLoading = false;
  bool diseasesLoading = false;
  bool datasetLoading = false;

  bool overviewError = false;
  bool diseasesError = false;
  bool datasetError = false;

  int _overviewRequestId = 0;
  int _diseasesRequestId = 0;
  int _datasetRequestId = 0;

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

      if (!mounted) return;
      setState(() {
        loading = false;
        overviewLoading = true;
        diseasesLoading = true;
        datasetLoading = true;
        overviewError = false;
        diseasesError = false;
        datasetError = false;
      });

      _loadOverviewBlock();
      _loadDiseasesBlock();
      _loadDatasetBlock();
    } catch (_) {
      if (!mounted) return;
      setState(() => error = true);
    }
  }

  Future<void> _loadOverviewBlock() async {
    final requestId = ++_overviewRequestId;
    if (!mounted) return;
    setState(() {
      overviewLoading = true;
      overviewError = false;
    });

    try {
      final resOverview = await _fetchWithOneRetry(
        () => ApiService.fetchAdminStatsOverview(),
      );
      if (!mounted) return;
      if (requestId != _overviewRequestId) return;

      if (resOverview == null) {
        setState(() {
          overviewError = true;
          overviewLoading = false;
        });
        return;
      }

      setState(() {
        overview = _extractOverviewPayload(resOverview);
        overviewError = false;
        overviewLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        overviewError = true;
        overviewLoading = false;
      });
    }
  }

  Future<void> _loadDiseasesBlock() async {
    final requestId = ++_diseasesRequestId;
    if (!mounted) return;
    setState(() {
      diseasesLoading = true;
      diseasesError = false;
    });

    try {
      final resDiseases = await _fetchWithOneRetry(
        () => ApiService.fetchAdminStatsDiseases(),
      );
      if (!mounted) return;
      if (requestId != _diseasesRequestId) return;

      if (resDiseases == null) {
        setState(() {
          diseasesError = true;
          diseasesLoading = false;
        });
        return;
      }

      final diseaseRows = _extractListPayload(resDiseases);
      final diseaseCounter = <String, int>{};

      for (final row in diseaseRows) {
        final label = _extractLabel(row);
        if (label.isEmpty) continue;
        diseaseCounter[label] =
            (diseaseCounter[label] ?? 0) + _toInt(row['count']);
      }

      final diseaseEntries = diseaseCounter.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        diseases = diseaseEntries
            .map((e) => {'label': e.key, 'count': e.value})
            .toList();
        diseasesError = false;
        diseasesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        diseasesError = true;
        diseasesLoading = false;
      });
    }
  }

  Future<void> _loadDatasetBlock() async {
    final requestId = ++_datasetRequestId;
    if (!mounted) return;
    setState(() {
      datasetLoading = true;
      datasetError = false;
    });

    try {
      final resDataset = await _fetchWithOneRetry(
        () => ApiService.fetchAdminStatsDataset(),
      );
      if (!mounted) return;
      if (requestId != _datasetRequestId) return;

      final datasetRows = resDataset != null
          ? _extractListPayload(resDataset)
          : <Map<String, dynamic>>[];

      final nextDataset = datasetRows.isNotEmpty
          ? fixedDiseaseLabels.map((lbl) {
              final match = datasetRows.firstWhere(
                (x) => (x['disease'] ?? x['label'] ?? '').toString() == lbl,
                orElse: () => {'count': 0},
              );
              return {'label': lbl, 'count': _toInt(match['count'])};
            }).toList()
          : List<Map<String, dynamic>>.from(fixedDiseaseDatasetCounts);

      setState(() {
        dataset = nextDataset;
        pestDataset = List<Map<String, dynamic>>.from(fixedPestDatasetCounts);
        datasetError = false;
        datasetLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        datasetError = true;
        datasetLoading = false;
        // Incluso si falla el endpoint, mostramos dataset fijo para no dejar vacío.
        dataset = List<Map<String, dynamic>>.from(fixedDiseaseDatasetCounts);
        pestDataset = List<Map<String, dynamic>>.from(fixedPestDatasetCounts);
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchWithOneRetry(
    Future<Map<String, dynamic>?> Function() request,
  ) async {
    try {
      return await request().timeout(blockRequestTimeout);
    } catch (_) {
      await Future.delayed(retryDelay);
      return await request().timeout(blockRequestTimeout);
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

  int pestDatasetTotal() {
    return pestDataset.fold(0, (sum, item) => sum + (item["count"] as int));
  }

  Color _colorForIndex(int index) {
    return chartColors[index % chartColors.length];
  }

  String _extractLabel(Map<String, dynamic> row) {
    final raw =
        (row['disease'] ?? row['label'] ?? row['class'] ?? '').toString();
    return raw.trim();
  }

  bool _hasPestLabels(Iterable<String> labels) {
    for (final label in labels) {
      final normalized = label.toLowerCase();
      if (normalized.startsWith('plaga:') ||
          normalized.contains('pulgon') ||
          normalized.contains('pulgilla') ||
          normalized.contains('gusano')) {
        return true;
      }
    }
    return false;
  }

  Future<Map<String, int>> _buildLiveLabelStatsFromDiagnoses() async {
    final users = await ApiService.fetchUsers() ?? [];
    final counter = <String, int>{};

    for (final u in users) {
      final userId =
          (u['id'] is int) ? u['id'] as int : int.tryParse('${u['id']}') ?? 0;
      if (userId == 0) continue;

      final diags = await ApiService.fetchDiagnoses(userId: userId) ?? [];
      for (final d in diags) {
        final label = (d['label'] ??
                d['disease'] ??
                d['prediction'] ??
                d['class'] ??
                d['result'] ??
                '')
            .toString()
            .trim();
        if (label.isEmpty) continue;
        counter[label] = (counter[label] ?? 0) + 1;
      }
    }

    return counter;
  }

  List<PieChartSectionData> buildDiseaseChart() {
    return diseases.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value["count"] as int).toDouble();

      return PieChartSectionData(
        value: value,
        color: _colorForIndex(index),
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
        color: _colorForIndex(index),
        radius: 70,
        title: '',
      );
    }).toList();
  }

  List<PieChartSectionData> buildPestDatasetChart() {
    return pestDataset.asMap().entries.map((entry) {
      final index = entry.key;
      final value = (entry.value["count"] as int).toDouble();

      return PieChartSectionData(
        value: value,
        color: _colorForIndex(index),
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
              _statCard(
                "Usuarios",
                overviewLoading ? "..." : "${overview?['users'] ?? 0}",
                Icons.people,
                primaryGreen,
                isLoading: overviewLoading,
              ),
              const SizedBox(width: 10),
              _statCard(
                "Diagnósticos",
                overviewLoading ? "..." : "${overview?['diagnoses'] ?? 0}",
                Icons.medical_services,
                Colors.orange,
                isLoading: overviewLoading,
              ),
            ],
          ),
          if (overviewError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _inlineBlockError(
                "No se pudieron cargar los totales.",
                _loadOverviewBlock,
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text("Actualizar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _title("Diagnósticos más comunes"),
          _subtitle(
              "Incluye enfermedades y plagas detectadas en registros reales de usuarios."),
          if (diseasesLoading)
            const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (diseasesError)
            _blockError(
              "No se pudieron cargar diagnósticos comunes.",
              _loadDiseasesBlock,
            )
          else ...[
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
            _legend(diseases, prettifyLabels: true),
          ],
          const SizedBox(height: 40),
          _title("Total de datos usados para entrenar IA enfermedades"),
          _subtitle("Cantidad de imágenes del dataset de enfermedades."),
          if (datasetLoading)
            const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (datasetError)
            _blockError(
              "No se pudo cargar dataset de enfermedades.",
              _loadDatasetBlock,
            )
          else
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
          const SizedBox(height: 40),
          _title("Total de datos usados para entrenar IA plagas"),
          _subtitle("Cantidad de imágenes del dataset de plagas."),
          SizedBox(
            height: 260,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 4,
                sections: buildPestDatasetChart(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.orange.shade50,
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
                      color: Colors.orange.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bug_report,
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
                        "${pestDatasetTotal()}",
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
          _legend(pestDataset),
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

  String _prettifyLabel(dynamic rawLabel) {
    final raw = (rawLabel ?? '').toString().trim();
    if (raw.isEmpty) return '';

    final withoutSeparators =
        raw.replaceAll('_', ' ').replaceAll('-', ' ').replaceAll(':', ' ');
    final collapsed = withoutSeparators.replaceAll(RegExp(r'\s+'), ' ');
    final lower = collapsed.toLowerCase();

    return lower[0].toUpperCase() + lower.substring(1);
  }

  Widget _legend(List<Map<String, dynamic>> items,
      {bool prettifyLabels = false}) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text("Sin datos disponibles"),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final label = prettifyLabels
            ? _prettifyLabel(entry.value["label"])
            : (entry.value["label"] ?? '').toString();
        final count = entry.value["count"];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _colorForIndex(index),
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

  Widget _blockError(String message, Future<void> Function() onRetry) {
    return SizedBox(
      height: 220,
      child: Center(
        child: _inlineBlockError(message, onRetry),
      ),
    );
  }

  Widget _inlineBlockError(String message, Future<void> Function() onRetry) {
    final isLoading = _isBlockLoading(onRetry);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: const TextStyle(color: Colors.redAccent)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onRetry,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(isLoading ? "Cargando..." : "Reintentar bloque"),
        ),
      ],
    );
  }

  bool _isBlockLoading(Future<void> Function() onRetry) {
    if (identical(onRetry, _loadOverviewBlock)) return overviewLoading;
    if (identical(onRetry, _loadDiseasesBlock)) return diseasesLoading;
    if (identical(onRetry, _loadDatasetBlock)) return datasetLoading;
    return false;
  }

  Widget _statCard(String title, String value, IconData icon, Color color,
      {bool isLoading = false}) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Text(value,
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
