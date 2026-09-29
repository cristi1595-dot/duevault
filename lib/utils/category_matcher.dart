class CategoryMatcher {
  static const Map<String, List<String>> _keywordMap = {
    'Utilities': [
      'enel', 'electrica', 'eon', 'e.on', 'hidroelectrica', 'gaz', 'curent',
      'apa', 'canal', 'salubritate', 'gunoi', 'incalzire', 'termoenergetica',
    ],
    'Telecom': [
      'digi', 'rds', 'rcs', 'vodafone', 'orange', 'telekom', 'internet', 'fibra',
    ],
    'Subscriptions': [
      'netflix', 'spotify', 'youtube', 'disney', 'hbo', 'max', 'prime',
      'apple tv', 'apple music', 'patreon', 'icloud', 'google one', 'chatgpt',
    ],
    'Auto': [
      'itp', 'rca', 'casco', 'rovinieta', 'roviniet', 'parcare', 'combustibil',
      'benzina', 'motorina', 'omv', 'petrom', 'mol', 'rompetrol', 'revizie',
    ],
    'Housing': [
      'chirie', 'intretinere', 'asociatie', 'bloc', 'imobil', 'apartament',
    ],
    'Loans': [
      'rata', 'credit', 'imprumut', 'leasing', 'banca', 'bcr', 'brd', 'ing', 'bt',
    ],
    'Health': [
      'dentist', 'stomatolog', 'farmacie', 'medlife', 'regina maria', 'sanador',
      'analize', 'medic', 'reteta',
    ],
    'Identity': [
      'buletin', 'ci', 'pasaport', 'permis conducere', 'certificat',
    ],
    'Warranty': [
      'garantie', 'emag', 'altex', 'flanco',
    ],
  };

  static String? detectCategory(String title) {
    final lower = title.trim().toLowerCase();
    if (lower.isEmpty) return null;

    for (final entry in _keywordMap.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
