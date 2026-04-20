import 'package:flutter/material.dart';

class TrashParcelsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> trashedParcels;
  final void Function(Map<String, dynamic> parcel) onRestore;

  const TrashParcelsScreen({
    super.key,
    required this.trashedParcels,
    required this.onRestore,
  });

  @override
  State<TrashParcelsScreen> createState() => _TrashParcelsScreenState();
}

class _TrashParcelsScreenState extends State<TrashParcelsScreen> {
  static const Color primaryColor = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color bgColor = Color(0xFFF1F8E9);

  late List<Map<String, dynamic>> _trashedParcels;

  @override
  void initState() {
    super.initState();
    _trashedParcels = List<Map<String, dynamic>>.from(widget.trashedParcels);
  }

  void _restoreParcel(Map<String, dynamic> parcel) {
    widget.onRestore(parcel);
    setState(() {
      _trashedParcels.removeWhere((item) => item['id'] == parcel['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkGreen,
        title: const Text('Papelera'),
      ),
      body: _trashedParcels.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: darkGreen.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 44, color: darkGreen),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No hay parcelas en papelera',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Las parcelas que muevas desde el menú aparecerán aquí para poder restaurarlas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trashedParcels.length,
              itemBuilder: (context, index) {
                final parcel = _trashedParcels[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.orangeAccent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  parcel['name']?.toString() ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lat: ${parcel['latitude']}  |  Lng: ${parcel['longitude']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _restoreParcel(parcel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.restore_rounded),
                          label: const Text('Restaurar'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
