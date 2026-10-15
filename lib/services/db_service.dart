import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'maiz_app.db');

    _db = await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        // ---------- USERS ----------
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            password TEXT,
            synced INTEGER DEFAULT 0,
            server_id INTEGER
          )
        ''');

        // ---------- CROPS (Parcela local) ----------
        await db.execute('''
          CREATE TABLE IF NOT EXISTS crops (
            id INTEGER PRIMARY KEY,
            user_id INTEGER,
            name TEXT,
            latitude REAL,
            longitude REAL,
            created_at TEXT
          )
        ''');

        // ---------- DIAGNOSES ----------
        await db.execute('''
          CREATE TABLE IF NOT EXISTS diagnoses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            crop_id INTEGER,
            image_path TEXT,
            server_image_path TEXT,
            disease TEXT,
            recommendation TEXT,
            confidence REAL,
            is_corn_leaf INTEGER,
            latitude REAL,
            longitude REAL,
            tipo TEXT DEFAULT 'enfermedad',
            created_at TEXT,
            uploaded INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS crops (
                id INTEGER PRIMARY KEY,
                user_id INTEGER,
                name TEXT,
                latitude REAL,
                longitude REAL,
                created_at TEXT
              )
            ''');
          } catch (_) {}
          try {
            await db
                .execute("ALTER TABLE diagnoses ADD COLUMN crop_id INTEGER");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE diagnoses ADD COLUMN latitude REAL");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE diagnoses ADD COLUMN longitude REAL");
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute(
                "ALTER TABLE diagnoses ADD COLUMN server_image_path TEXT");
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute(
                "ALTER TABLE diagnoses ADD COLUMN tipo TEXT DEFAULT 'enfermedad'");
          } catch (_) {}
        }
      },
    );

    return _db!;
  }

  // ===============================================================
  // USERS
  // ===============================================================

  static String _hashPassword(String password) {
    // simple SHA256 hash for local storage; the server uses bcrypt
    return sha256.convert(utf8.encode(password)).toString();
  }

  static Future<int> saveUser(
    String name,
    String email,
    String password, {
    int synced = 0,
    int? serverId,
  }) async {
    final db = await database;

    return await db.insert('users', {
      'name': name,
      'email': email,
      'password': _hashPassword(password),
      'synced': synced,
      'server_id': serverId,
    });
  }

  static Future<void> upsertUserByEmail({
    required String name,
    required String email,
    required String password,
    required int serverId,
    int synced = 1,
  }) async {
    final db = await database;

    final updated = await db.update(
      'users',
      {
        'name': name,
        'password': password,
        'server_id': serverId,
        'synced': synced,
      },
      where: 'email = ?',
      whereArgs: [email],
    );

    if (updated == 0) {
      await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'synced': synced,
        'server_id': serverId,
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedUsers() async {
    final db = await database;
    return await db.query('users', where: 'synced = 0');
  }

  static Future<void> markUserAsSynced(int localId, int serverId) async {
    final db = await database;

    await db.update(
      'users',
      {
        'synced': 1,
        'server_id': serverId,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<Map<String, dynamic>?> loginOffline(
      String email, String password) async {
    final db = await database;

    final hashed = _hashPassword(password);
    final rows = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashed],
    );

    return rows.isNotEmpty ? rows.first : null;
  }

  // ===============================================================
  // DIAGNOSES
  // ===============================================================

  static Future<void> saveDiagnosis({
    required int userId,
    int? cropId,
    required String imagePath,
    required String disease,
    required String recommendation,
    required double confidence,
    required bool isCornLeaf,
    String tipo = 'enfermedad',
    double latitude = 0.0,
    double longitude = 0.0,
    required String createdAt,
    int uploaded = 0,
  }) async {
    final db = await database;

    await db.insert('diagnoses', {
      'user_id': userId,
      'crop_id': cropId,
      'image_path': imagePath,
      'disease': disease,
      'recommendation': recommendation,
      'confidence': confidence,
      'is_corn_leaf': isCornLeaf ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'tipo': tipo,
      'created_at': createdAt,
      'uploaded': uploaded,
    });
  }

  // 🔥 NUEVA FUNCIÓN: Actualiza el diagnóstico local con la respuesta de la IA
  static Future<void> updateDiagnosticAfterSync({
    required int localId,
    required String disease,
    required String recommendation,
    required double confidence,
    required int isCornLeaf,
    required String serverImagePath,
  }) async {
    final db = await database;
    await db.update(
      'diagnoses',
      {
        'disease': disease,
        'recommendation': recommendation,
        'confidence': confidence,
        'is_corn_leaf': isCornLeaf,
        'image_path':
            serverImagePath, // Cambiamos ruta local por URL del servidor
        'uploaded': 1,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<void> replaceDiagnosesForUser(
    int userId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('diagnoses', where: 'user_id = ?', whereArgs: [userId]);

      for (final item in items) {
        await txn.insert('diagnoses', {
          'user_id': userId,
          'crop_id': item['crop_id'],
          'image_path': item['image_path'] ?? '',
          'disease': item['disease'] ?? item['disease_name'] ?? '',
          'recommendation': item['recommendation'] ?? item['advice'] ?? '',
          'confidence':
              (item['confidence'] ?? item['probability'] ?? 0).toDouble(),
          'is_corn_leaf':
              (item['is_corn_leaf'] == true || item['is_corn_leaf'] == 1)
                  ? 1
                  : 0,
          'latitude': item['latitude'] ?? item['lat'] ?? 0.0,
          'longitude': item['longitude'] ?? item['lng'] ?? 0.0,
          'tipo': item['tipo'] ?? item['type'] ?? 'enfermedad',
          'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
          'uploaded': 1,
        });
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getAllDiagnoses({
    int? userId,
  }) async {
    final db = await database;

    if (userId != null) {
      return await db.rawQuery('''
        SELECT d.*, u.name AS user_name
        FROM diagnoses d
        JOIN users u ON d.user_id = u.id
        WHERE d.user_id = ?
        ORDER BY d.created_at DESC
      ''', [userId]);
    }

    return await db.rawQuery('''
      SELECT d.*, u.name AS user_name
      FROM diagnoses d
      JOIN users u ON d.user_id = u.id
      ORDER BY d.created_at DESC
    ''');
  }

  static Future<int> countDiagnosesByUser(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM diagnoses WHERE user_id = ?',
      [userId],
    );

    if (result.isEmpty) return 0;
    final raw = result.first['total'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getDiagnosesByCrop(
      int cropId) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT * FROM diagnoses
      WHERE crop_id = ?
      ORDER BY created_at DESC
    ''', [cropId]);
  }

  static Future<List<Map<String, dynamic>>> getPendingDiagnoses() async {
    final db = await database;

    return await db.query(
      'diagnoses',
      where: 'uploaded = 0',
    );
  }

  static Future<void> deletePendingDiagnosesWithoutServerUser() async {
    final db = await database;
    await db.delete(
      'diagnoses',
      where:
          'uploaded = 0 AND user_id IN (SELECT id FROM users WHERE server_id IS NULL)',
    );
  }

  static Future<int?> getServerIdForLocalUser(int localId) async {
    final db = await database;
    final rows = await db.query(
      'users',
      columns: ['server_id'],
      where: 'id = ?',
      whereArgs: [localId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final serverId = rows.first['server_id'] as int?;
    return serverId;
  }

  static Future<void> markDiagnosisAsUploaded(
    int id, {
    Map<String, dynamic>? serverData,
  }) async {
    final db = await database;

    final update = <String, Object?>{'uploaded': 1};

    if (serverData != null) {
      final disease = serverData["disease_name"] ?? serverData["disease"];
      final recommendation =
          serverData["recommendation"] ?? serverData["advice"];
      final confidence = serverData["confidence"] ?? serverData["probability"];
      final isCorn = serverData["is_corn_leaf"] ?? serverData["is_corn"];

      if (disease != null) update["disease"] = disease.toString();
      if (recommendation != null) {
        update["recommendation"] = recommendation.toString();
      }
      if (confidence != null) {
        final num? confNum = confidence is num
            ? confidence
            : num.tryParse(confidence.toString());
        if (confNum != null) update["confidence"] = confNum.toDouble();
      }
      if (isCorn != null) {
        update["is_corn_leaf"] = (isCorn == 1 || isCorn == true) ? 1 : 0;
      }
    }

    await db.update(
      'diagnoses',
      update,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deletePendingDiagnosisById(int id) async {
    final db = await database;
    return await db.delete(
      'diagnoses',
      where: 'id = ? AND uploaded = 0',
      whereArgs: [id],
    );
  }

  static Future<void> saveCropLocal(Map<String, dynamic> crop) async {
    final db = await database;

    double _toDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v.trim());
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    try {
      await db.insert(
        'crops',
        {
          'id': crop['id'],
          'user_id': crop['user_id'] ?? crop['userId'],
          'name': crop['name'] ?? '',
          'latitude': _toDouble(crop['latitude'] ?? crop['lat']),
          'longitude': _toDouble(crop['longitude'] ?? crop['lng']),
          'created_at': crop['created_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Evita romper el flujo; loguea para depurar
      print("❌ No se pudo guardar crop local: $e | data: $crop");
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerParcelasLocales() async {
    final db = await database;
    // Asegura que la tabla exista aunque la migración no se haya aplicado
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crops (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        name TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT
      )
    ''');
    return await db.query('crops', orderBy: 'created_at DESC');
  }

  static Future<List<Map<String, dynamic>>>
      obtenerDiagnosticosLocalesPorParcela(int cropId) async {
    final db = await database;
    return await db.query(
      'diagnoses',
      where: 'crop_id = ?',
      whereArgs: [cropId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<List<Map<String, dynamic>>>
      obtenerDiagnosticosLocalesPendientesPorParcela(int cropId) async {
    final db = await database;
    return await db.query(
      'diagnoses',
      where: 'crop_id = ? AND uploaded = 0',
      whereArgs: [cropId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<void> actualizarDiagnosticoSincronizado(
    int localId,
    Map<String, dynamic> apiResult,
  ) async {
    final db = await database;

    // Mantener ruta local si existe (para offline) y guardar la remota en server_image_path
    String? localPath;
    try {
      final current = await db.query('diagnoses',
          where: 'id = ?', whereArgs: [localId], limit: 1);
      if (current.isNotEmpty) {
        final p = current.first;
        final path = p['image_path']?.toString();
        if (path != null && path.isNotEmpty) localPath = path;
      }
    } catch (_) {}

    double _toDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v.trim());
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    final disease =
        (apiResult['disease_name'] ?? apiResult['disease'] ?? '').toString();
    final recommendation =
        (apiResult['recommendation'] ?? apiResult['advice'] ?? '').toString();
    final confidence =
        _toDouble(apiResult['confidence'] ?? apiResult['probability'] ?? 0.0);
    final isCorn = (apiResult['is_corn_leaf'] ?? apiResult['is_corn'] ?? 1);
    final serverImagePath =
        (apiResult['image_path'] ?? apiResult['imageUrl'] ?? '').toString();

    await db.update(
      'diagnoses',
      {
        'disease': disease,
        'recommendation': recommendation,
        'confidence': confidence,
        'is_corn_leaf': (isCorn == true || isCorn == 1) ? 1 : 0,
        if (localPath != null) 'image_path': localPath,
        if (serverImagePath.isNotEmpty) 'server_image_path': serverImagePath,
        'uploaded': 1,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // 1. Para obtener los diagnósticos que se quedaron atrapados en el cel
  static Future<List<Map<String, dynamic>>>
      obtenerDiagnosticosPendientes() async {
    final db = await database;
    // Buscamos los que tengan confidence 0.0 (así los marcamos cuando no hay internet)
    return await db
        .query('diagnoses', where: 'confidence = ?', whereArgs: [0.0]);
  }

  // 2. Para borrar el registro local una vez que la API ya lo recibió
  static Future<int> eliminarPendiente(int id) async {
    final db = await database;
    return await db.delete('diagnoses', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAllLocalData() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('diagnoses');
    batch.delete('crops');
    batch.delete('users');
    await batch.commit(noResult: true);
  }
}
