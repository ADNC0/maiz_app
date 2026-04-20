import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// IMPORTACIONES MOCK (Ajusta a tus rutas reales)
// ==========================================
import 'package:maiz_app/services/api_service.dart';
import 'package:maiz_app/services/db_service.dart';
import 'package:maiz_app/services/session_service.dart';
import 'package:maiz_app/services/sync_service.dart';
import 'package:maiz_app/screens/crop_diagnosis_screen.dart';
import 'package:maiz_app/screens/trash_parcels_screen.dart';

// =========================================================
//  CEREBRO AGRONÓMICO: EL COMPADRE EXPERTO
// =========================================================
class CornDiseaseLibrary {
  // Esta función es la que decide qué consejo darte
  static Map<String, dynamic> getDetailedDiagnosis(String rawDiseaseName) {
    // 1. Limpiamos el nombre que viene del sistema (minúsculas y sin tildes)
    String cleanName = _normalizeText(rawDiseaseName);

    // ---------------------------------------------------------
    //    BLOQUE 1: DIAGNÓSTICOS EXACTOS DE TU API
    //    (Basado en la imagen: no_maiz, roya, tizon, etc.)
    // ---------------------------------------------------------

    // CASO 1: NO ES MAÍZ
    if (cleanName.contains("no_maiz") ||
        cleanName.contains("no_crop") ||
        cleanName.contains("unknown") ||
        cleanName.contains("background")) {
      return _getNoEsMaizData();
    }

    // CASO 2: HOJA SANA (La prioridad positiva)
    if (cleanName == "hoja_sana" ||
        cleanName.contains("hoja_sana") ||
        cleanName.contains("healthy") ||
        cleanName.contains("saludable")) {
      return _getSanoData();
    }

    // CASO 3: ROYA
    if (cleanName.contains("roya") ||
        cleanName.contains("rust") ||
        cleanName.contains("puccinia")) {
      return _getRoyaData();
    }

    // CASO 4: TIZÓN
    if (cleanName.contains("tizon") ||
        cleanName.contains("blight") ||
        cleanName.contains("helminthosporium")) {
      return _getTizonData();
    }

    // CASO 5: MANCHA GRIS (Cercospora)
    // Tu API devuelve "mancha_gris", así que lo atrapamos aquí.
    if (cleanName.contains("mancha_gris") ||
        cleanName.contains("cercospora") ||
        cleanName.contains("grey_leaf_spot")) {
      return _getCercosporaData();
    }

    // ---------------------------------------------------------
    //    BLOQUE 2: OTROS DIAGNÓSTICOS (Por si la API crece)
    // ---------------------------------------------------------

    // MANCHA DE ASFALTO (Tar Spot)
    if (cleanName.contains("asfalto") || cleanName.contains("tar_spot")) {
      return _getManchaAsfaltoData();
    }

    // MOSAICO / VIRUS
    if (cleanName.contains("mosaico") ||
        cleanName.contains("virus") ||
        cleanName.contains("streak")) {
      return _getMosaicoData();
    }

    // CARBÓN (Smut)
    if (cleanName.contains("carbon") ||
        cleanName.contains("smut") ||
        cleanName.contains("ustilago")) {
      return _getCarbonData();
    }

    // DEFICIENCIA DE NITROGENO
    if (cleanName.contains("nitrogeno") || cleanName.contains("deficiencia")) {
      return _getDeficienciaNitrogenoData();
    }

    // ---------------------------------------------------------
    //    BLOQUE 3: CASO DESCONOCIDO (Fallback)
    // ---------------------------------------------------------
    return {
      "title": "ALGO RARO VEO AQUÍ ($rawDiseaseName)",
      "is_healthy": false,
      "severity": "Desconocida",
      "description":
          "El sistema detectó '$rawDiseaseName', pero no tengo una ficha técnica exacta para eso. Parece un hongo o problema no registrado.",
      "chemical":
          "Lo mejor es que lleves esta hoja al técnico de la agropecuaria. Si ves hongos, podrías aplicar un fungicida de amplio espectro.",
      "organic":
          "Arranca esa hoja fea con cuidado y quémala lejos del cultivo por si acaso.",
      "prevention":
          "Revisa si aparecen más manchas iguales en los próximos 3 días."
    };
  }

  static String _normalizeText(String input) {
    if (input.isEmpty) return "";
    String text = input.trim().toLowerCase();
    var withDia = 'áéíóúüñ';
    var withoutDia = 'aeiouun';
    for (int i = 0; i < withDia.length; i++) {
      text = text.replaceAll(withDia[i], withoutDia[i]);
    }
    // Reemplazamos guiones bajos por espacios para facilitar la búsqueda si es necesario,
    // aunque los 'contains' de arriba funcionan igual.
    // text = text.replaceAll('_', ' ');
    return text;
  }

  // --- BASE DE DATOS DE DATOS (TEXTOS) ---

  static Map<String, dynamic> _getRoyaData() {
    return {
      "title": "ROYA (Ese polvillo colorado)",
      "is_healthy": false,
      "severity": "ALTA",
      "description":
          "Fíjate bien: la hoja tiene unos granitos o bultitos color ladrillo o naranja. Haz la prueba del dedo: pásale el dedo por encima suavecito; si te deja el dedo manchado de un polvo color óxido, es Roya seguro.",
      "chemical":
          "Aquí toca usar un remedio bueno. Busca en la tienda algo que tenga Triazoles (como el Ciproconazol). Fumiga tempranito en la mañana o ya en la tarde cuando baje el sol.",
      "organic":
          "Si prefieres lo natural, prepara un Caldo Sulfocálcico. Es barato y funciona. También puedes hervir bastante Cola de Caballo, cuelas esa agua y fumigas con eso.",
      "prevention":
          "No le eches tanta Urea de golpe, porque la planta se pone muy tierna y aguada, y ahí es cuando más le entra este hongo."
    };
  }

