import 'dart:io';
import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';

class DiagnosisThumb extends StatelessWidget {
  final String? pathOrUrl;
  final double size;

  const DiagnosisThumb({
    super.key,
    required this.pathOrUrl,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final p = (pathOrUrl ?? '').trim();

    Widget placeholder() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.image_outlined, size: 28),
        );

    if (p.isEmpty) return placeholder();

    // Si ya viene como URL completa
    if (p.startsWith('http')) {
      return _netImage(p, placeholder);
    }

    // Si es ruta local del teléfono
    final file = File(p);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: 200,
        ),
      );
    }

    // Si es ruta relativa del servidor (ej: /uploads/xxx.jpg)
    return FutureBuilder<String>(
      future: ApiService.baseUrl,
      builder: (context, snap) {
        final base = snap.data;
        if (base == null) return placeholder();

        final url = p.startsWith('/') ? '$base$p' : '$base/$p';
        return _netImage(url, placeholder);
      },
    );
  }

  Widget _netImage(String url, Widget Function() placeholder) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) => placeholder(),
      ),
    );
  }
}
