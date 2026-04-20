import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE DATOS
// ─────────────────────────────────────────────────────────────────────────────
class DiseaseData {
  final String name;
  final String scientificName;
  final String tagline;
  final IconData icon;
  final Color primaryColor;
  final String description;
  final String causes;
  final String propagation;
  final String prevention;
  final String bestPractices;
  final String imageUrl;

  const DiseaseData({
    required this.name,
    required this.scientificName,
    required this.tagline,
    required this.icon,
    required this.primaryColor,
    required this.description,
    required this.causes,
    required this.propagation,
    required this.prevention,
    required this.bestPractices,
    required this.imageUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CATÁLOGO DE ENFERMEDADES
// ─────────────────────────────────────────────────────────────────────────────
const kDiseases = <DiseaseData>[
  DiseaseData(
    name: 'Roya',
    scientificName: 'Puccinia sorghi',
    tagline: 'Pústulas anaranjadas en ambas caras de la hoja',
    icon: Icons.grain,
    primaryColor: Color(0xFFD84315),
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/8/8c/Puccinia_sorghi_%2805%29.jpg',
    description:
        'La Roya del Maíz es una enfermedad fúngica que se manifiesta como '
        'pústulas pequeñas de color naranja–marrón en ambas caras de las hojas. '
        'Al frotar las pústulas liberan un polvo anaranjado (esporas) '
        'característico. En infecciones severas las hojas se tornan amarillas y '
        'se secan prematuramente, reduciendo la fotosíntesis y el rendimiento '
        'de la planta.',
    causes: '• Hongo: Puccinia sorghi\n'
        '• Temperatura óptima: 16 – 23 °C\n'
        '• Humedad relativa alta (> 95 %) y períodos frecuentes de rocío\n'
        '• Lluvias frecuentes que facilitan la dispersión de esporas\n'
        '• Noches frescas seguidas de días cálidos y húmedos\n'
        '• Uso de variedades susceptibles sin resistencia genética',
    propagation:
        '• Urediniosporas dispersadas fácilmente por el viento a grandes distancias\n'
        '• El ciclo completo de infección dura solo 7 – 14 días en condiciones ideales\n'
        '• Una planta enferma puede infectar miles de plantas vecinas\n'
        '• Las esporas sobreviven en plantas voluntarias entre cosecha y cosecha',
    prevention:
        '• Usar híbridos certificados con resistencia genética a la Roya\n'
        '• Aplicar fungicidas preventivos (triazoles o estrobilurina) al inicio\n'
        '• Monitorear el cultivo cada 7 días desde la emergencia\n'
        '• Sembrar en la época recomendada para evitar las condiciones propicias\n'
        '• Tratar las semillas con fungicidas sistémicos antes de la siembra',
    bestPractices: '• Retirar y destruir los residuos de cosecha infectados\n'
        '• Rotar cultivos con leguminosas (soja, frijol) al menos 1 temporada\n'
        '• Evitar el exceso de fertilización nitrogenada que debilita la planta\n'
        '• Mantener un espaciado adecuado para buena ventilación entre plantas\n'
        '• Registrar las parcelas afectadas para planificar la próxima siembra',
  ),
  DiseaseData(
    name: 'Tizón',
    scientificName: 'Exserohilum turcicum',
    tagline: 'Lesiones elípticas grisáceas que avanzan de abajo hacia arriba',
    icon: Icons.whatshot,
    primaryColor: Color(0xFF6D4C41),
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/2/2d/Northern_corn_leaf_blight.JPG',
    description:
        'El Tizón del Norte del Maíz produce lesiones elípticas de 2 a 15 cm '
        'de largo, de color gris–verdoso a café con bordes ondulados. Las '
        'manchas comienzan en las hojas bajas y ascienden progresivamente hacia '
        'el dosel. En el centro de cada lesión se observan líneas oscuras de '
        'esporulación del hongo. Cuando la infección ocurre antes de la '
        'polinización puede reducir el rendimiento hasta un 50 %.',
    causes: '• Hongo: Exserohilum turcicum\n'
        '• Temperatura óptima: 18 – 27 °C\n'
        '• Humedad foliar sostenida por más de 6 horas consecutivas\n'
        '• Lluvia frecuente y riego por aspersión nocturno\n'
        '• Alta densidad de siembra que reduce la aireación del cultivo\n'
        '• Siembra continua de maíz sin rotación de cultivos',
    propagation:
        '• Conidias dispersadas por el viento y el salpique de lluvia\n'
        '• El inóculo primario sobrevive en residuos de cosecha en el suelo\n'
        '• La dispersión es mayor durante períodos de lluvia y alta humedad\n'
        '• El hongo puede infectar en pocas horas cuando las condiciones son idóneas',
    prevention:
        '• Seleccionar híbridos con resistencia específica al Tizón del Norte\n'
        '• Aplicar fungicidas sistémicos en los estadios V6 – VT (inicio espiga)\n'
        '• Mantener densidades de siembra que permitan buena aireación\n'
        '• Evitar riegos nocturnos que prolongan la humedad sobre el follaje\n'
        '• Usar semillas de calidad certificada con tratamiento fungicida',
    bestPractices: '• Rotar con soja, frijol o girasol al menos una temporada\n'
        '• Incorporar profundamente los residuos de cosecha infectados\n'
        '• Planificar el riego para que las hojas se sequen antes del anochecer\n'
        '• Monitorear el cultivo desde V4 – V6 buscando lesiones en hojas bajas\n'
        '• Documentar parcelas con historial de Tizón para tratamiento preventivo',
  ),
  DiseaseData(
    name: 'Mancha Gris',
    scientificName: 'Cercospora zeae-maydis',
    tagline: 'Manchas rectangulares limitadas por las nervaduras de la hoja',
    icon: Icons.blur_on,
    primaryColor: Color(0xFF546E7A),
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/1/12/Gray_leaf_spot_Cercospora_zeae-maydis_5465607.png',
    description:
        'La Mancha Gris del Maíz se presenta como lesiones rectangulares de '
        'color gris a pardo, delimitadas entre las nerviaciones de la hoja. '
        'Las manchas van desde pocos milímetros hasta varios centímetros de '
        'largo. En casos severos, las lesiones se fusionan cubriendo grandes '
        'áreas foliares, lo que provoca la muerte prematura de las hojas y '
        'reduce significativamente la capacidad fotosintética y el llenado del grano.',
    causes: '• Hongo: Cercospora zeae-maydis\n'
        '• Temperatura óptima: 25 – 30 °C\n'
        '• Períodos prolongados de rocío nocturno y neblina matutina\n'
        '• Monocultivo de maíz por varios años consecutivos\n'
        '• Acumulación de residuos infectados en la superficie del suelo\n'
        '• Variedades susceptibles sin resistencia genética al hongo',
    propagation:
        '• Esporas liberadas principalmente en noches húmedas y frescas\n'
        '• Dispersión por salpicadura de lluvia y viento a corta distancia\n'
        '• El hongo sobrevive en residuos de cosecha sobre el suelo entre temporadas\n'
        '• La infección requiere un mínimo de 12 horas de humedad foliar continua',
    prevention: '• Sembrar híbridos con resistencia parcial a Cercospora\n'
        '• Aplicar fungicidas mixtos (estrobilurina + triazol) preventivamente\n'
        '• Evitar labranza mínima sin rotación en zonas de alto riesgo\n'
        '• Mejorar el drenaje del campo para reducir la humedad ambiental\n'
        '• Iniciar el monitoreo desde el estadio V8 (8 hojas expandidas)',
    bestPractices:
        '• Rotar maíz con cultivos no hospederos: soja, papa o trigo\n'
        '• Incorporar los residuos de cosecha al suelo mediante labranza profunda\n'
        '• Mejorar el sistema de drenaje en zonas con exceso de humedad\n'
        '• Llevar registro histórico de parcelas afectadas para planificar\n'
        '• Capacitar al personal en el reconocimiento temprano de síntomas',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA DE LISTA
// ─────────────────────────────────────────────────────────────────────────────
class DiseaseInfoScreen extends StatelessWidget {
  const DiseaseInfoScreen({super.key});

  static const Color _darkGreen = Color(0xFF2E7D32);
  static const Color _bgColor = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Fondo ondulado degradado (igual que Historial / Diagnóstico) ──
          ClipPath(
            clipper: _DiseaseWaveClipper(),
            child: Container(
              height: size.height * 0.35,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF81C784), _darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guía de Enfermedades',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Conoce las enfermedades del maíz',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Lista de enfermedades ──
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: kDiseases.length,
                    itemBuilder: (context, index) {
                      final disease = kDiseases[index];
                      return _DiseaseCard(
                        disease: disease,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DiseaseDetailScreen(disease: disease),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA EN LA LISTA
// ─────────────────────────────────────────────────────────────────────────────
class _DiseaseCard extends StatelessWidget {
  final DiseaseData disease;
  final VoidCallback onTap;

  const _DiseaseCard({required this.disease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fotografía de la enfermedad ──
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  disease.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          disease.primaryColor.withOpacity(0.7),
                          disease.primaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(disease.icon, color: Colors.white, size: 50),
                    ),
                  ),
                ),
              ),
              // ── Ícono + nombre + flecha ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: disease.primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(disease.icon,
                          color: disease.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            disease.scientificName,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            disease.tagline,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF455A64),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA DE DETALLE
// ─────────────────────────────────────────────────────────────────────────────
class DiseaseDetailScreen extends StatelessWidget {
  final DiseaseData disease;

  const DiseaseDetailScreen({super.key, required this.disease});

  static const Color _darkGreen = Color(0xFF2E7D32);
  static const Color _bgColor = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sections = _buildSections();

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Fondo ondulado degradado (mismo que todas las pantallas) ──
          ClipPath(
            clipper: _DiseaseWaveClipper(),
            child: Container(
              height: size.height * 0.35,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF81C784), _darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Row(
                    children: [
                      // Botón atrás
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(disease.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              disease.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              disease.scientificName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Fotografía + Secciones expandibles ──
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Fotografía de la enfermedad
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            disease.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    disease.primaryColor.withOpacity(0.7),
                                    disease.primaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(disease.icon,
                                    color: Colors.white, size: 60),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ...sections.map((s) => _SectionExpander(section: s)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_SectionData> _buildSections() => [
        _SectionData(
          title: 'Descripción',
          icon: Icons.info_outline,
          color: const Color(0xFF1565C0),
          content: disease.description,
          initiallyExpanded: true,
        ),
        _SectionData(
          title: 'Causas',
          icon: Icons.science_outlined,
          color: const Color(0xFFBF360C),
          content: disease.causes,
        ),
        _SectionData(
          title: 'Propagación',
          icon: Icons.air,
          color: const Color(0xFF6A1B9A),
          content: disease.propagation,
        ),
        _SectionData(
          title: 'Prevención',
          icon: Icons.shield_outlined,
          color: const Color(0xFF2E7D32),
          content: disease.prevention,
        ),
        _SectionData(
          title: 'Buenas Prácticas',
          icon: Icons.eco,
          color: const Color(0xFF00695C),
          content: disease.bestPractices,
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIÓN EXPANDIBLE
// ─────────────────────────────────────────────────────────────────────────────
class _SectionData {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final bool initiallyExpanded;

  const _SectionData({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    this.initiallyExpanded = false,
  });
}

class _SectionExpander extends StatelessWidget {
  final _SectionData section;

  const _SectionExpander({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: section.initiallyExpanded,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(section.icon, color: section.color, size: 22),
          ),
          title: Text(
            section.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontSize: 16,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: section.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: section.color.withOpacity(0.15)),
              ),
              child: Text(
                section.content,
                style: const TextStyle(
                  height: 1.7,
                  fontSize: 14,
                  color: Color(0xFF455A64),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAVE CLIPPER (mismo patrón que HistoryWaveClipper / HeaderWaveClipper)
// ─────────────────────────────────────────────────────────────────────────────
class _DiseaseWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height - 30);
    path.quadraticBezierTo(
        size.width * 3 / 4, size.height - 60, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