  static Map<String, dynamic> _getTizonData() {
    return {
      "title": "TIZÓN (Quemadura de hoja)",
      "is_healthy": false,
      "severity": "MUY ALTA",
      "description":
          "Mira esas manchas largas y secas de color gris o pardo. Parecen quemaduras de cigarro o canoas alargadas. Empiezan en las hojas de abajo y van subiendo.",
      "chemical":
          "Para prevenir usa Mancozeb. Pero si ya ves mucha mancha, corre a buscar algo con Azoxistrobina mezclado con Triazol. Aplícalo rápido.",
      "organic":
          "Hay un hongo bueno que se llama Trichoderma, cómpralo y échalo al suelo y a la hoja. También quita las hojas secas de abajo para que corra el aire.",
      "prevention":
          "Para la próxima siembra, trata de no poner maíz en el mismo sitio donde hubo maíz enfermo, porque este hongo se queda escondido en el rastrojo viejo."
    };
  }

  static Map<String, dynamic> _getManchaAsfaltoData() {
    return {
      "title": "MANCHA DE ASFALTO",
      "is_healthy": false,
      "severity": "CRÍTICA (¡Actúa rápido!)",
      "description":
          "Pásale la mano a la hoja. Se sienten rasposos esos puntitos negros brillantes, parecen salpicaduras de brea o asfalto. Alrededor del punto negro se pone seco.",
      "chemical":
          "¡No te duermas! Esto mata rápido. Pide en la tienda Ciproconazol o Piraclostrobina. Ponle pegante o adherente a la mezcla.",
      "organic":
          "Está difícil curar esto solo con remedios caseros si ya está avanzado. Podrías probar con extracto de cítricos para frenarlo un poco, pero no te confíes.",
      "prevention":
          "Siembra las matas un poquito más separadas para que entre luz y aire. A este hongo le encanta la oscuridad y la humedad encerrada."
    };
  }

  static Map<String, dynamic> _getCercosporaData() {
    return {
      "title": "MANCHA GRIS",
      "is_healthy": false,
      "severity": "MEDIA",
      "description":
          "Son unas manchitas cuadraditas o rectangulares de color gris o café. Si te fijas bien, las manchas corren parejito con las venas de la hoja, no las cruzan.",
      "chemical":
          "Aplica fungicidas sistémicos cuando el maíz esté empezando a echar la espiga. Productos con Benzimidazoles funcionan bien.",
      "organic":
          "Prepara un Caldo Bordeles (eso lleva cobre y cal) al 1%. Mézclalo bien y cuélalo para que no se te tape la boquilla.",
      "prevention":
          "Si tuviste esto el año pasado, te toca meter arado para enterrar toda la basura vieja, porque ahí es donde vive este hongo."
    };
  }

  static Map<String, dynamic> _getMosaicoData() {
    return {
      "title": "MOSAICO (Virus o Rayado)",
      "is_healthy": false,
      "severity": "VARIABLE",
      "description":
          "La hoja se ve rayada, tiene partes verde clarito y otras verde oscuro, parece piel de tigre o una sandía. Además, la planta se queda chaparra.",
      "chemical":
          "No hay veneno que cure el virus. Lo que tienes que matar es al bicho que lo trae (el pulgón o la chicharrita). Usa insecticida como Imidacloprid.",
      "organic":
          "Prepara agua con Jabón Potásico y un poquito de Aceite de Neem para lavar los bichos de la hoja. Pon plásticos amarillos con pegante.",
      "prevention":
          "Mantén bien limpio el monte de los bordes de la parcela, ahí es donde se esconden los bichos que traen esta enfermedad."
    };
  }

  static Map<String, dynamic> _getCarbonData() {
    return {
      "title": "CARBÓN (Esas bolsas negras)",
      "is_healthy": false,
      "severity": "MEDIA",
      "description":
          "Le han salido unas bolsas o tumores blancos que parecen champiñones deformes. Cuando esas bolsas se secan, botan un polvo negro como carbón.",
      "chemical":
          "Ya no sirve fumigar la hoja. El remedio era tratar la semilla antes de sembrar. Para la próxima, compra semilla curada con Carboxin.",
      "organic":
          "¡Haz esto ya! Arranca esas bolsas con cuidado ANTES de que se revienten. Mételas en una funda plástica y sácalas lejos.",
      "prevention":
          "Ten cuidado cuando pases con el azadón o la cultivadora. Si hieres a la planta, por ahí se mete este hongo."
    };
  }

  static Map<String, dynamic> _getDeficienciaNitrogenoData() {
    return {
      "title": "LE FALTA COMIDA (Nitrógeno)",
      "is_healthy": false,
      "severity": "NUTRICIONAL",
      "description":
          "La planta tiene hambre. La hoja se está poniendo amarilla empezando desde la punta y bajando por el centro en forma de V.",
      "chemical":
          "Cómprate un saco de Urea (46-0-0). Tírale al suelo cerquita del tallo, pero asegúrate de que haya humedad.",
      "organic":
          "Si tienes gallinaza o abono de cuy bien podrido, échale un puñado al pie de cada planta. También puedes sembrar frijol en el medio.",
      "prevention": "Para la otra, haz un análisis de suelo antes de sembrar."
    };
  }

