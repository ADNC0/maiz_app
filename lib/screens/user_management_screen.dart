import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/session_service.dart';
// Importamos la pantalla de detalles (la que muestra parcelas de UN usuario específico)
import 'package:maiz_app/screens/admin_user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Color verde corporativo
  static const Color primaryGreen = Color(0xFF2E7D32);

  List<Map<String, dynamic>> users = [];
  bool loading = true;
  bool unauthorizedRole = false;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  // Carga la lista de usuarios (GET)
  Future<void> loadUsers() async {
    final role = (SessionService.userRole ?? '').trim().toLowerCase();
    if (role != 'administrador') {
      if (mounted) {
        setState(() {
          users = [];
          loading = false;
          unauthorizedRole = true;
        });
      }
      return;
    }

    final data = await ApiService.fetchUsers();
    if (mounted) {
      setState(() {
        users = data ?? [];
        loading = false;
        unauthorizedRole = false;
      });
    }
  }

  // Cambiar Estado (Activo/Inactivo)
  Future<void> _toggleUserStatus(int id, String userName) async {
    final response = await ApiService.changeUserStatus(id);

    if (!mounted) return;

    if (response['success'] == true) {
      final msg = response['message'] ?? "Estado actualizado correctamente";
      final bool nuevoEstado = response['nuevo_estado'] ?? false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$msg (Ahora: ${nuevoEstado ? 'Activo' : 'Inactivo'})"),
          backgroundColor: Colors.green[700],
        ),
      );
      loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? "Error al cambiar estado"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryGreen));
    }

    if (unauthorizedRole) {
      return const Center(
        child: Text(
          "Acceso restringido: solo Administrador.",
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (users.isEmpty) {
      return const Center(child: Text("No hay usuarios registrados."));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        // ===== ENCABEZADO INTERNO =====
        const Text(
          "Gestión de Usuarios",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20), // Verde oscuro
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Administra el acceso y las parcelas de los usuarios",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),

        // ===== LISTA DE USUARIOS =====
        ...users.map((user) {
          // Parseo seguro del ID
          final int userId = (user['id'] ?? 0) is int
              ? user['id']
              : int.tryParse("${user['id']}") ?? 0;

          final String name = "${user['name'] ?? 'Sin Nombre'}";
          final String email = "${user['email'] ?? ''}";

          final dynamic rawStatus = user['status'];
          final bool isActive = rawStatus == true || rawStatus == 1;

          // Verificamos si soy yo mismo para bloquear acciones destructivas
          final bool isMe = (SessionService.userId != null &&
              userId == SessionService.userId);

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Ícono de Avatar
                  CircleAvatar(
                    backgroundColor: primaryGreen.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          color: primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Información Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Etiqueta de estado visual
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isActive
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3))),
                          child: Text(
                            isActive ? "Activo" : "Inactivo",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Colors.green[800]
                                  : Colors.grey[600],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  // Columna de Acciones
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Botón Ver Parcelas
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined,
                            color: primaryGreen),
                        tooltip: "Ver parcelas del usuario",
                        visualDensity: VisualDensity.compact,
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
                      ),

                      // 2. Switch de Estado (Habilitar/Deshabilitar)
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isActive,
                          activeColor: primaryGreen,
                          onChanged: isMe
                              ? null // No puedo desactivarme a mi mismo
                              : (_) => _toggleUserStatus(userId, name),
                        ),
                      ),
                      // El botón de eliminar ha sido removido según solicitud.
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
