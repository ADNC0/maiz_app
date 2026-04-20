import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // Variables estáticas para acceder desde cualquier lado
  static int? userId;
  static String? userName;
  static String? userEmail;
  static String? userRole;

  static const _prefsUserIdKey = 'usuario_id';
  static const _prefsUserNameKey = 'usuario_nombre';
  static const _prefsUserEmailKey = 'usuario_email';
  static const _prefsUserRoleKey = 'usuario_rol';

  // legacy keys kept for backward compatibility when reading old sessions
  static const _legacyPrefsUserIdKey = 'session_user_id';
  static const _legacyPrefsUserNameKey = 'session_user_name';
  static const _legacyPrefsUserEmailKey = 'session_user_email';
  static const _legacyPrefsUserRoleKey = 'session_user_role';

  // Guarda datos en RAM (rol opcional)
  static void setUser({
    required int id,
    required String name,
    required String email,
    String? role,
  }) {
    userId = id;
    userName = name;
    userEmail = email;
    userRole = role;
  }

  static void clearMemory() {
    userId = null;
    userName = null;
    userEmail = null;
    userRole = null;
  }

  // Persiste la sesión solo si el rol es Agricultor
  static Future<void> persistIfAgricultor() async {
    if (userId == null || userName == null || userEmail == null) return;
    if ((userRole ?? '').trim() != 'Agricultor') return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsUserIdKey, userId!);
    await prefs.setString(_prefsUserNameKey, userName!);
    await prefs.setString(_prefsUserEmailKey, userEmail!);
    await prefs.setString(_prefsUserRoleKey, userRole ?? 'Agricultor');
  }

  // Persiste la sesión actual para cualquier rol usando llaves usuario_*.
  static Future<void> persistCurrentSession() async {
    if (userId == null || userName == null || userEmail == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsUserIdKey, userId!);
    await prefs.setString(_prefsUserNameKey, userName!);
    await prefs.setString(_prefsUserEmailKey, userEmail!);
    await prefs.setString(_prefsUserRoleKey, (userRole ?? '').trim());
  }

  // Intenta cargar una sesión persistida (solo Agricultor)
  static Future<bool> loadPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_prefsUserRoleKey) ??
        prefs.getString(_legacyPrefsUserRoleKey);
    if (role == null || role.trim() != 'Agricultor') return false;

    final id =
        prefs.getInt(_prefsUserIdKey) ?? prefs.getInt(_legacyPrefsUserIdKey);
    final name = prefs.getString(_prefsUserNameKey) ??
        prefs.getString(_legacyPrefsUserNameKey);
    final email = prefs.getString(_prefsUserEmailKey) ??
        prefs.getString(_legacyPrefsUserEmailKey);

    if (id == null || name == null || email == null) {
      await clear();
      return false;
    }

    setUser(id: id, name: name, email: email, role: role);
    return true;
  }

  // Verifica sesión vigente leyendo llaves nuevas (usuario_*) y legacy.
  static Future<bool> isLoggedIn() async {
    if (userId != null && (userRole ?? '').trim().isNotEmpty) return true;

    final prefs = await SharedPreferences.getInstance();
    final id =
        prefs.getInt(_prefsUserIdKey) ?? prefs.getInt(_legacyPrefsUserIdKey);
    final role = prefs.getString(_prefsUserRoleKey) ??
        prefs.getString(_legacyPrefsUserRoleKey);

    return id != null && role != null && role.trim().isNotEmpty;
  }

  // Limpia sesión en RAM y almacenamiento
  static Future<void> clear() async {
    clearMemory();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