  static Map<String, dynamic> _getSanoData() {
    return {
      "title": "¡QUÉ CHULADA DE MAÍZ!",
      "is_healthy": true,
      "severity": "NINGUNA",
      "description":
          "¡Te felicito! La hoja está verdecita, limpia y fuerte. No tiene manchas, ni huecos, ni cosas raras.",
      "chemical":
          "No gastes plata en remedios ni venenos ahorita. Sigue abonando y regando como vas.",
      "organic":
          "Si quieres consentirla, échale algún bioestimulante de algas o aminoácidos para que cargue mejor la mazorca.",
      "prevention":
          "No te confíes. Sigue dándote una vuelta por la parcela cada semana."
    };
  }

  // --- DETECTOR: NO ES MAÍZ ---
  static Map<String, dynamic> _getNoEsMaizData() {
    return {
      "title": "NO ES MAÍZ",
      "is_healthy": false,
      "severity": "NO APLICA",
      "description":
          "La imagen no corresponde a una planta de maíz conocida, o no es una planta.",
      "chemical": "No aplica.",
      "organic": "No aplica.",
      "prevention":
          "Verifica que la foto esté enfocada y sea de una hoja de maíz."
    };
  }
}

// ==========================================
// WIDGET PRINCIPAL: LISTADO DE PARCELAS
// ==========================================
class UserParcelsScreen extends StatefulWidget {
  final int userId;

  const UserParcelsScreen({super.key, required this.userId});

  @override
  State<UserParcelsScreen> createState() => _UserParcelsScreenState();
}

