import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maiz_app/services/api_service.dart';

// =========================================================
// 🧠 CEREBRO AGRONÓMICO: EL COMPADRE EXPERTO 🧠
// (Tu librería integrada aquí mismo)
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
    if (cleanName.contains("mosaico") || cleanName.contains("virus") || cleanName.contains("streak")) {
      return _getMosaicoData();
    }

    // CARBÓN (Smut)
    if (cleanName.contains("carbon") || cleanName.contains("smut") || cleanName.contains("ustilago")) {
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
      "description": "El sistema detectó '$rawDiseaseName', pero no tengo una ficha técnica exacta para eso. Parece un hongo o problema no registrado.",
      "chemical": "Lo mejor es que lleves esta hoja al técnico de la agropecuaria. Si ves hongos, podrías aplicar un fungicida de amplio espectro.",
      "organic": "Arranca esa hoja fea con cuidado y quémala lejos del cultivo por si acaso.",
      "prevention": "Revisa si aparecen más manchas iguales en los próximos 3 días."
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
      "description": "Fíjate bien: la hoja tiene unos granitos o bultitos color ladrillo o naranja. Haz la prueba del dedo: pásale el dedo por encima suavecito; si te deja el dedo manchado de un polvo color óxido, es Roya seguro.",
      "chemical": "Aquí toca usar un remedio bueno. Busca en la tienda algo que tenga Triazoles (como el Ciproconazol). Fumiga tempranito en la mañana o ya en la tarde cuando baje el sol.",
      "organic": "Si prefieres lo natural, prepara un Caldo Sulfocálcico. Es barato y funciona. También puedes hervir bastante Cola de Caballo, cuelas esa agua y fumigas con eso.",
      "prevention": "No le eches tanta Urea de golpe, porque la planta se pone muy tierna y aguada, y ahí es cuando más le entra este hongo."
    };
  }

  static Map<String, dynamic> _getTizonData() {
    return {
      "title": "TIZÓN (Quemadura de hoja)",
      "is_healthy": false,
      "severity": "MUY ALTA",
      "description": "Mira esas manchas largas y secas de color gris o pardo. Parecen quemaduras de cigarro o canoas alargadas. Empiezan en las hojas de abajo y van subiendo.",
      "chemical": "Para prevenir usa Mancozeb. Pero si ya ves mucha mancha, corre a buscar algo con Azoxistrobina mezclado con Triazol. Aplícalo rápido.",
      "organic": "Hay un hongo bueno que se llama Trichoderma, cómpralo y échalo al suelo y a la hoja. También quita las hojas secas de abajo para que corra el aire.",
      "prevention": "Para la próxima siembra, trata de no poner maíz en el mismo sitio donde hubo maíz enfermo, porque este hongo se queda escondido en el rastrojo viejo."
    };
  }

  static Map<String, dynamic> _getManchaAsfaltoData() {
    return {
      "title": "MANCHA DE ASFALTO",
      "is_healthy": false,
      "severity": "CRÍTICA (¡Actúa rápido!)",
      "description": "Pásale la mano a la hoja. Se sienten rasposos esos puntitos negros brillantes, parecen salpicaduras de brea o asfalto. Alrededor del punto negro se pone seco.",
      "chemical": "¡No te duermas! Esto mata rápido. Pide en la tienda Ciproconazol o Piraclostrobina. Ponle pegante o adherente a la mezcla.",
      "organic": "Está difícil curar esto solo con remedios caseros si ya está avanzado. Podrías probar con extracto de cítricos para frenarlo un poco, pero no te confíes.",
      "prevention": "Siembra las matas un poquito más separadas para que entre luz y aire. A este hongo le encanta la oscuridad y la humedad encerrada."
    };
  }

  static Map<String, dynamic> _getCercosporaData() {
    return {
      "title": "MANCHA GRIS",
      "is_healthy": false,
      "severity": "MEDIA",
      "description": "Son unas manchitas cuadraditas o rectangulares de color gris o café. Si te fijas bien, las manchas corren parejito con las venas de la hoja, no las cruzan.",
      "chemical": "Aplica fungicidas sistémicos cuando el maíz esté empezando a echar la espiga. Productos con Benzimidazoles funcionan bien.",
      "organic": "Prepara un Caldo Bordeles (eso lleva cobre y cal) al 1%. Mézclalo bien y cuélalo para que no se te tape la boquilla.",
      "prevention": "Si tuviste esto el año pasado, te toca meter arado para enterrar toda la basura vieja, porque ahí es donde vive este hongo."
    };
  }

  static Map<String, dynamic> _getMosaicoData() {
    return {
      "title": "MOSAICO (Virus o Rayado)",
      "is_healthy": false,
      "severity": "VARIABLE",
      "description": "La hoja se ve rayada, tiene partes verde clarito y otras verde oscuro, parece piel de tigre o una sandía. Además, la planta se queda chaparra.",
      "chemical": "No hay veneno que cure el virus. Lo que tienes que matar es al bicho que lo trae (el pulgón o la chicharrita). Usa insecticida como Imidacloprid.",
      "organic": "Prepara agua con Jabón Potásico y un poquito de Aceite de Neem para lavar los bichos de la hoja. Pon plásticos amarillos con pegante.",
      "prevention": "Mantén bien limpio el monte de los bordes de la parcela, ahí es donde se esconden los bichos que traen esta enfermedad."
    };
  }
  
  static Map<String, dynamic> _getCarbonData() {
    return {
      "title": "CARBÓN (Esas bolsas negras)",
      "is_healthy": false,
      "severity": "MEDIA",
      "description": "Le han salido unas bolsas o tumores blancos que parecen champiñones deformes. Cuando esas bolsas se secan, botan un polvo negro como carbón.",
      "chemical": "Ya no sirve fumigar la hoja. El remedio era tratar la semilla antes de sembrar. Para la próxima, compra semilla curada con Carboxin.",
      "organic": "¡Haz esto ya! Arranca esas bolsas con cuidado ANTES de que se revienten. Mételas en una funda plástica y sácalas lejos.",
      "prevention": "Ten cuidado cuando pases con el azadón o la cultivadora. Si hieres a la planta, por ahí se mete este hongo."
    };
  }

  static Map<String, dynamic> _getDeficienciaNitrogenoData() {
    return {
      "title": "LE FALTA COMIDA (Nitrógeno)",
      "is_healthy": false,
      "severity": "NUTRICIONAL",
      "description": "La planta tiene hambre. La hoja se está poniendo amarilla empezando desde la punta y bajando por el centro en forma de V.",
      "chemical": "Cómprate un saco de Urea (46-0-0). Tírale al suelo cerquita del tallo, pero asegúrate de que haya humedad.",
      "organic": "Si tienes gallinaza o abono de cuy bien podrido, échale un puñado al pie de cada planta. También puedes sembrar frijol en el medio.",
      "prevention": "Para la otra, haz un análisis de suelo antes de sembrar."
    };
  }

  static Map<String, dynamic> _getSanoData() {
    return {
      "title": "¡QUÉ CHULADA DE MAÍZ!",
      "is_healthy": true,
      "severity": "NINGUNA",
      "description": "¡Te felicito! La hoja está verdecita, limpia y fuerte. No tiene manchas, ni huecos, ni cosas raras.",
      "chemical": "No gastes plata en remedios ni venenos ahorita. Sigue abonando y regando como vas.",
      "organic": "Si quieres consentirla, échale algún bioestimulante de algas o aminoácidos para que cargue mejor la mazorca.",
      "prevention": "No te confíes. Sigue dándote una vuelta por la parcela cada semana."
    };
  }

  // --- DETECTOR: NO ES MAÍZ ---
  static Map<String, dynamic> _getNoEsMaizData() {
    return {
      "title": "NO ES MAÍZ",
      "is_healthy": false,
      "severity": "NO APLICA",
      "description": "La imagen no corresponde a una planta de maíz conocida, o no es una planta.",
      "chemical": "No aplica.",
      "organic": "No aplica.",
      "prevention": "Verifica que la foto esté enfocada y sea de una hoja de maíz."
    };
  }
}

