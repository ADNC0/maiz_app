import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:maiz_app/services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// =========================================================
//  CEREBRO AGRONÓMICO: EL COMPADRE EXPERTO 
// (Tu librería integrada aquí mismo)
// =========================================================
class CornDiseaseLibrary {

  static String getScientificName(String rawDiseaseName) {
    final cleanName = _normalizeText(rawDiseaseName);

    if (cleanName.contains("roya") ||
        cleanName.contains("rust") ||
        cleanName.contains("puccinia")) {
      return "Puccinia sorghi";
    }

    if (cleanName.contains("tizon") ||
        cleanName.contains("blight") ||
        cleanName.contains("helminthosporium")) {
      return "Exserohilum turcicum";
    }

    if (cleanName.contains("mancha_gris") ||
        cleanName.contains("cercospora") ||
        cleanName.contains("grey_leaf_spot")) {
      return "Cercospora zeae-maydis";
    }

    if (cleanName.contains("gusano cortador") ||
        cleanName.contains("cortador amarillo") ||
        cleanName.contains("cortador") ||
        cleanName.contains("cutworm")) {
      return "Agrotis ipsilon";
    }

    if (cleanName.contains("gusano ejercito") ||
        cleanName.contains("gusano_ejercito") ||
        cleanName.contains("armyworm") ||
        cleanName.contains("ejercito")) {
      return "Spodoptera frugiperda";
    }

    if (cleanName.contains("pulgon") ||
        cleanName.contains("pulgones") ||
        cleanName.contains("aphid") ||
        cleanName.contains("aphids")) {
      return "Rhopalosiphum maidis";
    }

    if (cleanName.contains("pulgilla") ||
        cleanName.contains("leafhopper") ||
        cleanName.contains("chicharrita") ||
        cleanName.contains("cicadella") ||
        cleanName.contains("froghopper")) {
      return "Dalbulus maidis";
    }

    if (cleanName.contains("mosaico") ||
        cleanName.contains("virus") ||
        cleanName.contains("streak")) {
      return "Sugarcane mosaic virus (SCMV)";
    }

    if (cleanName.contains("carbon") ||
        cleanName.contains("smut") ||
        cleanName.contains("ustilago")) {
      return "Ustilago maydis";
    }

    if (cleanName.contains("asfalto") || cleanName.contains("tar_spot")) {
      return "Phyllachora maydis";
    }

    if (cleanName.contains("hoja_sana") ||
        cleanName.contains("healthy") ||
        cleanName.contains("saludable")) {
      return "Zea mays (tejido sano)";
    }

    return "No disponible";
  }

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

    // CASO 6: NO ES PLAGA
    if (cleanName.contains("no_es_plaga") ||
      cleanName.contains("no_plaga") ||
        cleanName.contains("sin plaga") ||
        cleanName.contains("no pest") ||
        cleanName.contains("not_pest") ||
        cleanName.contains("no_plague") ||
        cleanName.contains("no es plaga")) {
      return _getNoEsPlagaData();
    }

    // CASO 7: GUSANO CORTADOR
    if (cleanName.contains("gusano cortador") ||
        cleanName.contains("cortador amarillo") ||
        cleanName.contains("cortador") ||
        cleanName.contains("cutworm")) {
      return _getGusanoCortadorData();
    }

    // CASO 8: GUSANO EJÉRCITO
    if (cleanName.contains("gusano ejercito") ||
        cleanName.contains("gusano_ejercito") ||
        cleanName.contains("armyworm") ||
        cleanName.contains("ejercito")) {
      return _getGusanoEjercitoData();
    }

    // CASO 9: PULGONES
    if (cleanName.contains("pulgon") ||
        cleanName.contains("pulgones") ||
        cleanName.contains("aphid") ||
        cleanName.contains("aphids")) {
      return _getPulgonesData();
    }