class _UserParcelsScreenState extends State<UserParcelsScreen>
    with SingleTickerProviderStateMixin {
  // --- CONFIGURACIÓN DE COLORES Y ESTILOS ---
  static const Color primaryColor = Color(0xFF66BB6A); // Verde vibrante
  static const Color darkGreen = Color(0xFF2E7D32); // Verde oscuro
  static const Color bgColor = Color(0xFFF1F8E9); // Fondo suave
  static const Color errorColor = Color(0xFFE57373); // Rojo suave

  // --- VARIABLES DE ESTADO ---
  List<Map<String, dynamic>> parcels = [];
  final List<Map<String, dynamic>> _trashedParcels = [];
  final Set<int> _trashedParcelIds = <int>{};
  bool isLoading = true;
  bool _wasOnline = false;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectSub;

  String get _trashPrefsKey => 'trashed_parcel_ids_user_${widget.userId}';

  // Controlador para animaciones de la lista
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // Inicializamos el controlador de animación
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _connectivity.checkConnectivity().then((status) {
      _wasOnline = status != ConnectivityResult.none;
    });

    _connectSub = _connectivity.onConnectivityChanged.listen((status) {
      final isOnline = status != ConnectivityResult.none;
      if (isOnline && !_wasOnline) {
        _autoSyncData();
      }
      _wasOnline = isOnline;
    });

    _loadTrashedParcelIds();

    // Cargar datos iniciales
    _loadParcelsData();
  }

  Future<void> _loadTrashedParcelIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_trashPrefsKey) ?? const <String>[];
    final ids = raw.map(int.tryParse).whereType<int>().toSet();

    if (!mounted) return;
    setState(() {
      _trashedParcelIds
        ..clear()
        ..addAll(ids);
      _rebuildTrashedParcelsFromVisibleData();
    });
  }

  Future<void> _saveTrashedParcelIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _trashPrefsKey,
      _trashedParcelIds.map((id) => id.toString()).toList(),
    );
  }

  void _rebuildTrashedParcelsFromVisibleData() {
    _trashedParcels
      ..clear()
      ..addAll(
        parcels
            .where((p) => _trashedParcelIds.contains(p['id']))
            .map((p) => Map<String, dynamic>.from(p)),
      );
  }

  Future<void> _syncTrashStateWithLoadedParcels() async {
    final validParcelIds = parcels.map((p) => p['id']).whereType<int>().toSet();
    _trashedParcelIds.removeWhere((id) => !validParcelIds.contains(id));
    _rebuildTrashedParcelsFromVisibleData();
    await _saveTrashedParcelIds();
  }

  @override
  void dispose() {
    _connectSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. LÓGICA DE CARGA DE DATOS (API)
  // ==========================================
  Map<String, dynamic> _normalizeParcel(Map<String, dynamic> p) {
    int _toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value.trim()) ?? 0;
      }
      return 0;
    }

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

    return {
      ...p,
      'id': _toInt(p['id']),
      'latitude': _toDouble(p['latitude'] ?? p['lat']),
      'longitude': _toDouble(p['longitude'] ?? p['lng']),
      'name': p['name'] ?? p['variety'] ?? 'Sin Nombre',
    };
  }

  List<Map<String, dynamic>> get _visibleParcels {
    return parcels
        .where((parcel) => !_trashedParcelIds.contains(parcel['id']))
        .toList();
  }

  Future<void> _loadParcelsData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    // Intentar traer de la API
    try {
      final data = await ApiService.fetchParcels(widget.userId);
      if (data != null && data.isNotEmpty) {
        final normalized = data.map(_normalizeParcel).toList();
        parcels = normalized;
        await _syncTrashStateWithLoadedParcels();

        if (!mounted) return;
        setState(() {
          parcels = List<Map<String, dynamic>>.from(normalized);
          isLoading = false;
        });
        _animController.forward(
            from: 0); // dispara animaciones para que sean visibles
        print("API devolvió ${data.length} parcelas");
        // Guardar en local sin bloquear el flujo
        for (var p in normalized) {
          DBService.saveCropLocal(p)
              .catchError((e) => print("Error guardando local: $e"));
        }
        return;
      }
    } catch (e) {
      print("API Falló: $e");
    }

    // Si falló la API o regresó vacío, intentamos LOCAL
    try {
      final localData = await DBService.obtenerParcelasLocales();
      print("SQLite devolvió ${localData.length} parcelas");
      parcels = (localData ?? []).map(_normalizeParcel).toList();
      await _syncTrashStateWithLoadedParcels();

      if (!mounted) return;
      setState(() {
        parcels = List<Map<String, dynamic>>.from(parcels);
        isLoading = false;
      });
      _animController.forward(from: 0); // asegura que aparezcan
    } catch (e) {
      print("Error crítico: Ni API ni SQLite funcionaron: $e");
      setState(() {
        parcels = [];
        isLoading = false;
      });
    }
  }

  Future<void> _autoSyncData() async {
    await SyncService.syncOfflineData();

    if (mounted) {
      await _loadParcelsData();
      setState(() {});
    }
  }

  // ==========================================
  // 2. GESTIÓN DE GPS Y PERMISOS
  // ==========================================
  Future<Position?> _determinarPosicionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verificar si el servicio está activo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      _mostrarAlertaAmigable("GPS Desactivado",
          "Por favor, enciende la ubicación de tu teléfono para continuar.");
      return null;
    }

    // 2. Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return null;
        _mostrarAlertaAmigable("Permiso Denegado",
            "Necesitamos acceso a tu ubicación para registrar o diagnosticar la parcela.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      _mostrarAlertaAmigable("Permiso Bloqueado",
          "Los permisos de ubicación están bloqueados permanentemente. Habilítalos en Configuración.");
      return null;
    }

    // 3. Obtener posición
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint("Error GPS: $e");
      return null;
    }
  }

  // ==========================================
  // 3. CREACIÓN DE NUEVA PARCELA (MODAL)
  // ==========================================
  void _abrirModalCrearParcela() {
    final nombreController = TextEditingController();
    final ValueNotifier<Position?> localPosNotifier = ValueNotifier(null);
    final ValueNotifier<bool> localGpsLoading = ValueNotifier(false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 25, spreadRadius: 5)
            ]),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 15, bottom: 10),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.add_location_alt_rounded,
                            color: primaryColor, size: 30),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nueva Parcela",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen),
                            ),
                            Text(
                              "Registra tu zona de cultivo",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),
                  const Text("Nombre del Cultivo",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      hintText: "Ej: Maizales del Sur",
                      prefixIcon: const Icon(Icons.label_important_outline,
                          color: primaryColor),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              const BorderSide(color: primaryColor, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text("Ubicación Geográfica",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable: localGpsLoading,
                    builder: (context, loading, _) {
                      return InkWell(
                        onTap: loading
                            ? null
                            : () async {
                                localGpsLoading.value = true;
                                final pos = await _determinarPosicionActual();
                                localGpsLoading.value = false;
                                if (pos != null) {
                                  localPosNotifier.value = pos;
                                }
                              },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.grey[300]!, width: 2),
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                          ),
                          child: loading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: primaryColor))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.satellite_alt,
                                        color: primaryColor),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Obtener ubicación GPS",
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<Position?>(
                    valueListenable: localPosNotifier,
                    builder: (context, pos, _) {
                      if (pos == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.3))),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: primaryColor),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Ubicación capturada:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen)),
                                Text("Lat: ${pos.latitude.toStringAsFixed(5)}",
                                    style: const TextStyle(fontSize: 12)),
                                Text("Lng: ${pos.longitude.toStringAsFixed(5)}",
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: darkGreen.withOpacity(0.4),
                      ),
                      child: const Text("GUARDAR PARCELA",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      onPressed: () {
                        if (nombreController.text.trim().isEmpty ||
                            localPosNotifier.value == null) {
                          _mostrarAlertaAmigable("¡Faltan Datos!",
                              "Por favor escribe un nombre para la parcela y asegúrate de obtener la ubicación GPS antes de guardar.");
                          return;
                        }
                        Navigator.pop(context);
                        _guardarParcelaEnBackend(nombreController.text.trim(),
                            localPosNotifier.value!);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNCIÓN PRIVADA PARA GUARDAR ---
  Future<void> _guardarParcelaEnBackend(String nombre, Position pos) async {
    setState(() => isLoading = true);

    final response = await ApiService.createParcel(
      name: nombre,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    if (response["ok"]) {
      _mostrarSnackBarExito("¡Parcela registrada con éxito!");
      await _loadParcelsData();
    } else {
      setState(() => isLoading = false);
      _mostrarAlertaAmigable(
          "Error al guardar", "El servidor respondió: ${response["message"]}");
    }
  }

  // ==========================================
  // 4. DIAGNÓSTICO DE CULTIVO CON IA
  // ==========================================

  Future<void> _mostrarGuiaDiagnostico(int cropId, String cropName) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Antes de tomar la foto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _GuiaItem(
                icon: Icons.wb_sunny_outlined,
                text:
                    "Usa luz natural, evita sombras fuertes y no tomes la foto de noche."),
            SizedBox(height: 8),
            _GuiaItem(
                icon: Icons.flash_off,
                text: "No uses flash: genera brillos que confunden al modelo."),
            SizedBox(height: 8),
            _GuiaItem(
                icon: Icons.photo_size_select_large,
                text:
                    "Acerca la cámara a 15-25 cm y enfoca la zona afectada completa."),
            SizedBox(height: 8),
            _GuiaItem(
                icon: Icons.blur_on,
                text:
                    "Mantén la mano firme y la hoja limpia (sin polvo ni gotas)."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await _iniciarProcesoDiagnostico(cropId, cropName);
    }
  }

  Future<void> _iniciarProcesoDiagnostico(int cropId, String cropName) async {
    // 1. Validar Ubicación
    final position = await _determinarPosicionActual();
    if (position == null) return;

    // 2. Elegir origen de la imagen (cámara o galería)
    final imageSource = await _seleccionarFuenteImagen();
    if (imageSource == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? photo = imageSource == ImageSource.camera
        ? await picker.pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.rear,
            imageQuality: 85,
          )
        : await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );

    if (photo == null) return; // Usuario canceló

    File imageFile = File(photo.path);

    // 3. Proceso de Envío
    if (!mounted) return;
    _mostrarDialogoCarga("Analizando hoja...");

    try {
      Map<String, dynamic>? result;
      bool isSuccess = false;

      // Check de salud del backend
      bool isBackendOnline = false;
      try {
        isBackendOnline = await ApiService.checkBackendHealth();
      } catch (_) {}

      bool fueOffline = false;

      if (isBackendOnline) {
        // Enviar imagen
        final response = await ApiService.uploadImageToCrop(
          imageFile,
          cropId: cropId,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        if (response != null && response is Map<String, dynamic>) {
          isSuccess = true;

          // =====================================================================
          // 🔥 AQUÍ OCURRE LA MAGIA DEL INTERCEPTOR DE RECOMENDACIONES 🔥
          // =====================================================================
          String rawDisease =
              response["disease_name"] ?? response["disease"] ?? "Desconocido";

          // Invocamos a la librería para obtener datos ricos, reales y estudiados
          Map<String, dynamic> expertAdvice =
              CornDiseaseLibrary.getDetailedDiagnosis(rawDisease);

          // Fusionamos la respuesta de la API con el consejo experto local
          result = {
            ...response, // Mantener datos originales
            "display_title": expertAdvice["title"],
            "disease_name":
                expertAdvice["title"], // Sobrescribir con nombre limpio
            "description": expertAdvice["description"],
            "recommendation":
                expertAdvice["chemical"], // Compatibilidad backward
            "chemical_control": expertAdvice["chemical"],
            "organic_control": expertAdvice["organic"],
            "prevention": expertAdvice["prevention"],
            "is_healthy": expertAdvice["is_healthy"],
            "severity": expertAdvice["severity"],
          };
        }
      } else {
        // MODO OFFLINE
        await DBService.saveDiagnosis(
          imagePath: imageFile.path,
          userId: widget.userId,
          cropId: cropId,
          disease: "Pendiente de Análisis",
          recommendation: "Sin internet. Sincroniza más tarde.",
          confidence: 0.0,
          isCornLeaf: true,
          latitude: position.latitude,
          longitude: position.longitude,
          createdAt: DateTime.now().toIso8601String(),
        );
        isSuccess = true;
        fueOffline = true;
        result = {
          "disease_name": "Guardado Offline",
          "display_title": "MODO OFFLINE",
          "description": "Tu diagnóstico se ha guardado localmente.",
          "confidence": 0.0,
          "recommendation":
              "Se guardó en el dispositivo. Conéctate a internet para analizar.",
          "is_offline": true,
          "is_healthy": true // Neutral
        };
      }

      if (mounted) Navigator.pop(context); // Cierra loading

      if (!mounted) return;

      if (isSuccess && fueOffline) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CropDiagnosisScreen(
              cropId: cropId,
              cropName: cropName,
            ),
          ),
        );
        return;
      }

      if (isSuccess && result != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosisResultScreen(
              cropName: cropName,
              imageFile: imageFile,
              resultData: result!,
            ),
          ),
        ).then((_) {
          _loadParcelsData();
        });
      } else {
        if (mounted)
          _mostrarAlertaAmigable("Error", "No se pudo procesar la imagen.");
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      debugPrint("Error Diagnostico: $e");
      _mostrarAlertaAmigable("Excepción", "Ocurrió un error inesperado: $e");
    }
  }

  Future<ImageSource?> _seleccionarFuenteImagen() async {
    if (!mounted) return null;

    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const ListTile(
                  title: Text(
                    "Selecciona una opción",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt_rounded, color: primaryColor),
                  title: const Text("Tomar foto"),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: primaryColor),
                  title: const Text("Elegir de galería"),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 5. PAPELERA LOCAL (SOLO FRONTEND)
  // ==========================================
  Future<void> _moverParcelaAPapelera(Map<String, dynamic> parcel) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Mover a papelera?"),
        content: const Text(
            "La parcela se ocultará de la lista principal, pero podrás restaurarla después desde la papelera."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Mover", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final parcelId = parcel['id'];
      if (parcelId is! int) return;

      setState(() {
        _trashedParcelIds.add(parcelId);
        final exists = _trashedParcels.any((item) => item['id'] == parcelId);
        if (!exists) {
          _trashedParcels.add(Map<String, dynamic>.from(parcel));
        }
      });
      await _saveTrashedParcelIds();
      _mostrarSnackBarExito("Parcela movida a papelera");
    }
  }

  void _restaurarParcela(Map<String, dynamic> parcel) {
    final parcelId = parcel['id'];
    if (parcelId is! int) return;

    setState(() {
      _trashedParcelIds.remove(parcelId);
      _trashedParcels.removeWhere((item) => item['id'] == parcelId);
    });

    unawaited(_saveTrashedParcelIds());

    _mostrarSnackBarExito("Parcela restaurada correctamente");
  }

  Future<void> _abrirPapelera() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrashParcelsScreen(
          trashedParcels: List<Map<String, dynamic>>.from(_trashedParcels),
          onRestore: _restaurarParcela,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ==========================================
  // 6. UTILIDADES UI
  // ==========================================

  void _mostrarAlertaAmigable(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.info_outline_rounded,
                    size: 40, color: Colors.orange),
              ),
              const SizedBox(height: 15),
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(mensaje,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Entendido",
                      style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoCarga(String texto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10)
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 20),
                Text(texto,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarSnackBarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Text(mensaje)
        ]),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==========================================
  // 7. BUILD: ESTRUCTURA VISUAL PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // ESTE BOTÓN DEBE ESTAR SIEMPRE AQUÍ ABAJO:
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darkGreen,
        elevation: 4,
        icon:
            const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
        label: const Text("Registrar Parcela",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        onPressed: _abrirModalCrearParcela,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: ClipPath(
              clipper: BackgroundWaveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF81C784), darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mis Tierras",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4)
                                ]),
                          ),
                          Text(
                            "Gestiona tus cultivos",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.white),
                                  onPressed: _abrirPapelera,
                                  tooltip: "Abrir papelera",
                                ),
                                if (_trashedParcels.isNotEmpty)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _trashedParcels.length.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white),
                              onPressed: _loadParcelsData,
                              tooltip: "Recargar lista",
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : _visibleParcels.isEmpty
                          ? _buildEmptyState()
                          : _buildParcelList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.signal_wifi_off_rounded,
                size: 50, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          const Text(
            "Sin conexión o sin parcelas",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loadParcelsData,
            child: const Text("Reintentar cargar"),
          )
        ],
      ),
    );
  }

  Widget _buildParcelList() {
    final visibleParcels = _visibleParcels;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: visibleParcels.length,
      itemBuilder: (ctx, index) {
        final p = visibleParcels[index];
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final double start = (index / visibleParcels.length) * 0.5;
            final double end = start + 0.4;
            final curve = CurvedAnimation(
              parent: _animController,
              curve:
                  Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
            );
            return FadeTransition(
              opacity: curve,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - curve.value)),
                child: child,
              ),
            );
          },
          child: _buildParcelCard(p),
        );
      },
    );
  }

  Widget _buildParcelCard(Map<String, dynamic> parcel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [primaryColor, darkGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]),
                  child: const Icon(Icons.grass, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel["name"] ?? "Sin Nombre",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            "Lat: ${parcel['latitude'].toString().substring(0, 6)}...",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    icon:
                        Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                    onSelected: (value) {
                      if (value == 'trash') _moverParcelaAPapelera(parcel);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'trash',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.orangeAccent, size: 20),
                            SizedBox(width: 10),
                            Text("Mover a papelera",
                                style: TextStyle(color: Colors.orangeAccent)),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text("Diagnosticar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () =>
                        _mostrarGuiaDiagnostico(parcel["id"], parcel["name"]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history_edu_rounded, size: 18),
                    label: const Text("Historial"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkGreen,
                      side: const BorderSide(color: darkGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CropDiagnosisScreen(
                                  cropId: parcel["id"],
                                  cropName: parcel["name"])));
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _GuiaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GuiaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.3),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// 🌽 SMART MAIZE CAMERA: ESCÁNER BIOMÉTRICO 🌽
// =========================================================
class SmartMaizeCameraScreen extends StatefulWidget {
  const SmartMaizeCameraScreen({super.key});

  @override
  State<SmartMaizeCameraScreen> createState() => _SmartMaizeCameraScreenState();
}

class _SmartMaizeCameraScreenState extends State<SmartMaizeCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Estado del análisis
  String _statusMessage = "Iniciando...";
  Color _statusColor = Colors.white;

  // Progreso de validación (0.0 a 1.0)
  double _scanProgress = 0.0;

  // Variables de control de estabilidad y condiciones
  int _goodFramesCount = 0;
  final int _requiredGoodFrames = 15;

  // Flag para bloquear acciones cuando ya se dispara la foto
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) throw "No hay cámaras disponibles";

      final camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);

      _controller = CameraController(
        camera,
        // 🔴 CAMBIO CLAVE: Usamos medium en lugar de high para evitar error de memoria
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startImageStream();
      }
    } catch (e) {
      debugPrint("Error cámara: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al abrir cámara")));
        Navigator.pop(context, null);
      }
    }
  }

  void _startImageStream() {
    int frameSkip = 0;
    _controller?.startImageStream((CameraImage image) async {
      // Si estamos ocupados, IGNORAMOS el cuadro para no llenar la memoria
      if (_isProcessing || _isCapturing) return;

      // Procesamos solo 1 de cada 3 cuadros (antes era 4, con medium podemos bajarlo a 3)
      frameSkip++;
      if (frameSkip % 3 != 0) return;

      try {
        _isProcessing = true; // Bloqueamos el paso

        // Ejecutamos análisis
        final resultado = await _analizarFrameBiometrico(image);

        if (!mounted) return;

        setState(() {
          _actualizarEstadoUI(resultado);
        });

        if (resultado['is_valid']) {
          _goodFramesCount++;
          _scanProgress =
              (_goodFramesCount / _requiredGoodFrames).clamp(0.0, 1.0);

          if (_goodFramesCount >= _requiredGoodFrames) {
            await _capturarAutomaticamente();
          }
        } else {
          if (_goodFramesCount > 0) _goodFramesCount -= 2;
          if (_goodFramesCount < 0) _goodFramesCount = 0;
          _scanProgress =
              (_goodFramesCount / _requiredGoodFrames).clamp(0.0, 1.0);
        }
      } catch (e) {
        debugPrint("Error procesando frame: $e");
      } finally {
        // SIEMPRE liberamos la bandera, pase lo que pase
        _isProcessing = false;
      }
    });
  }

  Future<Map<String, dynamic>> _analizarFrameBiometrico(
      CameraImage image) async {
    final int width = image.width;
    final int height = image.height;
    final int centerX = width ~/ 2;
    final int centerY = height ~/ 2;

    final int roiW = width ~/ 2;
    final int roiH = height ~/ 2;
    final int startX = centerX - (roiW ~/ 2);
    final int startY = centerY - (roiH ~/ 2);

    int totalLuma = 0;
    int greenPixels = 0;
    int pixelCount = 0;

    if (image.format.group == ImageFormatGroup.yuv420) {
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;
      final uvRowStride = image.planes[1].bytesPerRow;
      final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      for (int y = startY; y < startY + roiH; y += 10) {
        for (int x = startX; x < startX + roiW; x += 10) {
          final int index = y * width + x;
          final int yValue = yPlane[index];

          totalLuma += yValue;

          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
          final int uValue = uPlane[uvIndex] & 0xFF;
          final int vValue = vPlane[uvIndex] & 0xFF;

          int r = (yValue + 1.370705 * (vValue - 128)).toInt();
          int g =
              (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
                  .toInt();
          int b = (yValue + 1.732446 * (uValue - 128)).toInt();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          if (g > b && (g > r || (r > b && r > 100))) {
            greenPixels++;
          }

          pixelCount++;
        }
      }
    } else {
      totalLuma = 120 * 1000;
      pixelCount = 1000;
      greenPixels = 650;
    }

    final double avgLuma = (pixelCount == 0) ? 0 : totalLuma / pixelCount;
    final double greenRatio = (pixelCount == 0) ? 0 : greenPixels / pixelCount;

    bool isLightOk = avgLuma > 50 && avgLuma < 220;
    bool isCoverageOk = greenRatio > 0.40;

    String msg = "";
    if (!isLightOk) {
      if (avgLuma <= 50)
        msg = "Muy oscuro. Busca luz.";
      else
        msg = "Mucho brillo. Evita reflejos.";
    } else if (!isCoverageOk) {
      msg = "Acércate más a la hoja.";
    } else {
      msg = "Perfecto. Mantén quieto.";
    }

    return {
      "is_valid": isLightOk && isCoverageOk,
      "message": msg,
      "luma": avgLuma,
      "coverage": greenRatio
    };
  }

  void _actualizarEstadoUI(Map<String, dynamic> analisis) {
    if (analisis['is_valid']) {
      _statusColor = const Color(0xFF00E676);
      _statusMessage = "Analizando... ${(_scanProgress * 100).toInt()}%";
    } else {
      _statusColor = Colors.white;
      _statusMessage = analisis['message'];
    }
  }

  Future<void> _capturarAutomaticamente() async {
    if (_isCapturing) return;
    _isCapturing = true;

    HapticFeedback.heavyImpact();

    setState(() {
      _statusMessage = "¡Procesando!";
      _statusColor = Colors.greenAccent;
    });

    try {
      final XFile image = await _controller!.takePicture();

      if (!mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      _isCapturing = false;
      _goodFramesCount = 0;
      debugPrint("Error al capturar: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          CustomPaint(
            painter: ScannerOverlayPainter(
              borderColor: _statusColor,
              scanValue: _scanProgress,
            ),
            child: Container(),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24)),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.greenAccent, size: 16),
                            SizedBox(width: 8),
                            Text("IA ACTIVA",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: _statusColor == Colors.white
                          ? Colors.black.withOpacity(0.7)
                          : _statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: _statusColor.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2)
                      ]),
                  child: Column(
                    children: [
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _statusColor == Colors.white
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      if (_statusColor == Colors.white) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Apunta al choclo/hoja dentro del marco",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        )
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          if (_goodFramesCount > 0)
            Positioned(
              top: size.height * 0.25 + (size.height * 0.5 * _scanProgress),
              left: 40,
              right: 40,
              child: Container(
                height: 3,
                decoration:
                    BoxDecoration(color: Colors.greenAccent, boxShadow: [
                  BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2)
                ]),
              ),
            )
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double scanValue;

  ScannerOverlayPainter({required this.borderColor, required this.scanValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    final width = size.width;
    final height = size.height;

    final rectWidth = width * 0.85;
    final rectHeight = height * 0.55;
    final left = (width - rectWidth) / 2;
    final top = (height - rectHeight) / 2;

    final cutOutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, rectWidth, rectHeight),
      const Radius.circular(20),
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, width, height)),
        Path()..addRRect(cutOutRect),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final double cornerSize = 50;

    // Dibujo de esquinas
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerSize)
        ..lineTo(left, top)
        ..lineTo(left + cornerSize, top),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + rectWidth - cornerSize, top)
        ..lineTo(left + rectWidth, top)
        ..lineTo(left + rectWidth, top + cornerSize),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left, top + rectHeight - cornerSize)
        ..lineTo(left, top + rectHeight)
        ..lineTo(left + cornerSize, top + rectHeight),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + rectWidth - cornerSize, top + rectHeight)
        ..lineTo(left + rectWidth, top + rectHeight)
        ..lineTo(left + rectWidth, top + rectHeight - cornerSize),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.scanValue != scanValue;
  }
}

