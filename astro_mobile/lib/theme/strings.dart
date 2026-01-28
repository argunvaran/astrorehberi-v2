class AppStrings {
  static const Map<String, Map<String, String>> _data = {
    'en': {
      'app_title': 'Astro',
      'subtitle': 'Discover your cosmic blueprint.',
      'date_label': 'Date of Birth',
      'time_label': 'Time of Birth',
      'lat_label': 'Latitude',
      'lon_label': 'Longitude',
      'btn_generate': 'GENERATE CHART',
      'chart_title': 'Birth Chart',
      'planets_title': 'Planetary Positions',
      'aspects_title': 'Key Aspects',
      'error_title': 'Error',
      'language_btn': 'Türkçe'
    },
    'tr': {
      'app_title': 'Astro',
      'subtitle': 'Kozmik haritanızı keşfedin.',
      'date_label': 'Doğum Tarihi',
      'time_label': 'Doğum Saati',
      'lat_label': 'Enlem',
      'lon_label': 'Boylam',
      'btn_generate': 'HARİTAYI OLUŞTUR',
      'chart_title': 'Doğum Haritası',
      'planets_title': 'Gezegen Konumları',
      'aspects_title': 'Temel Açılar',
      'error_title': 'Hata',
      'language_btn': 'English'
    }
  };

  static String get(String key, String lang) {
    return _data[lang]?[key] ?? key;
  }
}