    // CASO 10: PULGUILLA / CHICHARRITA
    if (cleanName.contains("pulgilla") ||
        cleanName.contains("leafhopper") ||
        cleanName.contains("chicharrita") ||
        cleanName.contains("cicadella") ||
        cleanName.contains("froghopper")) {
      return _getPulgillaData();
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

  static Map<String, dynamic> _getNoEsPlagaData() {
    return {
      "title": "NO ES PLAGA",
      "is_healthy": false,
      "severity": "NO APLICA",
      "description": "La imagen no muestra una plaga clara. Puede ser un daño por condiciones de cultivo o la foto no corresponde a un insecto.",
      "chemical": "No apliques insecticidas si no hay una plaga confirmada.",
      "organic": "Revisa la planta completa y la foto. Busca si hay falta de agua, nutrientes o físico en la hoja.",
      "prevention": "Antes de actuar, toma una foto bien enfocada y confirma si el problema es plaga o estrés de la planta."
    };
  }

  static Map<String, dynamic> _getGusanoCortadorData() {
    return {
      "title": "GUSANO CORTADOR",
      "is_healthy": false,
      "severity": "ALTA",
      "description": "La planta aparece cortada o mordida en la base del tallo y las hojas jóvenes están a ras de suelo. Este gusano ataca por la noche y deja la planta tumbada.",
      "chemical": "Aplica un insecticida con Cipermetrina o Lambda-cihalotrina en la base de las plantas. Hazlo en la mañana o la tarde cuando los gusanos están activos.",
      "organic": "Coloca cebos con harina y melaza cerca de las plantas afectadas. Recoge las plantas cortadas y usa Bacillus thuringiensis en la base.",
      "prevention": "Mantén limpia la parcela, elimina maleza y rastrojo. Siembra con buena separación para reducir refugios y revisa temprano por la mañana."
    };
  }

  static Map<String, dynamic> _getGusanoEjercitoData() {
    return {
      "title": "GUSANO EJÉRCITO",
      "is_healthy": false,
      "severity": "ALTA",
      "description": "Las hojas aparecen comidas en grupos, con bordes irregulares y la planta como mordida. Se suelen mover varias orugas juntas en la hoja.",
      "chemical": "Aplica un plaguicida a base de Bacillus thuringiensis o un piretroide suave cuando haya pocas orugas visibles.",
      "organic": "Rocía con Bacillus thuringiensis o una mezcla de ajo y chile. También puedes recoger manualmente los grupos de gusanos.",
      "prevention": "No dejes maleza alta cerca del cultivo. Revisa los bordes y rota cultivos para que no se instalen grandes grupos."
    };
  }

  static Map<String, dynamic> _getPulgonesData() {
    return {
      "title": "PULGONES",
      "is_healthy": false,
      "severity": "MEDIA",
      "description": "Las hojas se rizan, aparecen puntitos y pueden gotear una savia pegajosa. Es común ver pequeñas colonias verdes o negras en el envés de la hoja.",
      "chemical": "Usa un insecticida sistémico como Imidacloprid o un piretroide suave aplicado en la mañana.",
      "organic": "Aplica agua jabonosa, aceite de neem o extracto de ajo. Si puedes, introduce mariquitas o insectos benéficos.",
      "prevention": "Controla malezas hospedantes y evita exceso de nitrógeno. Revisa plantas nuevas regularmente."
    };
  }

  static Map<String, dynamic> _getPulgillaData() {
    return {
      "title": "PULGUILLA / CHICHARRITA",
      "is_healthy": false,
      "severity": "MEDIA",
      "description": "Se observan punteados amarillos y hojas con brillo. Las pulgillas chupan savia y pueden transmitir virus entre plantas.",
      "chemical": "Aplica un insecticida sistémico o piretroide, como Imidacloprid o Cipermetrina, en la mañana.",
      "organic": "Rocía con agua jabonosa y aceite de neem. Coloca trampas amarillas y controla las malezas donde se refugian.",
      "prevention": "No fertilices en exceso con nitrógeno. Mantén los bordes limpios y revisa las plantas temprano."
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

  String _resolveDiagnosisImagePath() {
    final serverImagePath =
        "${diag['server_image_path'] ?? diag['serverImagePath'] ?? ''}".trim();
    if (serverImagePath.isNotEmpty) return serverImagePath;
    return "${diag['image_path'] ?? diag['imagePath'] ?? ''}".trim();
  }

  Future<pw.ImageProvider?> _loadDiagnosisPdfImage() async {
    final localPath = "${diag['image_path'] ?? diag['imagePath'] ?? ''}".trim();

    // Prioriza archivo local para que el PDF funcione incluso sin red.
    if (localPath.isNotEmpty && !localPath.startsWith('http')) {
      try {
        final file = File(localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) return pw.MemoryImage(bytes);
        }
      } catch (_) {}
    }

    final imagePath = _resolveDiagnosisImagePath();
    if (imagePath.isEmpty) return null;

    try {
      final base = await ApiService.baseUrl;
      final imageUrl = imagePath.startsWith('http')
          ? imagePath
          : "$base/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}";
      return await networkImage(imageUrl);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _buildDiagnosisPdfBytes() async {
    final rawDisease = "${diag['disease'] ?? ''}";
    final expertInfo = CornDiseaseLibrary.getDetailedDiagnosis(rawDisease);
    final scientificName = CornDiseaseLibrary.getScientificName(rawDisease);
    final userName = "${diag['user_name'] ?? 'Usuario desconocido'}";
    final created = _formatDate("${diag['created_at'] ?? '-'}");
    final confidence = (diag['confidence'] as num?)?.toDouble() ?? 0.0;
    final tipo = "${diag['tipo'] ?? 'enfermedad'}";

    final pdf = pw.Document();
    final confidencePct = ((confidence <= 1 ? confidence * 100 : confidence))
        .toStringAsFixed(1);
    final diagnosisImage = await _loadDiagnosisPdfImage();
    final severity = "${expertInfo['severity'] ?? 'No disponible'}";

    PdfColor _severityColor(String value) {
      final normalized = value.toLowerCase();
      if (normalized.contains('critica')) return PdfColors.red900;
      if (normalized.contains('muy alta')) return PdfColors.red700;
      if (normalized.contains('alta')) return PdfColors.red500;
      if (normalized.contains('media')) return PdfColors.orange700;
      if (normalized.contains('ninguna') || normalized.contains('no aplica')) {
        return PdfColors.green700;
      }
      return PdfColors.blueGrey700;
    }

    pw.Widget _sectionHeader(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.green100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
      );
    }

    pw.Widget _infoRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 92,
              child: pw.Text(
                '$label:',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: const pw.TextStyle(fontSize: 10.5),
              ),
            ),
          ],
        ),
      );
    }

    pw.MemoryImage? logo;
    try {
      final bytes =
          (await rootBundle.load('assets/icon/app_icon.png')).buffer.asUint8List();
      logo = pw.MemoryImage(bytes);
    } catch (_) {
      logo = null;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null)
                pw.Container(
                  width: 54,
                  height: 54,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORME TECNICO DE DIAGNOSTICO',
                      style: pw.TextStyle(
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Cultivo de maiz - Reporte tecnico generado por Maiz App',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Fecha de emision: ${_formatDate(DateTime.now().toIso8601String())}',
                      style: const pw.TextStyle(
                          fontSize: 9.5, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.green300),
          pw.SizedBox(height: 10),
          _sectionHeader('1. Resumen del diagnostico'),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.green50,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow('Usuario', userName),
                      _infoRow('Fecha', created),
                      _infoRow('Tipo',
                          tipo == 'plaga' ? 'Diagnostico de plaga' : 'Diagnostico de enfermedad'),
                      _infoRow('Resultado',
                          '${expertInfo['title'] ?? rawDisease}'),
                        _infoRow('Nombre cientifico', scientificName),
                      _infoRow('Confianza IA', '$confidencePct%'),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.SizedBox(
                            width: 92,
                            child: pw.Text(
                              'Severidad:',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: _severityColor(severity),
                              borderRadius:
                                  const pw.BorderRadius.all(pw.Radius.circular(10)),
                            ),
                            child: pw.Text(
                              severity,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Container(
                  width: 170,
                  height: 170,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green200),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                    color: PdfColors.white,
                  ),
                  child: diagnosisImage != null
                      ? pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(diagnosisImage, fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Imagen no disponible',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(
                                  fontSize: 9.5, color: PdfColors.grey700),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          _sectionHeader('2. Descripcion tecnica'),
          pw.SizedBox(height: 5),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text('${expertInfo['description'] ?? 'No disponible'}'),
          ),
          pw.SizedBox(height: 12),
          _sectionHeader('3. Recomendaciones de manejo'),
          pw.SizedBox(height: 6),
          pw.Bullet(text: 'Control quimico: ${expertInfo['chemical'] ?? 'No disponible'}'),
          pw.SizedBox(height: 5),
          pw.Bullet(text: 'Control organico: ${expertInfo['organic'] ?? 'No disponible'}'),
          pw.SizedBox(height: 5),
          pw.Bullet(text: 'Prevencion futura: ${expertInfo['prevention'] ?? 'No disponible'}'),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'Nota: Este informe es una ayuda tecnica basada en IA. Verifique en campo y consulte un tecnico agronomo antes de aplicar productos.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _downloadDiagnosisPdf(BuildContext context) async {
    try {
      final bytes = await _buildDiagnosisPdfBytes();
      final safeDate = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'diagnostico_maiz_$safeDate.pdf';
      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          data: bytes,
          fileName: fileName,
        ),
      );

      if (!context.mounted) return;

      if (savedPath == null || savedPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado cancelado por el usuario.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF guardado en: $savedPath'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar el PDF: $e')),
      );
    }
  }

  Future<void> _printOrSharePdf(BuildContext context) async {
    try {
      final bytes = await _buildDiagnosisPdfBytes();
      final safeDate = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'diagnostico_maiz_$safeDate.pdf';

      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar el PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. EXTRAER DATOS BÁSICOS
    final rawDisease = "${diag['disease'] ?? ''}";
    final scientificName = CornDiseaseLibrary.getScientificName(rawDisease);
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
        actions: [
          IconButton(
            tooltip: 'Descargar PDF',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _downloadDiagnosisPdf(context),
          ),
          IconButton(
            tooltip: 'Imprimir o compartir PDF',
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _printOrSharePdf(context),
          ),
        ],
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

                        const SizedBox(height: 8),
                        _infoRow("Nombre científico", scientificName),
                        
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