// ==========================================
// PANTALLA DE RESULTADO (MODIFICADA PARA OCULTAR TRATAMIENTOS SI NO ES MAÍZ)
// ==========================================
class DiagnosisResultScreen extends StatelessWidget {
  final String cropName;
  final File imageFile;
  final Map<String, dynamic> resultData;

  const DiagnosisResultScreen({
    super.key,
    required this.cropName,
    required this.imageFile,
    required this.resultData,
  });

  @override
  Widget build(BuildContext context) {
    // 1. EXTRAER DATOS
    final String displayTitle = resultData['display_title'] ??
        resultData['disease_name'] ??
        "Desconocido";
    final String description = resultData['description'] ?? "No disponible.";
    final String chemical = resultData['chemical_control'] ?? "";
    final String organic = resultData['organic_control'] ?? "";
    final String prevention = resultData['prevention'] ?? "";

    // 2. FLAGS DE ESTADO
    final bool isOffline = resultData['is_offline'] ?? false;
    final bool isHealthy = resultData['is_healthy'] ?? false;

    // DETECTAR SI ES EL CASO "NO ES MAÍZ"
    // Usamos el título o la severidad para saber si es un error de foto
    final bool isNoMaiz = displayTitle.contains("NO VEO BIEN") ||
        resultData['severity'] == "ERROR DE TOMA";

    // 3. COLORES DINÁMICOS
    final Color statusColor = isOffline
        ? Colors.grey
        : (isNoMaiz
            ? Colors.orangeAccent // Color de advertencia para "No Maíz"
            : (isHealthy
                ? const Color(0xFF66BB6A)
                : const Color(0xFFEF5350))); // Verde o Rojo

    final IconData statusIcon = isOffline
        ? Icons.cloud_off
        : (isNoMaiz
            ? Icons.image_not_supported_rounded // Icono de foto mala
            : (isHealthy
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded));

    return Scaffold(
      body: Stack(
        children: [
          // FONDO DE IMAGEN
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            child: Image.file(imageFile, fit: BoxFit.cover),
          ),

          // SOMBRA SUPERIOR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
          ),

          // BOTÓN ATRÁS
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // PANEL DESLIZABLE (BOTTOM SHEET)
          DraggableScrollableSheet(
            initialChildSize: 0.60,
            minChildSize: 0.60,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          spreadRadius: 2)
                    ]),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(25),
                  children: [
                    // BARRA DE ARRASTRE
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ENCABEZADO TITULO E ICONO
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: Icon(statusIcon, color: statusColor, size: 35),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Diagnóstico IA",
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                displayTitle,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),

