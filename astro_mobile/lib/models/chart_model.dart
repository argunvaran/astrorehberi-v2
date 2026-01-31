class Planet {
  final String name;
  final String sign;
  final double lon;
  final String interpretation;
  final bool isRestricted;

  Planet({
    required this.name,
    required this.sign,
    required this.lon,
    required this.interpretation,
    this.isRestricted = false,
  });

  factory Planet.fromJson(Map<String, dynamic> json) {
    return Planet(
      name: json['name'] ?? '',
      sign: json['sign'] ?? '',
      lon: (json['lon'] ?? 0.0).toDouble(),
      interpretation: json['interpretation'] ?? '',
      isRestricted: json['is_restricted'] ?? false,
    );
  }
}

class Aspect {
  final String p1;
  final String p2;
  final String type;
  final double orb;
  final String interpretation;

  Aspect({
    required this.p1,
    required this.p2,
    required this.type,
    required this.orb,
    required this.interpretation,
  });

  factory Aspect.fromJson(Map<String, dynamic> json) {
    return Aspect(
      p1: json['p1'] ?? '',
      p2: json['p2'] ?? '',
      type: json['type'] ?? '',
      orb: (json['orb'] ?? 0.0).toDouble(),
      interpretation: json['interpretation'] ?? '',
    );
  }
}

class MetaData {
  final int profectionHouse;
  final Map<String, dynamic> dominants;
  final String luckyColor;
  final String luckyStone;
  final String sunSign;
  final List<dynamic> planetaryHours;
  final List<dynamic> draconicChart; 
  final Map<String, dynamic>? celebrityMatch;
  final List<dynamic> acgLines;
  final double? lat; // Added field
  final double? lon; 
  final String? risingSign; // Added field

  MetaData({
    required this.profectionHouse,
    required this.dominants,
    required this.luckyColor,
    required this.luckyStone,
    required this.sunSign,
    required this.planetaryHours,
    required this.draconicChart,
    this.celebrityMatch,
    required this.acgLines,
    this.lat,
    this.lon,
    this.risingSign,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      profectionHouse: json['profection_house'] ?? 1,
      dominants: json['dominants'] ?? {},
      luckyColor: json['lucky_color'] ?? '',
      luckyStone: json['lucky_stone'] ?? '',
      sunSign: json['sun_sign'] ?? '',
      planetaryHours: json['planetary_hours'] ?? [],
      draconicChart: json['draconic_chart'] ?? [],
      celebrityMatch: json['celebrity_match'],
      acgLines: json['acg_lines'] ?? [],
      lat: (json['lat'] ?? json['latitude'])?.toDouble(),
      lon: (json['lon'] ?? json['longitude'])?.toDouble(),
      risingSign: json['rising_sign'],
    );
  }
}

class ChartData {
  final List<Planet> planets;
  final List<Aspect> aspects;
  final MetaData? meta;

  ChartData({required this.planets, required this.aspects, this.meta});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    var planetsList = json['planets'] as List?;
    var aspectsList = json['aspects'] as List?;

    // Try to extract lat/lon from root if not in meta, pass to meta
    // But MetaData constructor is called inside. 
    // We assume backend puts it in meta OR we rely on defaults.
    
    return ChartData(
      planets: planetsList?.map((e) => Planet.fromJson(e)).toList() ?? [],
      aspects: aspectsList?.map((e) => Aspect.fromJson(e)).toList() ?? [],
      meta: json['meta'] != null ? MetaData.fromJson(json['meta']) : null,
    );
  }
}
