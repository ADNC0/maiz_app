import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:maiz_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db_service.dart';
import 'navigation_service.dart';
import 'session_service.dart';

class ApiService {
  static bool _isHandlingUnauthorized = false;
  static const String _tokenKey = 'usuario_token';

  // ===============================================================
  // CONFIGURACIÓN DE CONEXIÓNnnnnnnnnnnnnnn
  // ===============================================================
  static Future<String> get baseUrl async {
    final appUrl = dotenv.env['APP_URL']?.trim();
    if (appUrl != null && appUrl.isNotEmpty) return appUrl;

    final apiBaseUrl = dotenv.env['API_BASE_URL']?.trim();
    if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) return apiBaseUrl;

    // return 'http://192.168.0.7:8000';
    return 'http://192.168.137.1:8000';
  }

  // ===============================================================
  // AYUDAS DE TOKEN / ALMACENAMIENTO
  // ===============================================================

  // Instancia de almacenamiento seguro usada para JWT
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static Future<void> setToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(
        key: 'jwt', value: token); // compatibilidad heredada
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    final secureLegacy = await _secureStorage.read(key: 'jwt');
    if (secureLegacy != null && secureLegacy.isNotEmpty) return secureLegacy;

    final prefs = await SharedPreferences.getInstance();
    final prefsToken = prefs.getString(_tokenKey) ?? prefs.getString('jwt');
    if (prefsToken != null && prefsToken.isNotEmpty) return prefsToken;

    return null;
  }

  static Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: 'jwt');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('jwt');
  }

  static Future<void> _clearSessionOn401() async {
    // Limpieza inmediata solicitada para evitar mezcla de usuarios.
    await clearToken();
    await SessionService.clear();
  }

  static String? _extractToken(Map<String, dynamic> data) {
    final dynamic nested = data['data'];
    final dynamic candidate = data['token'] ??
        data['jwt'] ??
        data['access_token'] ??
        data['accessToken'] ??
        (nested is Map ? nested['token'] : null) ??
        (nested is Map ? nested['jwt'] : null) ??
        (nested is Map ? nested['access_token'] : null) ??
        (nested is Map ? nested['accessToken'] : null);

    if (candidate == null) return null;
    final token = candidate.toString().trim();
    return token.isEmpty ? null : token;
  }

  static Future<void> logout() async {
    await clearToken();
    await SessionService.clear();
    await DBService.clearAllLocalData();
  }

  static Future<Map<String, String>> _defaultHeaders() async {
    final headers = <String, String>{};
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<void> _handleUnauthorized() async {
    // Evita disparar multiples redirecciones cuando varias peticiones fallan juntas.
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;
    try {
      await logout();

      final navigator = appNavigatorKey.currentState;
      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = appNavigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Sesion expirada. Por favor, ingresa de nuevo.'),
            ),
          );
        }
      });
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  // ===============================================================
  // VERIFICACION DE SALUD DEL SERVIDOR
  // ===============================================================
  static Future<bool> checkBackendHealth() async {
    try {
      final url = Uri.parse("${await baseUrl}/health");
      final headers = await _defaultHeaders();
      final res = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return false;
      }
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ===============================================================
  // AUTENTICACIÓN (INICIO DE SESIÓN / REGISTRO)
  // ===============================================================
  static Future<Map<String, dynamic>?> registerUser(
      String name, String email, String password) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/auth/register");
      final headers = <String, String>{'Content-Type': 'application/json'};
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final token = _extractToken(data);
          if (token != null) {
            await setToken(token);
          }
        }
        return data;
      }
      return null;
    } catch (e) {
      print("❌ registerUser error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      await clearToken();
      await SessionService.clear();

      final String rootUrl = await baseUrl;
      print(" Intentando login en: $rootUrl/api/auth/login");
      final url = Uri.parse("$rootUrl/api/auth/login");
      final headers = <String, String>{'Content-Type': 'application/json'};
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"email": email, "password": password}),
      );
      print(" Status Code: ${res.statusCode}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final token = _extractToken(data);
          if (token != null) {
            await setToken(token);
          }
        }
        return data;
      }
      // Propaga 401/403 para que quien llama pueda actuar.
      if (res.statusCode == 401 || res.statusCode == 403) {
        if (res.statusCode == 401) {
          await _clearSessionOn401();
        }
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return {
            ...decoded,
            'statusCode': res.statusCode,
          };
        }
        return {
          'success': false,
          'statusCode': res.statusCode,
        };
      }
      return null;
    } catch (e) {
      print("🛑 Error CRÍTICO en ApiService login: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> verifyAccount(
      String email, String code) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/auth/verify");
      final headers = <String, String>{'Content-Type': 'application/json'};
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (res.statusCode == 200 ||
          res.statusCode == 400 ||
          res.statusCode == 401) {
        if (res.statusCode == 401) {
          await _clearSessionOn401();
        }
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final token = _extractToken(data);
          if (token != null) {
            await setToken(token);
          }
          return {
            ...data,
            'statusCode': res.statusCode,
          };
        }
        return {
          'success': false,
          'statusCode': res.statusCode,
        };
      }

      return null;
    } catch (e) {
      print("❌ verifyAccount error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> requestOtp(
      String name, String email, String password) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/auth/request-otp");
      final headers = <String, String>{'Content-Type': 'application/json'};
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (res.statusCode == 200 ||
          res.statusCode == 400 ||
          res.statusCode == 401 ||
          res.statusCode == 403 ||
          res.statusCode == 409) {
        if (res.statusCode == 401) {
          await _clearSessionOn401();
        }
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          return {
            ...data,
            'statusCode': res.statusCode,
          };
        }
        return {
          'success': false,
          'statusCode': res.statusCode,
        };
      }

      return null;
    } catch (e) {
      print("❌ requestOtp error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> registerWithOtp({
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/auth/register");
      final headers = <String, String>{'Content-Type': 'application/json'};
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'code': code,
        }),
      );

      if (res.statusCode == 200 ||
          res.statusCode == 400 ||
          res.statusCode == 401 ||
          res.statusCode == 403) {
        if (res.statusCode == 401) {
          await _clearSessionOn401();
        }
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final token = _extractToken(data);
          if (token != null) {
            await setToken(token);
          }
          return {
            ...data,
            'statusCode': res.statusCode,
          };
        }
        return {
          'success': false,
          'statusCode': res.statusCode,
        };
      }

      return null;
    } catch (e) {
      print("❌ registerWithOtp error: $e");
      return null;
    }
  }

  // ===============================================================
  // UTILIDADES
  // ===============================================================
  /// Devuelve true si el correo ya está registrado en el servidor.
  /// El servidor debe exponer una ruta `/api/auth/check-email` que
  /// responda `{ "taken": true }` o `{ "taken": false }`.
  static Future<bool> isEmailTaken(String email) async {
    try {
      final url = Uri.parse(
          "${await baseUrl}/api/auth/check-email?email=${Uri.encodeComponent(email)}");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['taken'] == true;
      }
    } catch (_) {}
    return false;
  }

  // ===============================================================
  // GESTIÓN DE USUARIOS (ADMINISTRACIÓN)
  // ===============================================================
  static Future<List<Map<String, dynamic>>?> fetchUsers() async {
    try {
      final url = Uri.parse("${await baseUrl}/api/admin/users");
      final headers = await _defaultHeaders();
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }
      if (res.statusCode == 403) {
        print(" Admin users request denied (403): ${res.body}");
        return null;
      }
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }

        if (decoded is Map<String, dynamic>) {
          final dynamic usersData =
              decoded['users'] ?? decoded['data'] ?? decoded['usuarios'];
          if (usersData is List) {
            return usersData.cast<Map<String, dynamic>>();
          }
        }

        return <Map<String, dynamic>>[];
      }

      print("⚠️ Admin users request failed with status ${res.statusCode}");
      print("⚠️ Response body: ${res.body}");
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateUserRole(int id, String role) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/admin/users/$id/role");
      final headers = await _defaultHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.put(
        url,
        headers: headers,
        body: jsonEncode({"role": role}),
      );
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return false;
      }
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteUser(int id) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/admin/users/$id");
      final headers = await _defaultHeaders();
      final res = await http.delete(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return false;
      }
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ===============================================================
  // DIAGNÓSTICO (UNIFICADO)
  // ===============================================================
  /// La API ya extrae el id del usuario del token JWT, por lo que
  /// no es necesario pasar `userId` desde el cliente.
  static Future<Map<String, dynamic>?> _sendDiagnosisRequest(
    File image, {
    required String tipo,
    int? cropId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/v1/diagnose");
      final req = http.MultipartRequest("POST", url);
      req.headers.addAll(await _defaultHeaders());
      req.fields["tipo"] = tipo;
      if (cropId != null) req.fields["crop_id"] = cropId.toString();
      if (latitude != null) req.fields["latitude"] = latitude.toString();
      if (longitude != null) req.fields["longitude"] = longitude.toString();
      req.files.add(await http.MultipartFile.fromPath("image", image.path));

      final res = await req.send();
      final body = await res.stream.bytesToString();

      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }
      if (res.statusCode != 200) {
        return jsonDecode(body) as Map<String, dynamic>?;
      }
      return jsonDecode(body) as Map<String, dynamic>?;
    } catch (e) {
      print("❌ _sendDiagnosisRequest error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadImage(
    File image, {
    String tipo = 'enfermedad',
  }) async {
    final response = await _sendDiagnosisRequest(
      image,
      tipo: tipo,
    );
    if (response == null) return null;
    return response["diagnosis"] ?? response;
  }

  static Future<Map<String, dynamic>?> uploadImageToCrop(
    File image, {
    required int cropId,
    required double latitude,
    required double longitude,
    String tipo = 'enfermedad',
  }) async {
    final response = await _sendDiagnosisRequest(
      image,
      tipo: tipo,
      cropId: cropId,
      latitude: latitude,
      longitude: longitude,
    );
    if (response == null) return null;
    return response["diagnosis"] ?? response;
  }

  static Future<Map<String, dynamic>?> uploadImagePlaga(
    File image, {
    required int cropId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _sendDiagnosisRequest(
      image,
      tipo: 'plaga',
      cropId: cropId,
      latitude: latitude,
      longitude: longitude,
    );
    if (response == null) return null;
    return response["diagnosis"] ?? response;
  }

  // ===============================================================
  // HISTORIAL DE DIAGNÓSTICOS
  // ===============================================================
  /// Si se provee `userId`, se lo añade a la ruta; de lo contrario el
  /// servidor tomará el usuario del JWT (uso típico desde aplicaciones
  /// de agricultor). Esto deja la llamada compatible con administrador.
  static Future<List<Map<String, dynamic>>?> fetchDiagnoses(
      {int? userId}) async {
    try {
      final path = userId != null ? '/diagnoses/$userId' : '/diagnoses';
      final url = Uri.parse("${await baseUrl}$path");
      final headers = await _defaultHeaders();
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print("❌ Error in fetchDiagnoses: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> fetchDiagnosesByCrop(
      int cropId) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/crops/$cropId/diagnoses");
      final headers = await _defaultHeaders();
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        if (decoded is Map<String, dynamic>) {
          final dynamic listData = decoded["diagnoses"] ??
              decoded["data"] ??
              decoded["items"] ??
              decoded["results"];

          if (listData is List) {
            return listData
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }

          if (decoded["success"] == true && decoded["diagnosis"] is Map) {
            return [Map<String, dynamic>.from(decoded["diagnosis"] as Map)];
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ===============================================================
  // PARCELAS (CULTIVOS)
  // ===============================================================
  static Future<List<Map<String, dynamic>>?> fetchCrops([int? userId]) async {
    try {
      final String path =
          userId != null ? '/api/crops/user/$userId' : '/api/crops';
      final url = Uri.parse("${await baseUrl}$path");
      // Le bajamos el tiempo de espera para que no se quede colgado
      final headers = await _defaultHeaders();
      final res = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data["crops"] is List) {
          return (data["crops"] as List).cast<Map<String, dynamic>>();
        }
        if (data is List) return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print("❌ Error en fetchCrops: Connection failed (Offline)");
      return null; // Devolvemos null para que la pantalla sepa que debe buscar en la DB local
    }
  }

  static Future<Map<String, dynamic>> createParcel({
    required String name,
    required double latitude,
    required double longitude,
    int? userId, // opcional: solo cuando un administrador cree parcela
  }) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/crops");
      final Map<String, dynamic> payload = {
        "name": name,
        "variety": name,
        "latitude": latitude,
        "lng": longitude,
      };
      final body = jsonEncode(payload);
      final headers = await _defaultHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        url,
        headers: headers,
        body: body,
      );
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return {
          "ok": false,
          "message": "Sesion expirada. Por favor, ingresa de nuevo.",
        };
      }
      final json = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      return {
        "ok": res.statusCode == 200 || res.statusCode == 201,
        "message": json?["message"] ?? "Operación exitosa.",
        "raw": json,
      };
    } catch (e) {
      return {"ok": false, "message": e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>?> fetchParcels(int userId) async {
    final crops = await fetchCrops(userId);
    if (crops == null) return null;
    return crops.map((c) {
      return {
        ...c,
        "name": c["variety"] ?? c["name"],
        "latitude": c["lat"] ?? c["latitude"],
        "longitude": c["lng"] ?? c["longitude"],
      };
    }).toList();
  }

  static Future<bool> deleteCrop(int cropId) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/crops/$cropId");
      final headers = await _defaultHeaders();
      final res = await http.delete(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return false;
      }
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ===============================================================
  // RECUPERACIÓN DE CONTRASEÑA
  // ===============================================================
  static Future<Map<String, dynamic>> sendPasswordRecovery(String email) async {
    try {
      final resolvedBaseUrl = await baseUrl;
      final url = Uri.parse("$resolvedBaseUrl/api/forgot-password");
      print("📨 Enviando recuperación de contraseña a: $url");
      final headers = <String, String>{'Content-Type': 'application/json'};
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"email": email}),
      );
      print("📨 Respuesta recovery: ${res.statusCode}");
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 404) return data;
      return {
        "success": false,
        "message": "Error del servidor (${res.statusCode})"
      };
    } catch (e) {
      print("❌ sendPasswordRecovery error: $e");
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  // ===============================================================
  // ACTUALIZAR ESTADO Y PERFIL
  // ===============================================================
  static Future<Map<String, dynamic>> changeUserStatus(int userId) async {
    try {
      final url =
          Uri.parse("${await baseUrl}/api/usuarios/cambiar_estado_usuario");
      final headers = await _defaultHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"usuario_id": userId}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 ||
          res.statusCode == 400 ||
          res.statusCode == 404) return data;
      return {
        "success": false,
        "message": "Error del servidor (${res.statusCode})"
      };
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

// esto sirve
  static Future<Map<String, dynamic>?> fetchAdminStatsOverview() async {
    try {
      final url = Uri.parse("${await baseUrl}/api/admin/stats/overview");
      final headers = await _defaultHeaders();
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }
      if (res.statusCode != 200) {
        print('⚠️ Admin stats overview ${res.statusCode}: ${res.body}');
        return null;
      }
      return jsonDecode(res.body);
    } catch (e) {
      print('❌ fetchAdminStatsOverview error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchAdminStatsDiseases() async {
    try {
      final url = Uri.parse("${await baseUrl}/api/admin/stats/diseases");
      final headers = await _defaultHeaders();
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }
      if (res.statusCode != 200) {
        print('⚠️ Admin stats diseases ${res.statusCode}: ${res.body}');
        return null;
      }
      return jsonDecode(res.body);
    } catch (e) {
      print('❌ fetchAdminStatsDiseases error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchAdminStatsDataset() async {
    try {
      final url = Uri.parse("${await baseUrl}/api/admin/stats/dataset");
      final headers = await _defaultHeaders();
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }
      if (res.statusCode != 200) {
        print('⚠️ Admin stats dataset ${res.statusCode}: ${res.body}');
        return null;
      }
      return jsonDecode(res.body);
    } catch (e) {
      print('❌ fetchAdminStatsDataset error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? nombre,
    String? email,
    String? clave,
  }) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/actualizar-datos");
      final Map<String, dynamic> body = {
        "id": userId,
        "nombre": nombre,
        "email": email,
        "clave": clave,
      };
      final headers = await _defaultHeaders();
      headers['Content-Type'] = 'application/json';
      final res = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 ||
          res.statusCode == 409 ||
          res.statusCode == 404) return data;
      return {
        "success": false,
        "message": "Error del servidor (${res.statusCode})"
      };
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  static Future<Map<String, dynamic>?> httpGet(Uri url) async {
    try {
      final headers = await _defaultHeaders();
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (_) {
      return null;
    }
  }

  // ===============================================================
  // RESTABLECIMIENTO DE CONTRASEÑA
  // ===============================================================

  /// Envía el token obtenido por correo y la nueva contraseña.
  static Future<Map<String, dynamic>?> resetPassword(
      String email, String token, String newPassword) async {
    try {
      final resolvedBaseUrl = await baseUrl;
      final url = Uri.parse("$resolvedBaseUrl/api/auth/reset-password");
      final headers = <String, String>{'Content-Type': 'application/json'};
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode(
          {'email': email, 'token': token, 'newPassword': newPassword},
        ),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) {
      print('❌ resetPassword error: $e');
      return null;
    }
  }

  // ===============================================================
  // ARREGLO SIN CONEXIÓN: SINCRONIZACIÓN CORREGIDA
  // ===============================================================
  static Future<Map<String, dynamic>?> uploadImageToCropFromOffline(
    Map<String, dynamic> diag,
  ) async {
    try {
      final url = Uri.parse("${await baseUrl}/api/v1/diagnose");

      final String? imagePath = diag["image_path"];

      print("🔄 Sincronizando diagnóstico offline...");

      if (imagePath == null || !File(imagePath).existsSync()) {
        print("❌ ERROR: La imagen no existe en la ruta: $imagePath");
        return null;
      }

      final req = http.MultipartRequest("POST", url);
      // Agrega cabecera de autorizacion para que el servidor valide la peticion.
      req.headers.addAll(await _defaultHeaders());

      if (diag["crop_id"] != null)
        req.fields["crop_id"] = diag["crop_id"].toString();
      if (diag["latitude"] != null)
        req.fields["latitude"] = diag["latitude"].toString();
      if (diag["longitude"] != null)
        req.fields["longitude"] = diag["longitude"].toString();
      req.fields["tipo"] = diag["tipo"]?.toString() ?? 'enfermedad';

      req.files.add(await http.MultipartFile.fromPath("image", imagePath));

      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode == 401) {
        await _handleUnauthorized();
        return null;
      }

      if (res.statusCode == 200) {
        final parsed = jsonDecode(body);
        return parsed;
      } else {
        print("❌ Error en servidor sync (Status ${res.statusCode}): $body");
        return null;
      }
    } catch (e) {
      print("🛑 Error en sincronización offline: $e");
      return null;
    }
  }
}
