import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'db_service.dart';
import 'api_service.dart';
import 'session_service.dart';

class SyncService {
  static bool _isSyncing = false;

  // ===============================================================
  // LISTENER AUTOMÁTICO
  // ===============================================================
  static void startSyncListener() {
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result != ConnectivityResult.none) {
        print("🔌 Conexión detectada — iniciando sincronización offline...");
        await syncOfflineData();
      }
    });
  }

  static Future<void> syncOfflineData() async {
    if (_isSyncing) {
      print("⏳ syncOfflineData: ya hay una sincronización en curso, se omite.");
      return;
    }

    _isSyncing = true;
    try {
      await DBService.deletePendingDiagnosesWithoutServerUser();
      await syncPendingUsers();
      await syncPendingDiagnoses();
    } finally {
      _isSyncing = false;
    }
  }

  // ===============================================================
  // USUARIOS PENDIENTES
  // ===============================================================
  static Future<void> syncPendingUsers() async {
    final users = await DBService.getUnsyncedUsers();
    if (users.isEmpty) return;

    print("🔄 Sincronizando usuarios pendientes (${users.length})...");

    for (final user in users) {
      final res = await ApiService.registerUser(
        user['name'],
        user['email'],
        user['password'],
      );

      final success = res != null && res['id'] != null;

      if (success) {
        print("✔ Usuario sincronizado: ${user['email']}");
        await DBService.markUserAsSynced(user['id'], res['id']);
      } else {
        print("❌ Error al sincronizar usuario: ${user['email']}");
      }
    }
  }

  // ===============================================================
  // DIAGNÓSTICOS OFFLINE
  // ===============================================================
  static Future<void> syncPendingDiagnoses() async {
    final pending = await DBService.getPendingDiagnoses();
    if (pending.isEmpty) return;

    print("🔄 Sincronizando diagnósticos pendientes (${pending.length})...");

    for (final diag in pending) {
      final int localUserId = diag['user_id'];
      int? serverUserId = await DBService.getServerIdForLocalUser(localUserId);

      serverUserId ??= SessionService.userId;

      if (serverUserId == null) {
        print(
            "⚠️ Saltando sync: user local $localUserId sin server_id ni sesión");
        continue;
      }

      final String imagePath = diag['image_path'];
      final int? cropId = diag['crop_id'];
      final double? latitude = diag['lat'] ?? diag['latitude'];
      final double? longitude = diag['lng'] ?? diag['longitude'];

      if (!File(imagePath).existsSync()) {
        print("⚠️ Archivo offline no encontrado: $imagePath");
        continue;
      }

      //  FIX: INCLUIR EL ID LOCAL EN EL PAYLOAD
      final payload = {
        "id": diag['id'], //
        "user_id": serverUserId,
        "crop_id": cropId,
        "latitude": latitude,
        "longitude": longitude,
        "image_path": imagePath,
      };

      print("📤 Enviando diagnóstico offline...");
      final res = await ApiService.uploadImageToCropFromOffline(payload);

      final bool success =
          res != null && (res["success"] == true || res["diagnosis"] != null);

      if (success) {
        print("✔ Diagnóstico sincronizado correctamente");
        final localId = diag['id'] is int
            ? diag['id'] as int
            : int.tryParse('${diag['id']}');

        if (localId != null) {
          // Borrado inmediato del pendiente para evitar re-envío en refrescos.
          await DBService.deletePendingDiagnosisById(localId);
        }
      } else {
        print("❌ Error al sincronizar diagnóstico offline: $res");
      }
    }
  }
}