// =========================================================
// PANTALLA DE DETALLE (Modificada para usar el Cerebro)
// =========================================================

class DiagnosisDetailScreen extends StatelessWidget {
  final Map<String, dynamic> diag;

  const DiagnosisDetailScreen({super.key, required this.diag});

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    // 1. EXTRAER DATOS BÁSICOS
    final rawDisease = "${diag['disease'] ?? ''}";
    final userName = "${diag['user_name'] ?? 'Usuario desconocido'}";
    final created = "${diag['created_at'] ?? '-'}";
    final confidence = (diag['confidence'] ?? 0.0);
    final imagePath = "${diag['image_path'] ?? ''}".trim();

    // 2. INVOCAR AL "COMPADRE EXPERTO" (Usar la librería)
    // Esto busca la info detallada basada en el nombre crudo
    final expertInfo = CornDiseaseLibrary.getDetailedDiagnosis(rawDisease);

    // 3. Extraer los datos ricos del experto
    final expertTitle = expertInfo['title'];
    final expertSeverity = expertInfo['severity'];
    final expertDesc = expertInfo['description'];
    final expertChem = expertInfo['chemical'];
    final expertOrg = expertInfo['organic'];
    final expertPrev = expertInfo['prevention'];
    final isHealthy = expertInfo['is_healthy'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F1),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.description, color: Colors.white, size: 20),
              ),
              WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(text: "Diagnóstico"),
            ],
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: ApiService.baseUrl,
        builder: (context, snap) {
          final base = snap.data ?? "";
          final url = imagePath.isEmpty
              ? null
              : (imagePath.startsWith("http")
                  ? imagePath
                  : "$base/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}");

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- FOTO DEL CULTIVO ---
                const Text(
                  "Imagen del cultivo",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryGreen),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: url == null
                        ? _imagePlaceholder()
                        : GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _FullScreenImage(imageUrl: url),
                                ),
                              );
                            },
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- CARD DE INFORMACIÓN GENERAL ---
                _glassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("Información general"),
                        const SizedBox(height: 14),
                        _infoRow("Usuario", userName),
                        _infoRow("Fecha", _formatDate(created)),
                        
                        const Divider(height: 30),
                        
                        // Aquí usamos el título amigable del experto
                        _infoRow("Enfermedad", expertTitle, highlight: true),
                        
                        const SizedBox(height: 10),
                        _infoRow(
                          "Severidad", 
                          expertSeverity, 
                          highlight: true, 
                          customColor: isHealthy ? Colors.green : Colors.redAccent
                        ),
                        
                         const SizedBox(height: 10),
                        _infoRow(
                          "IA Confianza",
                          "${(double.tryParse('$confidence') ?? 0.0).toStringAsFixed(2)}%",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- CARD DEL EXPERTO (RESULTADO DETALLADO) ---
                _glassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology, color: primaryGreen),
                            const SizedBox(width: 8),
                            _sectionTitle("Análisis del Experto"),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // 1. Descripción
                        _expertSection(
                          icon: Icons.search,
                          title: "¿Qué estoy viendo?",
                          content: expertDesc,
                        ),
                        
                        const Divider(height: 30),

                        if (!isHealthy) ...[
                          // 2. Químico
                          _expertSection(
                            icon: Icons.science,
                            title: "Control Químico",
                            content: expertChem,
                            color: Colors.orange[800]!,
                          ),
                          const SizedBox(height: 20),

                          // 3. Orgánico
                          _expertSection(
                            icon: Icons.eco,
                            title: "Control Orgánico/Casero",
                            content: expertOrg,
                            color: Colors.green[700]!,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 4. Prevención (Siempre útil)
                        _expertSection(
                          icon: Icons.shield,
                          title: isHealthy ? "Consejo de Mantenimiento" : "Prevención Futura",
                          content: expertPrev,
                          color: Colors.blue[700]!,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Espacio extra al final
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // WIDGETS AUXILIARES
  // ============================================================

  // Widget para las secciones del experto
  Widget _expertSection({
    required IconData icon, 
    required String title, 
    required String content, 
    Color color = Colors.black87
  }) {
    // Si el contenido dice "No aplica", no lo mostramos o lo mostramos gris
    if (content.contains("No aplica")) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85), // Un poco más opaco para leer mejor el texto
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen),
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false, Color? customColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: highlight ? 16 : 14,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: customColor ?? (highlight ? primaryGreen : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE8ECEF),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 70, color: Colors.black38),
      ),
    );
  }

  String _formatDate(String created) {
    if (created.isEmpty) return "-";
    if (created.length >= 19) return created.substring(0, 19);
    return created;
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImage({required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}