                    // DESCRIPCIÓN DEL PROBLEMA
                    Text(isNoMaiz ? "¿Qué pasó?" : "Descripción",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.5,
                            fontSize: 15)),

                    const SizedBox(height: 25),

                    // ========================================================
                    // LÓGICA DE VISUALIZACIÓN (EL CAMBIO CLAVE ESTÁ AQUÍ)
                    // ========================================================

                    if (isNoMaiz) ...[
                      // CASO 1: NO ES MAÍZ (Solo muestra consejo de foto)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.orange[200]!)),
                        child: Column(
                          children: [
                            const Icon(Icons.center_focus_weak,
                                size: 40, color: Colors.orange),
                            const SizedBox(height: 15),
                            const Text(
                              "Sigue este consejo:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              prevention, // Aquí viene el consejo de cómo tomar la foto
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      )
                    ] else if (isHealthy) ...[
                      // CASO 2: PLANTA SANA (Solo felicitación)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green[200]!)),
                        child: const Row(
                          children: [
                            Icon(Icons.emoji_events, color: Colors.green),
                            SizedBox(width: 15),
                            Expanded(
                                child: Text(
                                    "¡Excelente trabajo! Tu cultivo se ve saludable. Sigue manteniendo buenas prácticas."))
                          ],
                        ),
                      )
                    ] else ...[
                      // CASO 3: ENFERMEDAD REAL (Muestra tratamientos)
                      _buildTreatmentSection("Control Químico", Icons.science,
                          chemical, Colors.blue[50]!, Colors.blue[800]!),
                      const SizedBox(height: 15),
                      _buildTreatmentSection("Control Orgánico", Icons.eco,
                          organic, Colors.green[50]!, Colors.green[800]!),
                      const SizedBox(height: 15),
                      _buildTreatmentSection("Prevención Futura", Icons.shield,
                          prevention, Colors.orange[50]!, Colors.orange[800]!),
                    ],

                    const SizedBox(height: 40),

                    // BOTÓN FINAL
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("FINALIZAR Y VOLVER",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // WIDGET AUXILIAR PARA LOS ACORDEONES
  Widget _buildTreatmentSection(String title, IconData icon, String content,
      Color bgColor, Color iconColor) {
    if (content.isEmpty)
      return const SizedBox.shrink(); // No mostrar si está vacío
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, color: iconColor)),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(content,
              style: const TextStyle(
                  fontSize: 15, height: 1.6, color: Colors.black87)),
        ],
      ),
    );
  }
}

class BackgroundWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
