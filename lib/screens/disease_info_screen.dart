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
  final String imageAsset;

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
    required this.imageAsset,
  });
}

class PestData {
  final String name;
  final String scientificName;
  final String tagline;
  final IconData icon;
  final Color primaryColor;
  final String description;
  final String damage;
  final String monitoring;
  final String control;
  final String bestPractices;
  final String imageAsset;

  const PestData({
    required this.name,
    required this.scientificName,
    required this.tagline,
    required this.icon,
    required this.primaryColor,
    required this.description,
    required this.damage,
    required this.monitoring,
    required this.control,
    required this.bestPractices,
    required this.imageAsset,
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
    imageAsset: 'assets/guide/disease_roya.jpg',
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
    imageAsset: 'assets/guide/disease_tizon.jpg',
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
    imageAsset: 'assets/guide/disease_mancha_gris.png',
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

const kPests = <PestData>[
  PestData(
    name: 'Gusano Cortador Amarillo',
    scientificName: 'Agrotis ipsilon',
    tagline: 'Larvas cortan plantas jovenes al nivel del suelo',
    icon: Icons.content_cut,
    primaryColor: Color(0xFF8D6E63),
    imageAsset: 'assets/guide/pest_gusano_cortador_amarillo.jpg',
    description:
        'El gusano cortador amarillo ataca en las primeras etapas del cultivo '
        'y corta las plantulas durante la noche. En focos severos puede reducir '
        'el stand de plantas y afectar el establecimiento uniforme del lote.',
    damage: '• Corte de tallos jovenes a ras de suelo\n'
        '• Parches con baja densidad de plantas\n'
        '• Retraso del cultivo por resiembra\n'
        '• Perdida temprana de vigor y potencial productivo',
    monitoring: '• Revisar de tarde y noche en etapas iniciales\n'
        '• Buscar plantas recien cortadas y larvas en suelo superficial\n'
        '• Muestrear bordes y zonas con residuos vegetales\n'
        '• Registrar porcentaje de plantas danadas por bloque',
    control: '• Mantener control de malezas antes de la siembra\n'
        '• Aplicar cebos o control focalizado en focos activos\n'
        '• Usar insecticidas autorizados segun umbral tecnico\n'
        '• Rotar ingredientes activos para evitar resistencia',
    bestPractices: '• Preparar bien el terreno y reducir refugios de larvas\n'
        '• Monitorear diariamente durante emergencia\n'
        '• Reponer fallas de poblacion de forma oportuna\n'
        '• Integrar manejo cultural, biologico y quimico',
  ),
  PestData(
    name: 'Pulguilla',
    scientificName: 'Phyllotreta striolata',
    tagline: 'Pequenos escarabajos que raspan hojas tiernas',
    icon: Icons.pest_control_rodent,
    primaryColor: Color(0xFF455A64),
    imageAsset: 'assets/guide/pest_pulguilla.jpg',
    description:
        'La pulguilla perfora o raspa hojas jovenes, dejando sintomas de '
        'cribado y debilitando plantulas. Su actividad aumenta con clima seco '
        'y presencia de malezas hospederas cercanas.',
    damage: '• Orificios pequenos en hojas nuevas\n'
        '• Raspado superficial que reduce area foliar activa\n'
        '• Mayor estres en plantas pequenas\n'
        '• Perdida de uniformidad en lotes recien emergidos',
    monitoring: '• Inspeccionar hojas superiores en primeras semanas\n'
        '• Verificar presencia de adultos saltadores al mover plantas\n'
        '• Evaluar dano por porcentaje de hoja afectada\n'
        '• Revisar bordes y sectores con malezas',
    control: '• Manejo oportuno de malezas hospederas\n'
        '• Tratamiento de semilla cuando historial de ataque es alto\n'
        '• Aplicaciones focalizadas segun umbral economico\n'
        '• Respetar dosis y periodo de reingreso',
    bestPractices: '• Siembra uniforme para reducir ventanas de susceptibilidad\n'
        '• Monitoreo intensivo en emergencia y V2-V4\n'
        '• Mantener bordes limpios y sin cruciferas espontaneas\n'
        '• Registrar presion de plaga por lote y campana',
  ),
  PestData(
    name: 'Gusano Ejercito',
    scientificName: 'Spodoptera frugiperda',
    tagline: 'Consumo rapido de hojas y dano en cogollo',
    icon: Icons.pest_control,
    primaryColor: Color(0xFFAD1457),
    imageAsset: 'assets/guide/pest_gusano_ejercito.jpg',
    description:
        'El gusano ejercito puede avanzar rapidamente en grupo, causando '
        'defoliacion y dano en cogollo. En maiz, los ataques tempranos '
        'afectan crecimiento y rendimiento final del cultivo.',
    damage: '• Perforaciones y desgarros extensos en hojas\n'
        '• Presencia de excremento en cogollo\n'
        '• Reduccion de area fotosintetica\n'
        '• Riesgo de perdidas severas en alta infestacion',
    monitoring: '• Recorrer el lote 2 veces por semana\n'
        '• Revisar cogollo, hojas nuevas y excremento\n'
        '• Priorizar control en etapas V3-V8\n'
        '• Mapear focos para respuesta rapida',
    control: '• Uso de biocontrol (Bt y enemigos naturales)\n'
        '• Aplicacion dirigida al cogollo en focos activos\n'
        '• Rotacion de modos de accion\n'
        '• Intervencion segun umbral tecnico recomendado',
    bestPractices: '• Monitoreo temprano y continuo\n'
        '• Evitar aplicaciones preventivas sin evidencia\n'
        '• Conservar registros de incidencia por parcela\n'
        '• Integrar manejo cultural, biologico y quimico',
  ),
  PestData(
    name: 'Pulgones',
    scientificName: 'Rhopalosiphum maidis',
    tagline: 'Colonias succionadoras con melaza en hojas y panoja',
    icon: Icons.bug_report,
    primaryColor: Color(0xFF5D4037),
    imageAsset: 'assets/guide/pest_pulgones.jpg',
    description:
        'Los pulgones se concentran en colonias y succionan savia, debilitando '
        'la planta. Tambien generan melaza que favorece fumagina y afecta la '
        'captacion de luz en el follaje.',
    damage: '• Amarillamiento y enrollamiento de hojas\n'
        '• Reduccion del crecimiento por perdida de savia\n'
        '• Melaza pegajosa y desarrollo de fumagina\n'
        '• Posible transmision de virosis',
    monitoring: '• Revisar envés de hojas y panoja\n'
        '• Buscar colonias, melaza y hormigas asociadas\n'
        '• Muestrear diferentes sectores del lote\n'
        '• Vigilar picos de poblacion en clima seco',
    control: '• Conservar controladores biologicos naturales\n'
        '• Aplicar control quimico solo con umbral superado\n'
        '• Cobertura efectiva en envés de hoja\n'
        '• Rotar ingredientes activos',
    bestPractices: '• Evitar exceso de nitrogeno\n'
        '• Manejar malezas reservorio\n'
        '• Registrar incidencia para decisiones tempranas\n'
        '• Integrar manejo biologico, cultural y quimico',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA DE LISTA
// ─────────────────────────────────────────────────────────────────────────────
class DiseaseInfoScreen extends StatefulWidget {
  const DiseaseInfoScreen({super.key});

  @override
  State<DiseaseInfoScreen> createState() => _DiseaseInfoScreenState();
}

class _DiseaseInfoScreenState extends State<DiseaseInfoScreen> {
  String _selectedGuide = 'enfermedad';

  static const Color _darkGreen = Color(0xFF2E7D32);
  static const Color _bgColor = Color(0xFFF1F8E9);

    String get _title =>
      _selectedGuide == 'plaga' ? 'Guia de Plagas' : 'Guia de Enfermedades';

    String get _subtitle => _selectedGuide == 'plaga'
      ? 'Identifica y maneja plagas del maiz'
      : 'Conoce las enfermedades del maiz';

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _subtitle,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Enfermedades'),
                          selected: _selectedGuide == 'enfermedad',
                          selectedColor: const Color(0xFF81C784),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedGuide = 'enfermedad');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Plagas'),
                          selected: _selectedGuide == 'plaga',
                          selectedColor: const Color(0xFFFFCC80),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedGuide = 'plaga');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Lista de enfermedades / plagas ──
                Expanded(
                  child: _selectedGuide == 'enfermedad'
                      ? ListView.builder(
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
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: kPests.length,
                          itemBuilder: (context, index) {
                            final pest = kPests[index];
                            return _PestCard(
                              pest: pest,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PestDetailScreen(pest: pest),
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
                child: Image.asset(
                  disease.imageAsset,
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

class _PestCard extends StatelessWidget {
  final PestData pest;
  final VoidCallback onTap;

  const _PestCard({required this.pest, required this.onTap});

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
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  pest.imageAsset,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          pest.primaryColor.withOpacity(0.7),
                          pest.primaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(pest.icon, color: Colors.white, size: 50),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: pest.primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(pest.icon, color: pest.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pest.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            pest.scientificName,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            pest.tagline,
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
                          child: Image.asset(
                            disease.imageAsset,
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

class PestDetailScreen extends StatelessWidget {
  final PestData pest;

  const PestDetailScreen({super.key, required this.pest});

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Row(
                    children: [
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
                        child: Icon(pest.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pest.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              pest.scientificName,
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            pest.imageAsset,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    pest.primaryColor.withOpacity(0.7),
                                    pest.primaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(pest.icon,
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
          content: pest.description,
          initiallyExpanded: true,
        ),
        _SectionData(
          title: 'Daños Principales',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFBF360C),
          content: pest.damage,
        ),
        _SectionData(
          title: 'Monitoreo',
          icon: Icons.search,
          color: const Color(0xFF6A1B9A),
          content: pest.monitoring,
        ),
        _SectionData(
          title: 'Control',
          icon: Icons.health_and_safety_outlined,
          color: const Color(0xFF2E7D32),
          content: pest.control,
        ),
        _SectionData(
          title: 'Buenas Prácticas',
          icon: Icons.eco,
          color: const Color(0xFF00695C),
          content: pest.bestPractices,
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
